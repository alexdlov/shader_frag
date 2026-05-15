import 'package:flutter/material.dart';

import '../components/aurora_widget.dart';
import '../components/glow_chart.dart';
import '../components/holographic_widget.dart';
import '../components/plasma_widget.dart';
import 'widgets/achievement_demo.dart';
import 'widgets/frosted_glass_demo.dart';
import 'widgets/hourglass_demo.dart';
import 'widgets/liquid_progress_demo.dart';
import 'widgets/loyalty_card.dart';
import 'widgets/section_header.dart';
import 'widgets/shader_card.dart';
import 'widgets/waveform_bars_demo.dart';

// ────────────────────────────────────────────────────────────
// ShadersPreview — use-case gallery
// ────────────────────────────────────────────────────────────

class ShadersPreview extends StatefulWidget {
  const ShadersPreview({super.key});

  @override
  State<ShadersPreview> createState() => _ShadersPreviewState();
}

class _ShadersPreviewState extends State<ShadersPreview> {
  static const _heartRate = <double>[
    72,
    75,
    78,
    82,
    95,
    110,
    128,
    142,
    155,
    162,
    168,
    165,
    158,
    150,
    138,
    125,
    110,
    95,
    88,
    82,
  ];

  static const _stepData = <double>[
    1200,
    2400,
    3100,
    4800,
    5500,
    6200,
    7800,
    8100,
    9200,
    10400,
    11000,
    12200,
    11500,
    10000,
    8800,
    7600,
    6400,
    5000,
    4200,
    3800,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080F),
        title: const Text(
          'Fragment Shader Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // ══════════════════════════════════════════════
              // 🌅  Ambient / Backgrounds
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '🌅',
                title: 'Ambient / Backgrounds',
                subtitle: 'GPU animation as a screen background — CPU cost: ~0',
              ),
              ShaderCard(
                title: 'Aurora — Onboarding Hero',
                hint: 'Full GPU animated background with content overlay',
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const AuroraWidget(
                      skyColor: Color(0xFF030308),
                      color1: Color(0xFF1AFFAA),
                      color2: Color(0xFF9918FF),
                      intensity: 1.2,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'MOTIONIX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your workouts. Your way.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Container(
                            width: 200,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: const Color(
                                0xFF1AFFAA,
                              ).withValues(alpha: 0.15),
                              border: Border.all(
                                color: const Color(
                                  0xFF1AFFAA,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Get started free',
                                style: TextStyle(
                                  color: Color(0xFF1AFFAA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ShaderCard(
                title: 'Plasma — Dashboard Background',
                hint: 'GPU background with stat chips rendered on top',
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const PlasmaWidget(
                      color1: Color(0xFF0D2A5A),
                      color2: Color(0xFF1A0040),
                      color3: Color(0xFF002830),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, Alex 👋',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              StatChip(
                                icon: Icons.directions_walk,
                                value: '8 240',
                                label: 'steps',
                              ),
                              SizedBox(width: 8),
                              StatChip(
                                icon: Icons.local_fire_department,
                                value: '420',
                                label: 'kcal',
                              ),
                              SizedBox(width: 8),
                              StatChip(
                                icon: Icons.bedtime,
                                value: '7h 20m',
                                label: 'sleep',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 📊  Data Visualization
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '📊',
                title: 'Data Visualization',
                subtitle: 'Health & finance charts — drag to select data point',
              ),
              ShaderCard(
                title: 'GlowChart — Heart Rate',
                hint:
                    'Tap / drag to select point. GPU bg + Path line = 2 layers.',
                height: 210,
                child: GlowChart(
                  data: _heartRate,
                  lineColor: const Color(0xFFFF2060),
                  bgTop: const Color(0xFF3A001A),
                  bgBottom: const Color(0xFF000208),
                  borderRadius: 0,
                ),
              ),
              ShaderCard(
                title: 'GlowChart — Daily Steps',
                hint:
                    'Same widget, different data and color — fully parameterised.',
                height: 210,
                child: GlowChart(
                  data: _stepData,
                  lineColor: const Color(0xFF00E5FF),
                  bgTop: const Color(0xFF001A33),
                  bgBottom: const Color(0xFF000508),
                  borderRadius: 0,
                ),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // ✨  Surface Effects
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '✨',
                title: 'Surface Effects',
                subtitle:
                    'Premium card sheen — move pointer to shift the shimmer',
              ),
              ShaderCard(
                title: 'Holographic — Loyalty / Apple Wallet style',
                hint: 'Drag or hover — rainbow sheen follows pointer',
                child: CardFrame(
                  builder: (w, h) => SizedBox(
                    width: w,
                    height: h,
                    child: const Stack(
                      fit: StackFit.expand,
                      children: [
                        HolographicWidget(
                          baseColor: Color(0xFFB8C8DC),
                          shimmer: 1.0,
                          borderRadius: 0,
                        ),
                        LoyaltyCard(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🏆  Events
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '🏆',
                title: 'Events',
                subtitle:
                    'Event-driven shader — shown only when achievement fires',
              ),
              const ShaderCard(
                title: 'Energy — Achievement Unlock',
                hint: 'Tap to trigger the GPU burst. Auto-resets after 3 s.',
                height: 220,
                child: AchievementDemo(),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // ⏳  Timer
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '⏳',
                title: 'Timer',
                subtitle:
                    'Sand falls on the GPU — progress, stream and wave in one shader pass',
              ),
              const ShaderCard(
                title: 'Hourglass — Sand Timer',
                hint:
                    'Select duration, press Start. Sand stream + surface wave driven by uTime.',
                height: 500,
                child: HourglassDemo(),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 💧  State / Progress
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '💧',
                title: 'State / Progress',
                subtitle:
                    'Liquid fill via sin-wave surface — progress tweens smoothly',
              ),
              const ShaderCard(
                title: 'LiquidProgress — Water Intake Tracker',
                hint:
                    'Tap levels to animate. Wave surface from two overlaid sin functions.',
                height: 220,
                child: LiquidProgressDemo(),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🎵  Audio / Media
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '🎵',
                title: 'Audio / Media',
                subtitle: 'Pure CustomPainter — no GLSL, 100% canvas API',
              ),
              const ShaderCard(
                title: 'WaveformBars — Music Player Equalizer',
                hint:
                    'Tap ▶ / ⏸ — Ticker lerps bar heights. Gradient shader cached by size.',
                height: 158,
                child: WaveformBarsDemo(),
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🔮  Compositing / Blur
              // ══════════════════════════════════════════════
              const SectionHeader(
                icon: '🔮',
                title: 'Compositing / Blur',
                subtitle:
                    'setImageSampler — pass a live texture to GLSL. Most advanced technique.',
              ),
              const ShaderCard(
                title: 'FrostedGlass — Bottom Panel over Live BG',
                hint:
                    'toImageSync() captures RepaintBoundary → sampler2D → 9-tap blur + grain.',
                height: 340,
                child: FrostedGlassDemo(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
