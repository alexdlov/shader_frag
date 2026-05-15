import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '_shader_loader.dart';

// ============================================================
// FrostedGlassWidget — frosted glass with noise
// ============================================================
// The most complex technique in the gallery: passing a live image
// to a GLSL fragment shader via sampler2D.
//
// Layer architecture (bottom to top):
//   1. RepaintBoundary(key: backgroundKey) — background (outside the widget)
//      This layer is CAPTURED as a ui.Image via toImageSync()
//   2. CustomPainter (frosted_glass.frag) — blur + noise
//      shader.setImageSampler(0, capturedImage) passes the texture
//   3. child — content over the glass (without blur)
//
// How background capture works:
//   • backgroundKey must point to a RepaintBoundary widget
//   • Ticker calls _captureBackground() every ~5 fps
//   • RenderRepaintBoundary.toImageSync() reads the GPU raster synchronously
//   • Old ui.Image is disposed, new one is passed to the shader
//
// Performance contract (per plugfox.dev articles):
//   ✓ No setState for animation — repaint via Listenable
//   ✓ _paint is reused between frames
//   ✓ toImageSync() is called only ~5 fps (not every frame)
//   ✓ RepaintBoundary isolates frosted overlay from the rest of the tree
//   ✓ Old ui.Image is disposed immediately after replacement
//
// Real-world use cases:
//   • Bottom sheet / modal over animated background
//   • Frosted card overlay (iOS-style)
//   • Info panel over map / media content
//
// Usage:
// ```dart
// final _bgKey = GlobalKey();
//
// Stack(children: [
//   RepaintBoundary(key: _bgKey, child: PlasmaWidget(...)),
//   Positioned(bottom: 0, left: 0, right: 0,
//     child: FrostedGlassWidget(backgroundKey: _bgKey, child: ...)),
// ])
// ```
// ============================================================

class FrostedGlassWidget extends StatefulWidget {
  const FrostedGlassWidget({
    required this.backgroundKey,
    required this.child,
    this.blurRadius = 12.0,
    this.noiseIntensity = 0.048,
    this.tint = const Color(0x44FFFFFF),
    this.borderRadius = 0.0,
    super.key,
  });

  static const _asset = 'lib/shaders/frosted_glass.frag';

  /// GlobalKey of the RepaintBoundary widget to blur.
  /// The widget with this key must be in the same tree.
  final GlobalKey backgroundKey;

  /// Content displayed over the frosted glass (without blur).
  final Widget child;

  /// Blur radius in logical pixels (4..24).
  final double blurRadius;

  /// Grain intensity (0.0..0.10).
  final double noiseIntensity;

  /// Tint color of the frosted glass (usually semi-transparent white).
  final Color tint;

  final double borderRadius;

  @override
  State<FrostedGlassWidget> createState() => _FrostedGlassState();
}

class _FrostedGlassState extends State<FrostedGlassWidget>
    with SingleTickerProviderStateMixin {
  static final _loader = ShaderProgramLoader(FrostedGlassWidget._asset);

  late final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final ValueNotifier<FrostedGlassWidget> _config = ValueNotifier(widget);
  // Notifier holds the CURRENTLY captured background image.
  // When it changes → painter gets a new texture and repaints.
  final ValueNotifier<ui.Image?> _bgImage = ValueNotifier(null);

  late final Ticker _ticker;
  ui.FragmentShader? _shader;
  CustomPainter? _painter;

  // Capture frequency control: ~5 fps (not every frame — toImageSync is expensive)
  Duration _lastCapture = Duration.zero;
  static const _captureInterval = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (_loader.value != null) {
      _setup();
    } else if (_loader.isLoading) {
      _loader.addListener(_onLoaded);
    }
  }

  void _setup() {
    _shader = _loader.value!.fragmentShader();
    _painter = _FrostedPainter(
      shader: _shader!,
      elapsed: _elapsed,
      bgImage: _bgImage,
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

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed;
    // Capture background no more than _captureInterval (~5 fps)
    if (elapsed - _lastCapture >= _captureInterval) {
      _lastCapture = elapsed;
      _captureBackground();
    }
  }

  // ── Captures the current render of the RepaintBoundary as a ui.Image ─
  // RenderRepaintBoundary.toImageSync() — synchronous GPU→CPU blit.
  // Returns a ui.Image — GPU texture ready to be passed to the shader.
  void _captureBackground() {
    if (!mounted) return;
    final ctx = widget.backgroundKey.currentContext;
    if (ctx == null) return;

    final rb = ctx.findRenderObject();
    if (rb is! RenderRepaintBoundary) return;
    if (!rb.hasSize) return;

    try {
      // pixelRatio: 1.0 — logical pixels, matches shader UV coordinates
      final image = rb.toImageSync(pixelRatio: 1.0);
      final old = _bgImage.value;
      _bgImage.value = image; // notifies painter → repaint
      old?.dispose(); // free GPU memory of the old frame
    } catch (_) {
      // toImageSync can throw if the widget is not yet rendered — ignore
    }
  }

  @override
  void didUpdateWidget(covariant FrostedGlassWidget old) {
    super.didUpdateWidget(old);
    _config.value = widget;
  }

  @override
  void dispose() {
    _loader.removeListener(_onLoaded);
    _ticker.dispose();
    _bgImage.value?.dispose();
    _bgImage.dispose();
    _elapsed.dispose();
    _config.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        // Stack size is determined by widget.child (the only non-positioned child).
        // Positioned.fill stretches the blur layer to this size.
        // This allows FrostedGlassWidget to work correctly in an unbounded context
        // (e.g., Positioned(bottom:0, left:0, right:0) without explicit height).
        children: [
          // Layer 1: frosted glass (shader) — fill the size of the child
          if (_painter != null)
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: _painter)),
            ),
          // Layer 2: content above the glass (not blurred) — determines the size of the Stack
          widget.child,
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _FrostedPainter
// ────────────────────────────────────────────────────────────
class _FrostedPainter extends CustomPainter {
  _FrostedPainter({
    required this.shader,
    required ValueNotifier<Duration> elapsed,
    required ValueNotifier<ui.Image?> bgImage,
    required ValueNotifier<FrostedGlassWidget> config,
  }) : _elapsed = elapsed,
       _bgImage = bgImage,
       _config = config,
       // Three sources of repaint:
       //   elapsed → grain animation in the shader (60 fps)
       //   bgImage → new background capture (~5 fps)
       //   config  → change in blurRadius / tint
       super(repaint: Listenable.merge([elapsed, bgImage, config]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> _elapsed;
  final ValueNotifier<ui.Image?> _bgImage;
  final ValueNotifier<FrostedGlassWidget> _config;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = _bgImage.value;
    // While the background is not captured — draw nothing (transparent)
    if (bg == null) return;

    final w = _config.value;
    final t = _elapsed.value.inMilliseconds / 1000.0;

    shader
      ..setFloat(0, size.width) // uSize.x
      ..setFloat(1, size.height) // uSize.y
      ..setFloat(2, t) // uTime (for grain animation)
      ..setFloat(3, w.blurRadius) // uBlurRadius
      ..setFloat(4, w.noiseIntensity) // uNoise
      ..setFloat(5, w.tint.r) // uTint
      ..setFloat(6, w.tint.g)
      ..setFloat(7, w.tint.b)
      ..setFloat(8, w.tint.a);

    // setImageSampler passes a ui.Image to the sampler2D uniform of the shader.
    // Index 0 = first (and only) sampler2D in frosted_glass.frag
    shader.setImageSampler(0, bg);

    _paint.shader = shader;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant _FrostedPainter old) => false;
}
