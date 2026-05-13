import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// LiquidProgressWidget — animated liquid fill with wave
// ============================================================
// Layer architecture:
//   • CustomPainter (liquid_progress.frag) — renders the liquid
//   • Ticker → ValueNotifier<Duration> — wave animated at 60 fps
//   • AnimationController → smooth transition of progress on change
//
// Performance contract (per plugfox.dev articles):
//   ✓ No setState/AnimatedBuilder for repainting — repaint via Listenable
//   ✓ repaint: Listenable.merge([elapsed, progressAnim, config])
//   ✓ shouldRepaint = false (repaint is controlled via Listenable)
//   ✓ _paint object is reused between frames
//   ✓ Ticker = SingleTickerProviderStateMixin (not TickerProvider)
//     + AnimationController has its own TickerProvider vsync
//
// Real-world use cases:
//   • Water / nutrition counter (health apps)
//   • Battery level indicator
//   • Loading / installation progress
// ============================================================

class LiquidProgressWidget extends StatefulWidget {
  const LiquidProgressWidget({
    required this.progress,
    this.fillColor = const Color(0xFF00B4D8),
    this.bgColor = const Color(0xFF001520),
    this.waveAmplitude = 0.022,
    this.borderRadius = 16.0,
    super.key,
  });

  static const _asset = 'lib/shaders/liquid_progress.frag';

  /// Fill level [0.0, 1.0]. Changes are animated automatically.
  final double progress;

  /// Color of the liquid.
  final Color fillColor;

  /// Color of the background (empty part).
  final Color bgColor;

  /// Wave amplitude in UV coordinates (0.01..0.05).
  final double waveAmplitude;

  final double borderRadius;

  @override
  State<LiquidProgressWidget> createState() => _LiquidProgressState();
}

class _LiquidProgressState extends State<LiquidProgressWidget>
    with TickerProviderStateMixin {
  // Shader program is loaded once — static final
  static final _loader = ShaderProgramLoader(LiquidProgressWidget._asset);

  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final ValueNotifier<LiquidProgressWidget> _config = ValueNotifier(
    widget,
  );

  late final Ticker _ticker;
  // AnimationController is needed for smooth tweening of progress on change
  late final AnimationController _progressAnim;

  ui.FragmentShader? _shader;
  CustomPainter? _painter;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _elapsed.value = e);
    _progressAnim = AnimationController(
      vsync: this,
      // progress is always in [0,1] — matches the default range of the controller
      duration: const Duration(milliseconds: 700),
    )..value = widget.progress.clamp(0.0, 1.0);

    if (_loader.value != null) {
      _setup();
    } else if (_loader.isLoading) {
      _loader.addListener(_onLoaded);
    }
  }

  void _setup() {
    _shader = _loader.value!.fragmentShader();
    _painter = _LiquidPainter(
      shader: _shader!,
      elapsed: _elapsed,
      progressAnim: _progressAnim,
      config: _config,
    );
    _ticker.start();
    if (mounted) setState(() {});
  }

  void _onLoaded() {
    _loader.removeListener(_onLoaded);
    if (_loader.value == null || !mounted) return;
    _setup();
  }

  @override
  void didUpdateWidget(covariant LiquidProgressWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;
    // Smoothly transition to the new progress value
    if (old.progress != widget.progress) {
      _progressAnim.animateTo(
        widget.progress.clamp(0.0, 1.0),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _loader.removeListener(_onLoaded);
    _ticker.dispose();
    _progressAnim.dispose();
    _elapsed.dispose();
    _config.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_painter == null) return const SizedBox.expand();
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: CustomPaint(painter: _painter, child: const SizedBox.expand()),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _LiquidPainter
// ────────────────────────────────────────────────────────────
class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required AnimationController progressAnim,
    required ValueNotifier<LiquidProgressWidget> config,
  }) : _elapsed = elapsed,
       _progressAnim = progressAnim,
       _config = config,
       // Repaint on every tick of time, every step of the progress animation
       // and on config changes — without setState, without AnimatedBuilder
       super(repaint: Listenable.merge([elapsed, progressAnim, config]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final AnimationController _progressAnim;
  final ValueNotifier<LiquidProgressWidget> _config;

  // Reusable Paint — do not create new Paint() every frame
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;
    final progress = _progressAnim.value;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, progress) // uProgress
      ..setFloat(4, w.fillColor.r) // uFillColor
      ..setFloat(5, w.fillColor.g)
      ..setFloat(6, w.fillColor.b)
      ..setFloat(7, w.fillColor.a)
      ..setFloat(8, w.bgColor.r) // uBgColor
      ..setFloat(9, w.bgColor.g)
      ..setFloat(10, w.bgColor.b)
      ..setFloat(11, w.bgColor.a)
      ..setFloat(12, w.waveAmplitude); // uWaveAmp

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  // false: repaint is managed by Listenable, not through shouldRepaint
  @override
  bool shouldRepaint(covariant _LiquidPainter old) => false;
}
