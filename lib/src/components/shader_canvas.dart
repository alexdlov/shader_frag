import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// ============================================================
// ShaderCanvas — low-level primitive for shader widgets
// ============================================================
// This is a LeafRenderObjectWidget (no children) with isRepaintBoundary=true.
// Why not CustomPaint?
//   • CustomPaint creates RenderCustomPaint — it works great,
//     but has overhead on child layout/paint.
//   • Here we draw ONE drawRect with a shader — no child needed.
//   • isRepaintBoundary ensures that 60 fps invalidations
//     don't "leak" up the tree and trigger repaint
//     of neighboring widgets (see plugfox.dev/high-performance-canvas).
//
// API is intentionally simple: shader + canvas size + uniforms callback.
// Repaint notifications come through [repaint] Listenable —
// the same pattern as CustomPaint(repaint: ...).
// ============================================================

typedef ShaderUniformsBuilder =
    void Function(ui.FragmentShader shader, Size size);

class ShaderCanvas extends LeafRenderObjectWidget {
  const ShaderCanvas({
    required this.shader,
    required this.uniforms,
    required this.repaint,
    super.key,
  });

  /// FragmentShader instance (each widget has its own — uniforms would conflict).
  /// Can be null while the program is loading.
  final ui.FragmentShader? shader;

  /// Callback to set uniforms before each draw.
  /// Called with the current canvas size.
  final ShaderUniformsBuilder uniforms;

  /// Source of repaint ticks (Ticker → ValueNotifier&lt;Duration&gt;,
  /// config notifier, GestureNotifier, etc.).
  /// Listenable.merge(\[...\]) combines multiple sources.
  final Listenable repaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ShaderCanvasRender(shader: shader, uniforms: uniforms, repaint: repaint);

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _ShaderCanvasRender renderObject,
  ) {
    renderObject
      ..shader = shader
      ..uniforms = uniforms
      ..repaint = repaint;
  }
}

class _ShaderCanvasRender extends RenderBox {
  _ShaderCanvasRender({
    required ui.FragmentShader? shader,
    required this.uniforms,
    required Listenable repaint,
  }) : _shader = shader,
       _repaint = repaint;

  ui.FragmentShader? _shader;
  ui.FragmentShader? get shader => _shader;
  set shader(ui.FragmentShader? value) {
    if (identical(_shader, value)) return;
    _shader = value;
    markNeedsPaint();
  }

  ShaderUniformsBuilder uniforms;

  Listenable _repaint;
  Listenable get repaint => _repaint;
  set repaint(Listenable value) {
    if (identical(_repaint, value)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
  }

  // ── Lifecycle of subscriptions ────────────────────────────────
  // Subscribe to repaint only while the RenderObject is in the tree,
  // otherwise you might get a leak through a long-lived ValueNotifier.

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  // ── Layout ─────────────────────────────────────────────────
  // Stretch to parent size. If the parent doesn't provide constraints,
  // take the minimum size to avoid crashing.

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.biggest.isFinite ? constraints.biggest : constraints.smallest;

  // ── Performance flags ──────────────────────────────────────

  /// Enable repaint-boundary: frequent shader repaints will NOT
  /// propagate up the tree. This is a key optimization —
  /// neighboring widgets (e.g., text) will not repaint on every frame.
  @override
  bool get isRepaintBoundary => true;

  /// Shader is always opaque at the drawRect level (alpha can be
  /// in the shader itself, but we do not "punch through" the layer below).
  @override
  bool get alwaysNeedsCompositing => false;

  // ── Paint ──────────────────────────────────────────────────

  final Paint _paint = Paint();

  @override
  void paint(PaintingContext context, Offset offset) {
    final shader = _shader;
    if (shader == null || size.isEmpty) return;
    uniforms(shader, size);
    _paint.shader = shader;
    final canvas = context.canvas;
    // drawRect with offset — consider the position from the parent
    canvas.drawRect(offset & size, _paint);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ui.FragmentShader>('shader', _shader))
      ..add(
        FlagProperty(
          'isRepaintBoundary',
          value: isRepaintBoundary,
          ifTrue: 'is repaint boundary',
        ),
      );
  }
}
