import 'package:flutter/material.dart';

import 'src/preview/shaders_preview.dart';

void main() {
  runApp(const ShaderApp());
}

class ShaderApp extends StatelessWidget {
  const ShaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Shader Gallery',
      debugShowCheckedModeBanner: false,
      home: ShadersPreview(),
    );
  }
}
