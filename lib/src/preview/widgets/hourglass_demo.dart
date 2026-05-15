import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../components/hourglass_widget.dart';

class HourglassDemo extends StatefulWidget {
  const HourglassDemo({super.key});

  @override
  State<HourglassDemo> createState() => _HourglassDemoState();
}

class _HourglassDemoState extends State<HourglassDemo> {
  static const _options = [
    Duration(minutes: 1),
    Duration(minutes: 3),
    Duration(minutes: 5),
  ];
  static const _labels = ['1 min', '3 min', '5 min'];

  Duration _selected = _options[0];
  bool _running = false;
  bool _completed = false;
  int _resetToken = 0;

  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;

  Duration get _elapsed {
    if (_startedAt == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_startedAt!);
  }

  Duration get _remaining {
    final r = _selected - _elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  void _start() {
    if (_completed) {
      _doReset();
      return;
    }
    setState(() {
      _running = true;
      _startedAt = DateTime.now();
    });
  }

  void _pause() {
    setState(() {
      _accumulated += _startedAt != null
          ? DateTime.now().difference(_startedAt!)
          : Duration.zero;
      _startedAt = null;
      _running = false;
    });
  }

  void _doReset() {
    setState(() {
      _running = false;
      _completed = false;
      _startedAt = null;
      _accumulated = Duration.zero;
      _resetToken++;
    });
  }

  void _onComplete() {
    setState(() {
      _running = false;
      _completed = true;
    });
  }

  String _formatRemaining() {
    final r = _remaining;
    final m = r.inMinutes;
    final s = r.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return TimerRefresh(enabled: _running, builder: _buildContent);
  }

  Widget _buildContent(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D1B2A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_options.length, (i) {
              final sel = _selected == _options[i];
              return GestureDetector(
                onTap: _running
                    ? null
                    : () => setState(() {
                        _selected = _options[i];
                        _accumulated = Duration.zero;
                        _startedAt = null;
                        _completed = false;
                      }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? const Color(0xFFE8C57A).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFFE8C57A).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      color: sel ? const Color(0xFFE8C57A) : Colors.white38,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            height: 280,
            child: HourglassWidget(
              key: ValueKey(_selected),
              duration: _selected,
              running: _running,
              resetToken: _resetToken,
              onComplete: _onComplete,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _completed
                ? const Text(
                    "Time's up! \u23f3",
                    key: ValueKey('done'),
                    style: TextStyle(
                      color: Color(0xFFE8C57A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text(
                    _formatRemaining(),
                    key: const ValueKey('timer'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 30,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 5,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_running)
                HourglassBtn(
                  icon: _completed
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  label: _completed ? 'Reset' : 'Start',
                  color: const Color(0xFFE8C57A),
                  onTap: _start,
                )
              else
                HourglassBtn(
                  icon: Icons.pause_rounded,
                  label: 'Pause',
                  color: Colors.white54,
                  onTap: _pause,
                ),
              if (_running || _accumulated > Duration.zero) ...[
                const SizedBox(width: 10),
                HourglassBtn(
                  icon: Icons.stop_rounded,
                  label: 'Reset',
                  color: Colors.white24,
                  onTap: _doReset,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── TimerRefresh — rebuilds subtree every second while enabled ───
class TimerRefresh extends StatefulWidget {
  const TimerRefresh({required this.enabled, required this.builder, super.key});

  final bool enabled;
  final WidgetBuilder builder;

  @override
  State<TimerRefresh> createState() => _TimerRefreshState();
}

class _TimerRefreshState extends State<TimerRefresh>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    // If declared as a `late final` field initializer, it would be lazily
    // created on first access, which might happen in dispose() when the
    // context is already deactivated → "deactivated widget ancestor" error.
    _ticker = createTicker(_onTick);
    if (widget.enabled) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant TimerRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (!widget.enabled) return;
    if (elapsed.inSeconds != _last.inSeconds) {
      _last = elapsed;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ── HourglassBtn — icon + label pill button ───────────────────────
class HourglassBtn extends StatelessWidget {
  const HourglassBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
