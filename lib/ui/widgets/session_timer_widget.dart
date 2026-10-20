import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A compact session timer with circular progress, preset durations,
/// and start / pause / reset controls. Drop into any MBS page.
class SessionTimerWidget extends StatefulWidget {
  final Color color;
  final String label; // e.g. "Meditate", "Train", "Reflect"

  const SessionTimerWidget({
    super.key,
    required this.color,
    this.label = 'Start Session',
  });

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget>
    with TickerProviderStateMixin {
  // Preset durations in minutes
  static const List<int> _presets = [5, 10, 15, 20, 30];
  int _selectedMinutes = 10;

  // Timer state
  late int _totalSeconds;
  int _remainingSeconds = 0;
  bool _running = false;
  bool _started = false;
  Timer? _timer;

  // Ring animation
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_running) return;
    setState(() {
      _selectedMinutes = minutes;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
      _started = false;
    });
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
      _pulseController.stop();
      setState(() => _running = false);
    } else {
      if (_remainingSeconds == 0) _reset();
      setState(() {
        _running = true;
        _started = true;
      });
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _pulseController.stop();
          setState(() {
            _running = false;
            _remainingSeconds = 0;
          });
          _onComplete();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _running = false;
      _started = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Session Complete 🎉',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Great work! You completed $_selectedMinutes minutes.',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            child: Text(
              'Done',
              style: GoogleFonts.outfit(
                color: widget.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _progress => _totalSeconds > 0
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringBg = isDark
        ? Colors.white.withAlpha(18)
        : Colors.black.withAlpha(12);
    final labelColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.color.withAlpha(40), width: 1.2),
      ),
      child: Column(
        children: [
          // ── Title ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Timer',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              if (_started)
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Circular ring ────────────────────────────────────────────
          ScaleTransition(
            scale: _running ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _progress,
                  ringColor: widget.color,
                  bgColor: ringBg,
                  strokeWidth: 10,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_started) ...[
                        Text(
                          '$_selectedMinutes',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w200,
                            color: widget.color,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'mins',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: widget.color.withAlpha(180),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${_remainingSeconds ~/ 60}'.padLeft(2, '0'),
                          style: GoogleFonts.outfit(
                            fontSize: 40,
                            fontWeight: FontWeight.w200,
                            color: widget.color,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          ':${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: widget.color.withAlpha(180),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Preset chips ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presets.map((mins) {
              final selected = mins == _selectedMinutes;
              return GestureDetector(
                onTap: () => _selectPreset(mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? widget.color : widget.color.withAlpha(18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? widget.color
                          : widget.color.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    '${mins}m',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : widget.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Start / Pause button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startPause,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _running
                        ? 'Pause'
                        : _started
                        ? 'Resume'
                        : widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom ring painter
// ---------------------------------------------------------------------------
class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2; // top

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress ring
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
