import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Loads a [ui.FragmentProgram] from a shader asset path.
///
/// **Usage pattern** — declare as `static final` inside the State class
/// so the GPU program compiles once per shader type (not once per widget):
///
/// ```dart
/// class _MyShaderState extends State<MyShader> {
///   static final _loader = ShaderProgramLoader('lib/shaders/my.frag');
///   ui.FragmentShader? _shader;
///
///   @override
///   void initState() {
///     super.initState();
///     if (_loader.value != null) {
///       _shader = _loader.value!.fragmentShader(); // own instance!
///     } else if (_loader.isLoading) {
///       _loader.addListener(_onProgramLoaded);
///     }
///   }
/// ```
///
/// **Why per-widget FragmentShader?**
/// [ui.FragmentProgram] is shared (compiled once on GPU).
/// [ui.FragmentShader] is a mutable uniform bag — each widget needs
/// its own so they don't clobber each other's setFloat() calls.
final class ShaderProgramLoader
    with ChangeNotifier
    implements ValueListenable<ui.FragmentProgram?> {
  ShaderProgramLoader(this.assetPath) {
    _load();
  }

  final String assetPath;

  @override
  ui.FragmentProgram? get value => _program;
  ui.FragmentProgram? _program;

  bool get isLoading => _isLoading;
  bool _isLoading = true;

  Future<void> _load() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        assetPath,
      ).timeout(const Duration(seconds: 5));
    } on Object catch (error, stackTrace) {
      if (kReleaseMode) return;
      if (error is UnsupportedError) return; // web HTML renderer
      developer.log(
        'Failed to load shader [$assetPath]: $error',
        error: error,
        stackTrace: stackTrace,
        name: 'ShaderProgramLoader',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
