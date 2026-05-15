import 'package:flutter/material.dart';

// ── ShaderCard — card container ───────────────────────────────
// height: null → size determined by child (e.g. CardFrame)
class ShaderCard extends StatelessWidget {
  const ShaderCard({
    required this.title,
    required this.hint,
    required this.child,
    this.height = 200,
    super.key,
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

// ── CardFrame — credit card proportions 85.6×54mm (ratio 1.586) ──
// Max width 440px, centred, clipped.
// Accepts builder(width, height) to pass exact sizes to widgets
// that require fixed dimensions (HolographicWidget etc.)
class CardFrame extends StatelessWidget {
  const CardFrame({required this.builder, super.key});

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

// ── StatChip — compact chip for dashboard overlay ────────────────
class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
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
