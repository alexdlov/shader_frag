import 'package:flutter/material.dart';

import '../../components/frosted_glass_widget.dart';
import '../../components/plasma_widget.dart';

class FrostedGlassDemo extends StatefulWidget {
  const FrostedGlassDemo({super.key});

  @override
  State<FrostedGlassDemo> createState() => _FrostedGlassDemoState();
}

class _FrostedGlassDemoState extends State<FrostedGlassDemo> {
  final _bgKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _bgKey,
          child: const PlasmaWidget(
            color1: Color(0xFF8B6FA8),
            color2: Color(0xFFB89DC9),
            color3: Color(0xFF7BC5D6),
            borderRadius: 0,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: Color(0x5500E5FF),
                size: 52,
              ),
              const SizedBox(height: 10),
              const Text(
                'NEON DREAMS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Synthwave Artist',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FrostedGlassWidget(
            backgroundKey: _bgKey,
            blurRadius: 14.0,
            noiseIntensity: 0.05,
            tint: const Color(0x30FFFFFF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Neon Dreams',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            value: 0.4,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.skip_previous_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
