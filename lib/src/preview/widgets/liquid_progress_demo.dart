import 'package:flutter/material.dart';

import '../../components/liquid_progress_widget.dart';

class LiquidProgressDemo extends StatefulWidget {
  const LiquidProgressDemo({super.key});

  @override
  State<LiquidProgressDemo> createState() => _LiquidProgressDemoState();
}

class _LiquidProgressDemoState extends State<LiquidProgressDemo> {
  double _progress = 0.35;

  static const _levels = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const _labels = ['0%', '25%', '50%', '75%', '100%'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LiquidProgressWidget(
          progress: _progress,
          fillColor: const Color(0xFF0096C7),
          bgColor: const Color(0xFF001220),
          waveAmplitude: 0.022,
          borderRadius: 0,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, color: Colors.white70, size: 28),
            const SizedBox(height: 6),
            Text(
              '${(_progress * 2400).round()} / 2400 ml',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_progress * 100).round()}% of daily goal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _levels.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _progress = _levels[i]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: (_progress == _levels[i])
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      _labels[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
