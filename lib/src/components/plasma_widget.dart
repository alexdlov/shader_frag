import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// PlasmaWidget
// ============================================================
// Renders an animated plasma wave effect using the GPU shader.
//
// Key architecture points:
//   • _loader is STATIC — FragmentProgram compiles once per app
//   • Each instance creates its OWN FragmentShader (mutable uniforms)
//   • Ticker drives animation without setState or AnimatedBuilder
//   • _elapsed ValueNotifier is passed to CustomPaint(repaint:)
//     → only the painter layer repaints, not the widget tree
//   • shouldRepaint returns false — repaints come from the Listenable
// ============================================================

class PlasmaWidget extends StatefulWidget {
  const PlasmaWidget({
    this.color1 = const Color(0xFF1A4DEB),
    this.color2 = const Color(0xFFCC1A99),
    this.color3 = const Color(0xFF00CCB3),
    this.borderRadius = 16.0,
    super.key,
  });

  static const _asset = 'lib/shaders/plasma.frag';

  final Color color1;
  final Color color2;
  final Color color3;
  final double borderRadius;

  @override
  State<PlasmaWidget> createState() => _PlasmaState();
}

class _PlasmaState extends State<PlasmaWidget>
    with SingleTickerProviderStateMixin {
  // Static: ONE FragmentProgram for all PlasmaWidget instances
  static final _loader = ShaderProgramLoader(PlasmaWidget._asset);

  // Per-instance: elapsed drives animation via repaint Listenable
  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  // Per-instance: widget config (updated in didUpdateWidget)
  late final ValueNotifier<PlasmaWidget> _config = ValueNotifier(widget);

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
    _painter = _PlasmaPainter(
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
  void didUpdateWidget(covariant PlasmaWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget; // triggers repaint via Listenable
  }

  @override
  void dispose() {
    _loader.removeListener(_onProgramLoaded); // safe if not added
    _ticker.dispose();
    _elapsed.dispose();
    _config.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_painter == null) return const SizedBox.expand();
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CustomPaint(painter: _painter, child: const SizedBox.expand()),
      ),
    );
  }
}

class _PlasmaPainter extends CustomPainter {
  _PlasmaPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<PlasmaWidget> config,
  }) : _elapsed = elapsed,
       _config = config,
       // repaint: Listenable — CustomPaint subscribes here.
       // When either elapsed or config changes → only the painter
       // layer is marked dirty, no widget rebuild happens.
       super(repaint: Listenable.merge([elapsed, config]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<PlasmaWidget> _config;

  // Reuse Paint object — allocating it every frame adds GC pressure
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;

    // Set uniforms in declaration order from plasma.frag
    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, w.color1.r) // uColor1 (r,g,b,a)
      ..setFloat(4, w.color1.g)
      ..setFloat(5, w.color1.b)
      ..setFloat(6, w.color1.a)
      ..setFloat(7, w.color2.r) // uColor2
      ..setFloat(8, w.color2.g)
      ..setFloat(9, w.color2.b)
      ..setFloat(10, w.color2.a)
      ..setFloat(11, w.color3.r) // uColor3
      ..setFloat(12, w.color3.g)
      ..setFloat(13, w.color3.b)
      ..setFloat(14, w.color3.a);

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  // false because repaints are driven by the Listenable above
  @override
  bool shouldRepaint(covariant _PlasmaPainter old) => false;
}
