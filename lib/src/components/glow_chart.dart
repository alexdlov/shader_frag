import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';
import 'shader_canvas.dart';

// ============================================================
// GlowChart — animated line-chart with shader background
// ============================================================
// Layer architecture (bottom to top):
//   1. ShaderCanvas (glow_chart.frag) — live gradient + grid
//   2. CustomPaint (_LinePainter) — line + fill under it
//   3. GestureDetector — tap shows point and value
//
// EACH layer has its own RepaintBoundary, so the background
// is redrawn every frame, while the line is only redrawn when
// the data or selected index changes.
// ============================================================

class GlowChart extends StatefulWidget {
  const GlowChart({
    required this.data,
    this.lineColor = const Color(0xFF00E5FF),
    this.bgTop = const Color(0xFF003344),
    this.bgBottom = const Color(0xFF000814),
    this.borderRadius = 16.0,
    this.height = 200,
    super.key,
  });

  final List<double> data;
  final Color lineColor;
  final Color bgTop;
  final Color bgBottom;
  final double borderRadius;
  final double height;

  static const _asset = 'lib/shaders/glow_chart.frag';

  @override
  State<GlowChart> createState() => _GlowChartState();
}

class _GlowChartState extends State<GlowChart> with TickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(GlowChart._asset);

  late final Ticker _ticker;
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<int?> _selected = ValueNotifier(null);
  late final AnimationController _drawIn;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _elapsed.value = e);
    _drawIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (_loader.value != null) {
      _bind();
    } else {
      _loader.addListener(_onLoaded);
    }
  }

  void _onLoaded() {
    _loader.removeListener(_onLoaded);
    if (!mounted || _loader.value == null) return;
    _bind();
  }

  void _bind() {
    _shader = _loader.value!.fragmentShader();
    _ticker.start();
    _drawIn.forward();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GlowChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _drawIn
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _drawIn.dispose();
    _elapsed.dispose();
    _selected.dispose();
    _shader?.dispose();
    _loader.removeListener(_onLoaded);
    super.dispose();
  }

  void _setUniforms(ui.FragmentShader s, Size size) {
    final t = _elapsed.value.inMilliseconds / 1000.0;
    final top = widget.bgTop;
    final bot = widget.bgBottom;
    final acc = widget.lineColor;
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, t)
      ..setFloat(3, top.r)
      ..setFloat(4, top.g)
      ..setFloat(5, top.b)
      ..setFloat(6, top.a)
      ..setFloat(7, bot.r)
      ..setFloat(8, bot.g)
      ..setFloat(9, bot.b)
      ..setFloat(10, bot.a)
      ..setFloat(11, acc.r)
      ..setFloat(12, acc.g)
      ..setFloat(13, acc.b)
      ..setFloat(14, acc.a)
      ..setFloat(15, 8.0); // grid density
  }

  void _onTapDown(TapDownDetails d, BoxConstraints box) {
    if (widget.data.isEmpty) return;
    final dx = d.localPosition.dx.clamp(0.0, box.maxWidth);
    final i = ((dx / box.maxWidth) * (widget.data.length - 1)).round();
    _selected.value = i;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            onTapDown: (d) => _onTapDown(d, box),
            onPanUpdate: (d) {
              if (widget.data.isEmpty) return;
              final dx = d.localPosition.dx.clamp(0.0, box.maxWidth);
              _selected.value = ((dx / box.maxWidth) * (widget.data.length - 1))
                  .round();
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Layer 1: background (60 fps) ──
                if (_shader != null)
                  ShaderCanvas(
                    shader: _shader!,
                    uniforms: _setUniforms,
                    repaint: _elapsed,
                  ),
                // ── Layer 2: line (repaint on data/draw-in/selected) ──
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _LinePainter(
                      data: widget.data,
                      color: widget.lineColor,
                      progress: _drawIn,
                      selected: _selected,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.data,
    required this.color,
    required Animation<double> progress,
    required ValueListenable<int?> selected,
  }) : _progress = progress,
       _selected = selected,
       super(repaint: Listenable.merge([progress, selected]));

  final List<double> data;
  final Color color;
  final Animation<double> _progress;
  final ValueListenable<int?> _selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxV = data.reduce((a, b) => a > b ? a : b);
    final minV = data.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

    Offset point(int i) {
      final x = i / (data.length - 1) * size.width;
      final yNorm = (data[i] - minV) / range;
      // padding 12% top/bottom — so the line doesn't stick to the edges
      final y = size.height * (0.88 - yNorm * 0.76);
      return Offset(x, y);
    }

    final progress = _progress.value;
    final endX = size.width * progress;

    // Smooth line through cubic Bezier (catmull-rom-style)
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 0; i < data.length - 1; i++) {
      final p0 = point(i);
      final p1 = point(i + 1);
      final dx = (p1.dx - p0.dx) * 0.5;
      path.cubicTo(p0.dx + dx, p0.dy, p1.dx - dx, p1.dy, p1.dx, p1.dy);
    }

    // Clip by progress — line "draws" from left to right
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, endX, size.height));

    // Fill under the line (gradient)
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
        color.withValues(alpha: 0.45),
        color.withValues(alpha: 0.0),
      ]);
    canvas.drawPath(fillPath, fillPaint);

    // Line with glow
    final glow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    canvas.restore();

    // Selected point + label
    final sel = _selected.value;
    if (sel != null && progress > 0.99 && sel < data.length) {
      final p = point(sel);
      final ringPaint = Paint()..color = color.withValues(alpha: 0.25);
      canvas.drawCircle(p, 14, ringPaint);
      canvas.drawCircle(p, 4, Paint()..color = color);

      final textPainter = TextPainter(
        text: TextSpan(
          text: data[sel].toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (p.dx + 10).clamp(0, size.width - textPainter.width - 4),
          (p.dy - textPainter.height - 8).clamp(4, size.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.data != data || old.color != color;
}
