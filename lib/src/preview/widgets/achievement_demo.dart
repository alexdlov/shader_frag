import 'package:flutter/material.dart';

import '../../components/energy_widget.dart';

class AchievementDemo extends StatefulWidget {
  const AchievementDemo({super.key});

  @override
  State<AchievementDemo> createState() => _AchievementDemoState();
}

class _AchievementDemoState extends State<AchievementDemo> {
  bool _active = false;

  void _trigger() {
    if (_active) return;
    setState(() => _active = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _trigger,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _active ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const EnergyWidget(
              speed: 2.5,
              rayCount: 14,
              coreColor: Colors.white,
              rayColor: Color(0xFF7B2FFF),
              intensity: 2.2,
              backgroundColor: Color(0xFF060010),
            ),
          ),
          if (!_active) Container(color: const Color(0xFF060010)),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _active
                  ? const _AchievementBadge(key: ValueKey(true))
                  : const _AchievementPrompt(key: ValueKey(false)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 8),
        const Text(
          'New Record!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '10 000 steps in one day',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AchievementPrompt extends StatelessWidget {
  const _AchievementPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🏆',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to unlock\nachievement',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
