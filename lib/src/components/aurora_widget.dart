import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// AuroraWidget — animated northern lights
// ============================================================

class AuroraWidget extends StatefulWidget {
  const AuroraWidget({
    this.skyColor = const Color(0xFF050508),
    this.color1 = const Color(0xFF1AFFAA),
    this.color2 = const Color(0xFF9918FF),
    this.intensity = 1.0,
    this.borderRadius = 16.0,
    super.key,
  });

  static const _asset = 'lib/shaders/aurora.frag';

  final Color skyColor;
  final Color color1;
  final Color color2;
  final double intensity; // 0.5..2.0
  final double borderRadius;

  @override
  State<AuroraWidget> createState() => _AuroraState();
}

class _AuroraState extends State<AuroraWidget>
    with SingleTickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(AuroraWidget._asset);

  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final ValueNotifier<AuroraWidget> _config = ValueNotifier(widget);

  late final Ticker _ticker;
  ui.FragmentShader? _shader;
  CustomPainter? _painter;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _elapsed.value = elapsed);
    if (_loader.value != null) {
      _setup();
    } else if (_loader.isLoading) {
      _loader.addListener(_onProgramLoaded);
    }
  }

  void _setup() {
    _shader = _loader.value!.fragmentShader();
    _painter = _AuroraPainter(
      shader: _shader!,
      elapsed: _elapsed,
      config: _config,
    );
    if (!_ticker.isActive) _ticker.start();
    if (mounted) setState(() {});
  }

  void _onProgramLoaded() {
    _loader.removeListener(_onProgramLoaded);
    if (_loader.value == null || !mounted) return;
    _setup();
  }

  @override
  void didUpdateWidget(covariant AuroraWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;
  }

  @override
  void dispose() {
    _loader.removeListener(_onProgramLoaded);
    _ticker.dispose();
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

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<AuroraWidget> config,
  }) : _elapsed = elapsed,
       _config = config,
       super(repaint: Listenable.merge([elapsed, config]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<AuroraWidget> _config;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, w.skyColor.r) // uSky
      ..setFloat(4, w.skyColor.g)
      ..setFloat(5, w.skyColor.b)
      ..setFloat(6, w.skyColor.a)
      ..setFloat(7, w.color1.r) // uColor1
      ..setFloat(8, w.color1.g)
      ..setFloat(9, w.color1.b)
      ..setFloat(10, w.color1.a)
      ..setFloat(11, w.color2.r) // uColor2
      ..setFloat(12, w.color2.g)
      ..setFloat(13, w.color2.b)
      ..setFloat(14, w.color2.a)
      ..setFloat(15, w.intensity); // uIntensity

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => false;
}
