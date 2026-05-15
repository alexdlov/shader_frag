import 'package:flutter/material.dart';

import '../../components/waveform_bars_widget.dart';

class WaveformBarsDemo extends StatefulWidget {
  const WaveformBarsDemo({super.key});

  @override
  State<WaveformBarsDemo> createState() => _WaveformBarsDemoState();
}

class _WaveformBarsDemoState extends State<WaveformBarsDemo> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0A0A18),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFF00E5FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Neon Dreams',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Synthwave Artist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF00E5FF),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WaveformBarsWidget(
            barCount: 32,
            isPlaying: _isPlaying,
            color: const Color(0xFF00E5FF),
            peakColor: Colors.white,
            barRadius: 3,
            height: 52,
          ),
        ],
      ),
    );
  }
}
