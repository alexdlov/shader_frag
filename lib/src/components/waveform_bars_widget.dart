import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ============================================================
// WaveformBarsWidget — animated equalizer
// ============================================================
// Pure CustomPainter without GLSL. Demonstrates:
//
//   • CustomPainter with repaint: Listenable — no setState, no AnimatedBuilder
//   • Reusing Paint (_fillPaint, _glowPaint) — important!
//     Do not create new Paint() every frame
//   • Gradient shader on Fill Paint — ONE LinearGradient.createShader()
//     call, cached by size (recreated only when size changes)
//   • MaskFilter.blur — neon glow via CPU blur (1 pass per bar)
//   • Ticker → ValueNotifier<List<double>> — pure Listenable chain
//   • isRepaintBoundary isolation via RepaintBoundary
//
// Animation:
//   • Each bar has _heights[i] (current) and _targets[i] (target)
//   • Ticker smoothly interpolates heights → targets (lerp × dt × speed)
//   • Targets change every ~280 ms: high when isPlaying, low when paused
//
// Real-world use case: Music player equalizer visualization
// ============================================================

class WaveformBarsWidget extends StatefulWidget {
  const WaveformBarsWidget({
    this.barCount = 28,
    this.isPlaying = true,
    this.color = const Color(0xFF00E5FF),
    this.peakColor = Colors.white,
    this.barRadius = 3.0,
    this.gapFraction = 0.30,
    this.height = 64.0,
    super.key,
  });

  /// Number of bars in the equalizer.
  final int barCount;

  /// Whether the playback animation is active.
  final bool isPlaying;

  /// Main color (bottom of the gradient).
  final Color color;

  /// Peak color (top of the gradient).
  final Color peakColor;

  /// Radius of the bar corners.
  final double barRadius;

  /// Fraction of the widget width allocated to gaps between bars (0..0.5).
  final double gapFraction;

  /// Height of the widget in logical pixels.
  final double height;

  @override
  State<WaveformBarsWidget> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<WaveformBarsWidget>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<WaveformBarsWidget> _config = ValueNotifier(widget);
  final ValueNotifier<List<double>> _heightsNotifier = ValueNotifier(const []);

  late List<double> _heights;
  late List<double> _targets;
  final _rng = math.Random();

  Duration _prevElapsed = Duration.zero;
  Duration _lastChange = Duration.zero;
  static const _changeInterval = Duration(milliseconds: 280);

  late final Ticker _ticker;
  _WaveformPainter? _painter;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(widget.barCount, (_) => 0.08);
    _targets = List.generate(widget.barCount, (_) => 0.08);
    _heightsNotifier.value = List.of(_heights);

    _painter = _WaveformPainter(heights: _heightsNotifier, config: _config);

    _ticker = createTicker(_onTick);
    _ticker.start();
    // Immediately set initial targets
    _randomizeTargets();
  }

  // ── Sets new random targets for all bars ────
  void _randomizeTargets() {
    if (widget.isPlaying) {
      // Playback: realistic EQ heights (mid-range dominates)
      for (var i = 0; i < _targets.length; i++) {
        final r = _rng.nextDouble();
        // Quadratic distribution: many mid-levels, few max
        _targets[i] = (r * r * 0.25 + _rng.nextDouble() * 0.75).clamp(
          0.08,
          1.0,
        );
      }
    } else {
      // Pause: all bars fall to near-zero
      for (var i = 0; i < _targets.length; i++) {
        _targets[i] = 0.04 + _rng.nextDouble() * 0.07;
      }
    }
  }

  // ── Ticker callback: smooth interpolation + target change ────
  void _onTick(Duration elapsed) {
    final dt = (elapsed - _prevElapsed).inMicroseconds / 1000000.0;
    _prevElapsed = elapsed;

    // Interpolation speed: faster during playback
    final speed = widget.isPlaying ? 9.0 : 5.0;
    final lerpFactor = (speed * dt).clamp(0.0, 1.0);

    bool changed = false;
    for (var i = 0; i < _heights.length; i++) {
      final prev = _heights[i];
      _heights[i] = _heights[i] + (_targets[i] - _heights[i]) * lerpFactor;
      if ((_heights[i] - prev).abs() > 0.0008) changed = true;
    }

    // Periodically change targets
    if (elapsed - _lastChange >= _changeInterval) {
      _lastChange = elapsed;
      _randomizeTargets();
    }

    // Notify only if there was a real change → fewer unnecessary repaints
    if (changed) {
      _heightsNotifier.value = List.of(_heights);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformBarsWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;

    // Recreate arrays when the number of bars changes
    if (old.barCount != widget.barCount) {
      _heights = List.generate(
        widget.barCount,
        (i) => i < _heights.length ? _heights[i] : 0.08,
      );
      _targets = List.generate(
        widget.barCount,
        (i) => i < _targets.length ? _targets[i] : 0.08,
      );
    }

    if (old.isPlaying != widget.isPlaying) {
      _randomizeTargets();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _config.dispose();
    _heightsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the repaint from the rest of the tree
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(painter: _painter, child: const SizedBox.expand()),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _WaveformPainter
// ────────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required ValueNotifier<List<double>> heights,
    required ValueNotifier<WaveformBarsWidget> config,
  }) : _heights = heights,
       _config = config,
       // repaint: Listenable — вместо setState / AnimatedBuilder
       super(repaint: Listenable.merge([heights, config]));

  final ValueNotifier<List<double>> _heights;
  final ValueNotifier<WaveformBarsWidget> _config;

  // ── Reusable Paint objects — created ONCE ────
  // Key principle: do not create new Paint() in the paint() method
  final _fillPaint = Paint()..style = PaintingStyle.fill;
  final _glowPaint = Paint()
    ..style = PaintingStyle.fill
    // MaskFilter.blur: blurred glow behind bars (neon effect)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

  // Cache gradient shader — recreated only when size/colors change
  Size _cachedSize = Size.zero;
  Color _cachedColor = const Color(0x00000000);
  Color _cachedPeak = const Color(0x00000000);

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = _config.value;
    final heights = _heights.value;
    if (heights.isEmpty) return;

    final n = heights.length;

    // ── Gradient shader: one for the entire canvas height ───────────
    // All bars use ONE shader — do not recreate for each
    // Recreate only when size or colors change
    if (size != _cachedSize ||
        cfg.color != _cachedColor ||
        cfg.peakColor != _cachedPeak) {
      _cachedSize = size;
      _cachedColor = cfg.color;
      _cachedPeak = cfg.peakColor;
      _fillPaint.shader = ui.Gradient.linear(
        Offset(0, size.height), // bottom → color
        Offset.zero, // top    → peakColor
        [cfg.color, cfg.peakColor],
      );
    }

    // ── Geometry of bars ─────────────────────────────────────
    final gapW = size.width * cfg.gapFraction / n;
    final barW = (size.width - gapW * n) / n;
    final r = Radius.circular(cfg.barRadius);

    // ── Pass 1: Glow (semi-transparent blur behind bars) ─────
    _glowPaint.color = cfg.color.withValues(alpha: 0.28);
    for (var i = 0; i < n; i++) {
      final h = (heights[i] * size.height).clamp(2.0, size.height);
      final x = i * (barW + gapW) + gapW * 0.5;
      canvas.drawRRect(
        RRect.fromLTRBR(x, size.height - h, x + barW, size.height, r),
        _glowPaint,
      );
    }

    // ── Pass 2: Fill (gradient bars on top of glow) ────────
    for (var i = 0; i < n; i++) {
      final h = (heights[i] * size.height).clamp(2.0, size.height);
      final x = i * (barW + gapW) + gapW * 0.5;
      canvas.drawRRect(
        RRect.fromLTRBR(x, size.height - h, x + barW, size.height, r),
        _fillPaint,
      );
    }
  }

  // false: shouldRepaint is not used to control repainting —
  // Listenable in the repaint: parameter does that
  @override
  bool shouldRepaint(covariant _WaveformPainter old) => false;
}
