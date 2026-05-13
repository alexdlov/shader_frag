import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// EnergyWidget — rotating radial energy rays
// ============================================================
// Fitness use cases:
//   • "Start workout" call-to-action background
//   • Power/streak badge background
//   • Loading screen while fetching workout plan
//   • Achievement burst animation (use intensity = 2.0)
// ============================================================

class EnergyWidget extends StatefulWidget {
  const EnergyWidget({
    this.speed = 1.0,
    this.rayCount = 8.0,
    this.coreColor = const Color(0xFFFFD040),
    this.rayColor = const Color(0xFFFF6600),
    this.intensity = 1.0,
    this.backgroundColor = const Color(0xFF0A0800),
    this.borderRadius = 16.0,
    super.key,
  });

  static const _asset = 'lib/shaders/energy.frag';

  final double speed;
  final double rayCount;
  final Color coreColor;
  final Color rayColor;
  final double intensity;
  final Color backgroundColor;
  final double borderRadius;

  @override
  State<EnergyWidget> createState() => _EnergyState();
}

class _EnergyState extends State<EnergyWidget>
    with SingleTickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(EnergyWidget._asset);

  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final ValueNotifier<EnergyWidget> _config = ValueNotifier(widget);

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
    _painter = _EnergyPainter(
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
  void didUpdateWidget(covariant EnergyWidget old) {
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

class _EnergyPainter extends CustomPainter {
  _EnergyPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<EnergyWidget> config,
  }) : _elapsed = elapsed,
       _config = config,
       super(repaint: Listenable.merge([elapsed, config]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<EnergyWidget> _config;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime
      ..setFloat(3, w.speed) // uSpeed
      ..setFloat(4, w.rayCount) // uRayCount
      ..setFloat(5, w.coreColor.r) // uCoreColor
      ..setFloat(6, w.coreColor.g)
      ..setFloat(7, w.coreColor.b)
      ..setFloat(8, w.coreColor.a)
      ..setFloat(9, w.rayColor.r) // uRayColor
      ..setFloat(10, w.rayColor.g)
      ..setFloat(11, w.rayColor.b)
      ..setFloat(12, w.rayColor.a)
      ..setFloat(13, w.intensity) // uIntensity
      ..setFloat(14, w.backgroundColor.r) // uBgColor
      ..setFloat(15, w.backgroundColor.g)
      ..setFloat(16, w.backgroundColor.b)
      ..setFloat(17, w.backgroundColor.a);

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter old) => false;
}
