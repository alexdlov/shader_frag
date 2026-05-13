import 'package:flutter/material.dart';

import '../components/aurora_widget.dart';
import '../components/energy_widget.dart';
import '../components/frosted_glass_widget.dart';
import '../components/glow_chart.dart';
import '../components/holographic_widget.dart';
import '../components/liquid_progress_widget.dart';
import '../components/plasma_widget.dart';
import '../components/waveform_bars_widget.dart';

// ────────────────────────────────────────────────────────────
// ShadersPreview — use-case gallery
// ────────────────────────────────────────────────────────────
// Each shader is shown in the context where it would realistically
// appear in a production app.
// Max content width: 680px (works well on tablet / web / desktop).
// ────────────────────────────────────────────────────────────

class ShadersPreview extends StatefulWidget {
  const ShadersPreview({super.key});

  @override
  State<ShadersPreview> createState() => _ShadersPreviewState();
}

class _ShadersPreviewState extends State<ShadersPreview> {
  // ── Sample data ────────────────────────────────────────────
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
              const _SectionHeader(
                icon: '🌅',
                title: 'Ambient / Backgrounds',
                subtitle: 'GPU animation as a screen background — CPU cost: ~0',
              ),

              // Aurora: onboarding hero
              _ShaderCard(
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

              // Plasma: dashboard
              _ShaderCard(
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
                              _StatChip(
                                icon: Icons.directions_walk,
                                value: '8 240',
                                label: 'steps',
                              ),
                              SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.local_fire_department,
                                value: '420',
                                label: 'kcal',
                              ),
                              SizedBox(width: 8),
                              _StatChip(
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
              const _SectionHeader(
                icon: '📊',
                title: 'Data Visualization',
                subtitle: 'Health & finance charts — drag to select data point',
              ),

              _ShaderCard(
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

              _ShaderCard(
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
              const _SectionHeader(
                icon: '✨',
                title: 'Surface Effects',
                subtitle:
                    'Premium card sheen — move pointer to shift the shimmer',
              ),

              _ShaderCard(
                title: 'Holographic — Loyalty / Apple Wallet style',
                hint: 'Drag or hover — rainbow sheen follows pointer',
                child: _CardFrame(
                  builder: (w, h) => SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: const [
                        HolographicWidget(
                          baseColor: Color(0xFFB8C8DC),
                          shimmer: 1.0,
                          borderRadius: 0,
                        ),
                        _LoyaltyCard(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🏆  Events
              // ══════════════════════════════════════════════
              const _SectionHeader(
                icon: '🏆',
                title: 'Events',
                subtitle:
                    'Event-driven shader — shown only when achievement fires',
              ),

              _ShaderCard(
                title: 'Energy — Achievement Unlock',
                hint: 'Tap to trigger the GPU burst. Auto-resets after 3 s.',
                height: 220,
                child: const _AchievementDemo(),
              ),

              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 💧  State / Progress
              // ══════════════════════════════════════════════
              const _SectionHeader(
                icon: '💧',
                title: 'State / Progress',
                subtitle:
                    'Liquid fill via sin-wave surface — progress tweens smoothly',
              ),

              _ShaderCard(
                title: 'LiquidProgress — Water Intake Tracker',
                hint:
                    'Tap levels to animate. Wave surface from two overlaid sin functions.',
                height: 220,
                child: const _LiquidProgressDemo(),
              ),

              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🎵  Audio / Media
              // ══════════════════════════════════════════════
              const _SectionHeader(
                icon: '🎵',
                title: 'Audio / Media',
                subtitle: 'Pure CustomPainter — no GLSL, 100% canvas API',
              ),

              _ShaderCard(
                title: 'WaveformBars — Music Player Equalizer',
                hint:
                    'Tap ▶ / ⏸ — Ticker lerps bar heights. Gradient shader cached by size.',
                height: 158,
                child: const _WaveformBarsDemo(),
              ),

              const SizedBox(height: 8),

              // ══════════════════════════════════════════════
              // 🔮  Compositing / Blur
              // ══════════════════════════════════════════════
              const _SectionHeader(
                icon: '🔮',
                title: 'Compositing / Blur',
                subtitle:
                    'setImageSampler — pass a live texture to GLSL. Most advanced technique.',
              ),

              _ShaderCard(
                title: 'FrostedGlass — Bottom Panel over Live BG',
                hint:
                    'toImageSync() captures RepaintBoundary → sampler2D → 9-tap blur + grain.',
                height: 260,
                child: const _FrostedGlassDemo(),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _SectionHeader
// ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _ShaderCard — card container
// height: null → size determined by child (e.g. _CardFrame)
// ────────────────────────────────────────────────────────────

class _ShaderCard extends StatelessWidget {
  const _ShaderCard({
    required this.title,
    required this.hint,
    required this.child,
    this.height = 200,
  });

  final String title;
  final String hint;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: height != null
                  ? SizedBox(height: height, child: child)
                  : child,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _CardFrame — credit card proportions 85.6×54mm (ratio 1.586)
// Max width 440px, centred, clipped.
// Accepts builder(width, height) to pass exact sizes to widgets
// that require fixed dimensions (HolographicWidget etc.)
// ────────────────────────────────────────────────────────────

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.builder});

  final Widget Function(double w, double h) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(0.0, 440.0);
        final h = w / 1.586; // standard credit card ratio
        return ColoredBox(
          color: const Color(0xFF060610),
          child: Align(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: builder(w, h),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────
// _StatChip — compact chip for dashboard overlay
// ────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white60, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _AchievementDemo — EnergyWidget activates only on tap
// ────────────────────────────────────────────────────────────

class _AchievementDemo extends StatefulWidget {
  const _AchievementDemo();

  @override
  State<_AchievementDemo> createState() => _AchievementDemoState();
}

class _AchievementDemoState extends State<_AchievementDemo> {
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
          // Energy shader renders only when needed
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

// ────────────────────────────────────────────────────────────
// _LoyaltyCard — content overlay for HolographicWidget demo
// ────────────────────────────────────────────────────────────

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MOTIONIX',
                style: TextStyle(
                  color: Colors.black45.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black45.withValues(alpha: 0.10),
                ),
                child: Text(
                  'PLATINUM',
                  style: TextStyle(
                    color: Colors.black45.withValues(alpha: 0.75),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '12 450 pts',
            style: TextStyle(
              color: Colors.black45.withValues(alpha: 0.70),
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Loyalty Points',
            style: TextStyle(
              color: Colors.black45.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.black45.withValues(alpha: 0.50),
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                'Alex Adopnex',
                style: TextStyle(
                  color: Colors.black45.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// _LiquidProgressDemo — Water intake with tap-to-fill UX
// ────────────────────────────────────────────────────────────
class _LiquidProgressDemo extends StatefulWidget {
  const _LiquidProgressDemo();

  @override
  State<_LiquidProgressDemo> createState() => _LiquidProgressDemoState();
}

class _LiquidProgressDemoState extends State<_LiquidProgressDemo> {
  double _progress = 0.35;

  static const _levels = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const _labels = ['0%', '25%', '50%', '75%', '100%'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Liquid fills the entire background of the card
        LiquidProgressWidget(
          progress: _progress,
          fillColor: const Color(0xFF0096C7),
          bgColor: const Color(0xFF001220),
          waveAmplitude: 0.022,
          borderRadius: 0,
        ),
        // Content on top of the liquid
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
            // Level buttons
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

// ────────────────────────────────────────────────────────────
// _WaveformBarsDemo — Music player EQ with play/pause
// ────────────────────────────────────────────────────────────
class _WaveformBarsDemo extends StatefulWidget {
  const _WaveformBarsDemo();

  @override
  State<_WaveformBarsDemo> createState() => _WaveformBarsDemoState();
}

class _WaveformBarsDemoState extends State<_WaveformBarsDemo> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Song info row ───────────────────────────────
          Row(
            children: [
              // Album art placeholder
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
              // Title + artist
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
              // Play / Pause button — the only place with setState
              // The WaveformBarsWidget itself does not rebuild when _isPlaying changes — only
              // didUpdateWidget() updates _config.value → notifies the painter
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
          // ── Waveform equalizer ──────────────────────────
          // WaveformBarsWidget itself manages its animation through Ticker
          // No setState inside the widget — only Listenable chain
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

// ────────────────────────────────────────────────────────────
// _FrostedGlassDemo — Frosted bottom panel over animated BG
// ────────────────────────────────────────────────────────────
class _FrostedGlassDemo extends StatefulWidget {
  const _FrostedGlassDemo();

  @override
  State<_FrostedGlassDemo> createState() => _FrostedGlassDemoState();
}

class _FrostedGlassDemoState extends State<_FrostedGlassDemo> {
  // GlobalKey on the RepaintBoundary that wraps the background widget.
  // FrostedGlassWidget uses this key to capture the texture via
  // RenderRepaintBoundary.toImageSync() → shader.setImageSampler(0, image)
  final _bgKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background: animated PlasmaWidget ──────────────
        // RepaintBoundary is needed so that FrostedGlassWidget can capture
        // именно этот слой через _bgKey
        RepaintBoundary(
          key: _bgKey,
          child: const PlasmaWidget(
            color1: Color(0xFF8B6FA8),
            color2: Color(0xFFB89DC9),
            color3: Color(0xFF7BC5D6),
            borderRadius: 0,
          ),
        ),

        // ── Content "behind the glass" — visible through blur ──
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

        // ── Frosted glass player panel ────────────────────
        // Positioned at the bottom. Captures the background via _bgKey.
        // Updates the texture ~5 fps — blur is "live" but not expensive.
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
                        // Progress bar mockup
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.4,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
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
