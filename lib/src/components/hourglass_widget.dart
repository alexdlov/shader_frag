import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '_shader_loader.dart';

// ============================================================
// HourglassWidget — animated GPU sand timer
// ============================================================
// Layer architecture:
//   • CustomPainter (hourglass.frag)         — GPU rendering
//   • ui.Image sand texture → sampler2D      — generated asset material
//   • Ticker → ValueNotifier<Duration>       — drives uTime (wave)
//   • ValueNotifier<double> _progress        — drives uProgress
//
// Performance contract:
//   ✓ No setState/AnimatedBuilder for repainting — repaint via Listenable
//   ✓ repaint: Listenable.merge([elapsed, progress, textures, config])
//   ✓ shouldRepaint = false (repaint is controlled via Listenable)
//   ✓ _paint object is reused between frames
//   ✓ Ticker runs only when [running] = true; wave time is
//     accumulated monotonically to avoid phase jumps on resume
//
// Usage:
//   HourglassWidget(
//     duration:   const Duration(minutes: 3),
//     running:    _isRunning,
//     onComplete: () => setState(() => _isRunning = false),
//   )
// ============================================================

class HourglassWidget extends StatefulWidget {
  const HourglassWidget({
    required this.duration,
    this.running = false,
    this.onComplete,
    this.resetToken = 0,
    this.sandColor = const Color(0xFFE8C57A),
    this.glassColor = const Color(0xFF90C8E0),
    this.bgColor = const Color(0xFF0D1B2A),
    super.key,
  });

  static const _asset = 'lib/shaders/hourglass.frag';
  static const _sandTextureAsset = 'assets/textures/sand.png';
  static const _glassTextureAsset = 'assets/textures/hourglass_glass.png';

  /// Total duration the sand takes to fall from top to bottom.
  final Duration duration;

  /// When true the sand flows; when false the animation is paused.
  final bool running;

  /// Called once when [progress] reaches 1.0 (all sand has fallen).
  final VoidCallback? onComplete;

  /// Increment this to force a full reset (sand back to top) without
  /// changing [duration].  Used by the demo's Reset button.
  final int resetToken;

  final Color sandColor;
  final Color glassColor;
  final Color bgColor;

  @override
  State<HourglassWidget> createState() => _HourglassState();
}

class _HourglassState extends State<HourglassWidget>
    with TickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(HourglassWidget._asset);
  static final Future<ui.Image> _sandTextureFuture = _loadImage(
    HourglassWidget._sandTextureAsset,
  );
  static final Future<ui.Image> _glassTextureFuture = _loadImage(
    HourglassWidget._glassTextureAsset,
  );

  // Monotonically increasing wave time (not reset on pause/resume).
  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);

  // 0.0 → 1.0 fill progress.
  late final ValueNotifier<double> _progress = ValueNotifier(0.0);

  // Triggers repaint on config changes (colors, running state, etc.).
  late final ValueNotifier<HourglassWidget> _config = ValueNotifier(widget);

  // Generated sand texture, passed to sampler2D in the fragment shader.
  late final ValueNotifier<ui.Image?> _sandTexture = ValueNotifier(null);

  // Glass frame texture, passed to a separate sampler2D in the shader.
  late final ValueNotifier<ui.Image?> _glassTexture = ValueNotifier(null);

  late final Ticker _ticker;

  ui.FragmentShader? _shader;
  CustomPainter? _painter;

  // Cumulative running time — only incremented while running=true.
  Duration _runningElapsed = Duration.zero;

  // Monotonic wave time — always incremented while ticker fires.
  Duration _waveElapsed = Duration.zero;

  // Last ticker timestamp; used to compute frame dt.
  Duration _lastTickTime = Duration.zero;

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    if (_loader.value != null) {
      _setup();
    } else if (_loader.isLoading) {
      _loader.addListener(_onLoaded);
    }

    _sandTextureFuture.then((image) {
      if (!mounted) return;
      _sandTexture.value = image;
    });
    _glassTextureFuture.then((image) {
      if (!mounted) return;
      _glassTexture.value = image;
    });

    if (widget.running) _ticker.start();
  }

  static Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  void _setup() {
    _shader = _loader.value!.fragmentShader();
    _painter = _HourglassPainter(
      shader: _shader!,
      elapsed: _elapsed,
      progress: _progress,
      sandTexture: _sandTexture,
      glassTexture: _glassTexture,
      config: _config,
    );
    if (mounted) setState(() {});
  }

  void _onLoaded() {
    _loader.removeListener(_onLoaded);
    if (_loader.value == null || !mounted) return;
    _setup();
  }

  void _onTick(Duration tickerTime) {
    // tickerTime resets to 0 after each start() call, so compute dt manually.
    final dt = tickerTime - _lastTickTime;
    _lastTickTime = tickerTime;

    // Wave time is always monotone (no phase jump on resume).
    _waveElapsed += dt;
    _elapsed.value = _waveElapsed;

    if (_completed) return;

    _runningElapsed += dt;
    final progress =
        (_runningElapsed.inMicroseconds / widget.duration.inMicroseconds).clamp(
          0.0,
          1.0,
        );
    _progress.value = progress;

    if (progress >= 1.0) {
      _completed = true;
      widget.onComplete?.call();
    }
  }

  @override
  void didUpdateWidget(covariant HourglassWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;

    if (old.duration != widget.duration ||
        old.resetToken != widget.resetToken) {
      _runningElapsed = Duration.zero;
      _progress.value = 0.0;
      _completed = false;
    }

    if (widget.running && !_ticker.isActive) {
      _lastTickTime = Duration.zero; // ticker resets to 0 on start()
      _ticker.start();
    } else if (!widget.running && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _loader.removeListener(_onLoaded);
    _ticker.dispose();
    _elapsed.dispose();
    _progress.dispose();
    _sandTexture.dispose();
    _glassTexture.dispose();
    _config.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_painter == null) return const SizedBox.expand();
    return CustomPaint(painter: _painter, child: const SizedBox.expand());
  }
}

// ────────────────────────────────────────────────────────────
// _HourglassPainter
// ────────────────────────────────────────────────────────────
class _HourglassPainter extends CustomPainter {
  _HourglassPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<double> progress,
    required ValueNotifier<ui.Image?> sandTexture,
    required ValueNotifier<ui.Image?> glassTexture,
    required ValueNotifier<HourglassWidget> config,
  }) : _elapsed = elapsed,
       _progress = progress,
       _sandTexture = sandTexture,
       _glassTexture = glassTexture,
       _config = config,
       super(
         repaint: Listenable.merge([
           elapsed,
           progress,
           sandTexture,
           glassTexture,
           config,
         ]),
       );

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<double> _progress;
  final ValueNotifier<ui.Image?> _sandTexture;
  final ValueNotifier<ui.Image?> _glassTexture;
  final ValueNotifier<HourglassWidget> _config;

  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final sandTexture = _sandTexture.value;
    final glassTexture = _glassTexture.value;
    if (sandTexture == null || glassTexture == null) return;

    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;
    final prog = _progress.value;
    final running = w.running ? 1.0 : 0.0;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, prog) // uProgress
      ..setFloat(4, running) // uRunning
      ..setFloat(5, w.sandColor.r) // uSandColor
      ..setFloat(6, w.sandColor.g)
      ..setFloat(7, w.sandColor.b)
      ..setFloat(8, w.sandColor.a)
      ..setFloat(9, w.glassColor.r) // uGlassColor
      ..setFloat(10, w.glassColor.g)
      ..setFloat(11, w.glassColor.b)
      ..setFloat(12, w.glassColor.a)
      ..setFloat(13, w.bgColor.r) // uBgColor
      ..setFloat(14, w.bgColor.g)
      ..setFloat(15, w.bgColor.b)
      ..setFloat(16, w.bgColor.a);

    shader.setImageSampler(0, sandTexture);
    shader.setImageSampler(1, glassTexture);

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  // Repaint is driven by Listenable, not shouldRepaint.
  @override
  bool shouldRepaint(covariant _HourglassPainter old) => false;
}
