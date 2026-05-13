import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// HolographicWidget — iridescent card surface
// ============================================================
// Move your mouse / finger over the widget to tilt the "light"
// direction and see the rainbow holographic effect shift.
//
// How interaction works:
//   • MouseRegion (desktop) + GestureDetector (touch) report pointer pos
//   • Normalized lightDir = (pointerX / width - 0.5) * 2, same for Y
//   • Stored in ValueNotifier<Offset> → triggers repaint via Listenable
// ============================================================

class HolographicWidget extends StatefulWidget {
  const HolographicWidget({
    this.baseColor = const Color(0xFFB8C8D8),
    this.shimmer = 1.0,
    this.borderRadius = 16.0,
    super.key,
  });

  static const _asset = 'lib/shaders/holographic.frag';

  final Color baseColor;
  final double shimmer; // 0.0 = flat, 1.0 = full rainbow
  final double borderRadius;

  @override
  State<HolographicWidget> createState() => _HolographicState();
}

class _HolographicState extends State<HolographicWidget>
    with SingleTickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(HolographicWidget._asset);

  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final ValueNotifier<HolographicWidget> _config = ValueNotifier(widget);
  // lightDir in normalized [-1, 1] range. (0, 0) = neutral
  final ValueNotifier<Offset> _lightDir = ValueNotifier(Offset.zero);

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
    _painter = _HolographicPainter(
      shader: _shader!,
      elapsed: _elapsed,
      config: _config,
      lightDir: _lightDir,
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
  void didUpdateWidget(covariant HolographicWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;
  }

  @override
  void dispose() {
    _loader.removeListener(_onProgramLoaded);
    _ticker.dispose();
    _elapsed.dispose();
    _config.dispose();
    _lightDir.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _updateLight(Offset localPos, Size widgetSize) {
    // Map pointer position to [-1, 1] light direction
    _lightDir.value = Offset(
      (localPos.dx / widgetSize.width - 0.5) * 2.0,
      (localPos.dy / widgetSize.height - 0.5) * 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_painter == null) return const SizedBox.expand();
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return MouseRegion(
            // Desktop: mouse hover updates light direction
            onHover: (event) => _updateLight(event.localPosition, size),
            child: GestureDetector(
              // Mobile: drag updates light direction
              onPanUpdate: (d) => _updateLight(d.localPosition, size),
              onPanEnd: (_) => _lightDir.value = Offset.zero,
              child: CustomPaint(
                painter: _painter,
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HolographicPainter extends CustomPainter {
  _HolographicPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<HolographicWidget> config,
    required ValueNotifier<Offset> lightDir,
  }) : _elapsed = elapsed,
       _config = config,
       _lightDir = lightDir,
       super(repaint: Listenable.merge([elapsed, config, lightDir]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<HolographicWidget> _config;
  final ValueNotifier<Offset> _lightDir;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;
    final l = _lightDir.value;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, l.dx) // uLightDir.x
      ..setFloat(4, l.dy) // uLightDir.y
      ..setFloat(5, w.shimmer) // uShimmer
      ..setFloat(6, w.baseColor.r) // uBaseColor
      ..setFloat(7, w.baseColor.g)
      ..setFloat(8, w.baseColor.b)
      ..setFloat(9, w.baseColor.a);

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant _HolographicPainter old) => false;
}
