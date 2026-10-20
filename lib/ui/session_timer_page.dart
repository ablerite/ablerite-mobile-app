import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/notification_service.dart';

class SessionTimerPage extends StatefulWidget {
  final String title; // e.g. "Mind Practice"
  final String label; // e.g. "Meditate"
  final String section; // e.g. "meditation_logs"
  final Color color;

  const SessionTimerPage({
    super.key,
    required this.title,
    required this.label,
    required this.section,
    required this.color,
  });

  @override
  State<SessionTimerPage> createState() => _SessionTimerPageState();
}

class _SessionTimerPageState extends State<SessionTimerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<int> _presets = [15, 30, 60];
  int _selectedMinutes = 15;
  bool _isCustom = false;

  late int _totalSeconds;
  int _remainingSeconds = 0;
  bool _running = false;
  bool _started = false;
  Timer? _timer;
  Timer? _alarmTimer;
  Timer? _alarmAutoStopTimer;
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _customAlarmPlaying = false;
  DateTime? _endsAt;
  bool _completionHandled = false;
  String? _sessionLogId;

  String get _alarmId => widget.section;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stopForegroundAlarm();
    NotificationService().cancelSessionTimerAlarm(_alarmId);
    _alarmPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running) {
      _syncRemainingTime();
    }
  }

  void _selectPreset(int minutes) {
    if (_running) return;
    setState(() {
      _isCustom = false;
      _selectedMinutes = minutes;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
      _started = false;
    });
  }

  Future<void> _enterCustomTime() async {
    if (_running) return;
    int tempMinutes = _isCustom ? _selectedMinutes : 10;
    final FixedExtentScrollController wheelController =
        FixedExtentScrollController(initialItem: tempMinutes - 1);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Custom Duration',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isCustom = true;
                          _selectedMinutes = tempMinutes;
                          _totalSeconds = tempMinutes * 60;
                          _remainingSeconds = _totalSeconds;
                          _started = false;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Set',
                        style: GoogleFonts.outfit(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Wheel
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection highlight
                    Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.color.withAlpha(50)),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: wheelController,
                      itemExtent: 44,
                      perspective: 0.004,
                      diameterRatio: 1.6,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        tempMinutes = index + 1;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 180,
                        builder: (context, index) {
                          final mins = index + 1;
                          return Center(
                            child: Text(
                              '$mins min${mins == 1 ? '' : 's'}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    wheelController.dispose();
  }

  Future<void> _startPause() async {
    if (_running) {
      _syncRemainingTime();
      _timer?.cancel();
      _endsAt = null;
      await NotificationService().cancelSessionTimerAlarm(_alarmId);
      if (mounted) setState(() => _running = false);
    } else {
      if (_remainingSeconds == 0) _reset();
      setState(() {
        if (!_started) _sessionLogId = const Uuid().v4();
        _running = true;
        _started = true;
        _completionHandled = false;
      });
      _endsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
      _scheduleTicks();
      try {
        await NotificationService().scheduleSessionTimerAlarm(
          timerId: _alarmId,
          endsAt: _endsAt!,
          label: widget.label.toLowerCase(),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Allow notifications to hear the timer alarm when the screen is off.',
              ),
            ),
          );
        }
      }
    }
  }

  void _scheduleTicks() {
    _timer?.cancel();
    _syncRemainingTime();
    if (!_running) return;
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _syncRemainingTime(),
    );
  }

  void _syncRemainingTime() {
    final endsAt = _endsAt;
    if (!_running || endsAt == null || !mounted) return;

    final milliseconds = endsAt.difference(DateTime.now()).inMilliseconds;
    final remaining = milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
    if (remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
    if (remaining == 0) _finishTimer();
  }

  void _finishTimer() {
    if (_completionHandled || !mounted) return;
    _completionHandled = true;
    _timer?.cancel();
    _endsAt = null;
    setState(() {
      _running = false;
      _remainingSeconds = 0;
    });
    _onComplete();
  }

  void _reset() {
    _timer?.cancel();
    _stopForegroundAlarm();
    _endsAt = null;
    _completionHandled = false;
    _sessionLogId = null;
    NotificationService().cancelSessionTimerAlarm(_alarmId);
    setState(() {
      _running = false;
      _started = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onComplete() async {
    _startForegroundAlarm();

    // ── Auto-log to Supabase ────────────────────────────────
    bool logged = false;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final now = DateTime.now();
        // Keep one stable primary key for this timer run. If completion is
        // delivered twice (for example, a lifecycle resume racing a tick),
        // Supabase rejects the duplicate instead of creating a second log.
        final logId = _sessionLogId ??= const Uuid().v4();
        await Supabase.instance.client.from('items').insert({
          'id': logId,
          'section': widget.section,
          'value': _selectedMinutes,
          'text': DateFormat('E').format(now),
          'date': DateFormat('yyyy-MM-dd').format(now),
          'user_id': userId,
        });
        logged = true;
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Session Complete 🎉',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'You completed a $_selectedMinutes minute ${widget.label.toLowerCase()} session.'
          '${logged ? '\n\nMinutes auto-logged ✓' : ''}',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              _stopForegroundAlarm();
              await NotificationService().cancelSessionTimerAlarm(_alarmId);
              if (!ctx.mounted || !mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Turn Off Alarm',
              style: GoogleFonts.outfit(
                color: widget.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startForegroundAlarm() {
    _stopForegroundAlarm();

    void alert() {
      HapticFeedback.heavyImpact();
      if (!_customAlarmPlaying) {
        SystemSound.play(SystemSoundType.alert);
      }
    }

    alert();
    _alarmTimer = Timer.periodic(const Duration(seconds: 2), (_) => alert());
    () async {
      try {
        await _alarmPlayer.setLoopMode(LoopMode.one);
        await _alarmPlayer.setAsset(sessionTimerAlarmSoundAsset);
        if (!mounted || _alarmAutoStopTimer == null) return;
        _customAlarmPlaying = true;
        await _alarmPlayer.play();
      } catch (error) {
        debugPrint('Could not play custom session alarm: $error');
      }
    }();
    _alarmAutoStopTimer = Timer(const Duration(minutes: 1), () {
      _stopForegroundAlarm();
      NotificationService().cancelSessionTimerAlarm(_alarmId);
    });
  }

  void _stopForegroundAlarm() {
    _customAlarmPlaying = false;
    _alarmPlayer.stop();
    _alarmTimer?.cancel();
    _alarmTimer = null;
    _alarmAutoStopTimer?.cancel();
    _alarmAutoStopTimer = null;
  }

  double get _progress => _totalSeconds > 0
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ringBg = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_started)
            TextButton(
              onPressed: _reset,
              child: Text(
                'Reset',
                style: GoogleFonts.outfit(
                  color: Colors.red.withAlpha(200),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Circular timer ring ─────────────────────────────────────
            ScaleTransition(
              scale: _running ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _progress,
                    ringColor: widget.color,
                    bgColor: ringBg,
                    strokeWidth: 14,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_started) ...[
                          Text(
                            '$_selectedMinutes',
                            style: GoogleFonts.outfit(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: widget.color,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'minutes',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: widget.color.withAlpha(180),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ] else ...[
                          Text(
                            minutes.toString().padLeft(2, '0'),
                            style: GoogleFonts.outfit(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: widget.color,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            ':${seconds.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
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

            const Spacer(flex: 1),

            // ── Preset duration chips ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._presets.map((mins) {
                    final selected =
                        mins == _selectedMinutes && !_isCustom && !_started;
                    return GestureDetector(
                      onTap: () => _selectPreset(mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? widget.color
                              : widget.color.withAlpha(18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? widget.color
                                : widget.color.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          '${mins}m',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : widget.color,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Custom chip
                  GestureDetector(
                    onTap: _enterCustomTime,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isCustom
                            ? widget.color
                            : widget.color.withAlpha(18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isCustom
                              ? widget.color
                              : widget.color.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: _isCustom ? Colors.white : widget.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCustom ? '${_selectedMinutes}m' : 'Custom',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isCustom ? Colors.white : widget.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── Start / Pause button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startPause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _running
                            ? 'Pause'
                            : _started
                            ? 'Resume'
                            : widget.label,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter
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

    // Background track
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

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
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
