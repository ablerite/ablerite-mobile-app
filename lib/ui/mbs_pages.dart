import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/habit_reminder.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';
import 'widgets/habit_tracker_widget.dart';
import 'session_timer_page.dart';
import 'mbs_log_page.dart';

class MBSPage extends StatefulWidget {
  final String title;
  final String section;
  final Color color;
  final IconData icon;
  final String unit;

  const MBSPage({
    super.key,
    required this.title,
    required this.section,
    required this.color,
    required this.icon,
    this.unit = 'mins',
  });

  @override
  State<MBSPage> createState() => _MBSPageState();
}

class _MBSPageState extends State<MBSPage> {
  List<Item> _logs = [];
  bool _isLoading = true;
  final TextEditingController _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showSuccess = false;

  HabitCategory _getCategoryFromSection(String section) {
    switch (section) {
      case 'meditation_logs':
        return HabitCategory.mind;
      case 'body_logs':
        return HabitCategory.body;
      case 'spirit_logs':
        return HabitCategory.spirit;
      default:
        return HabitCategory.mind;
    }
  }

  @override
  void initState() {
    super.initState();
    pushPage();
    _initNotifications();
    _fetchLogs();
  }

  Future<void> _initNotifications() async {
    await NotificationService().initialize();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', widget.section)
          .order('date', ascending: false); // Order by date descending

      if (mounted) {
        setState(() {
          _logs = (response as List).map((e) => Item.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Get current week's date range (Sunday to Saturday)
  Map<String, DateTime> _getCurrentWeekRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    // Go back to Sunday
    final startOfWeek = start.subtract(Duration(days: start.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return {'start': startOfWeek, 'end': endOfWeek};
  }

  bool _isInCurrentWeek(String? dateStr) {
    if (dateStr == null || !dateStr.contains('-')) return false;
    final logDate = DateTime.tryParse(dateStr);
    if (logDate == null) return false;

    final range = _getCurrentWeekRange();
    return logDate.isAfter(range['start']!.subtract(const Duration(days: 1))) &&
        logDate.isBefore(range['end']!);
  }

  int _getWeeklyTotal() {
    int total = 0;
    for (var log in _logs) {
      if (_isInCurrentWeek(log.date)) {
        total += log.value ?? 0;
      }
    }
    return total;
  }

  // Get all 7 days of current week
  List<DateTime> _getWeekDays() {
    final range = _getCurrentWeekRange();
    final List<DateTime> days = [];
    for (int i = 6; i >= 0; i--) {
      days.add(range['start']!.add(Duration(days: i)));
    }
    return days;
  }

  // Get entry for a specific day
  Item? _getEntryForDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    try {
      return _logs.firstWhere((log) => log.date == dayStr);
    } catch (e) {
      return null;
    }
  }

  Future<void> _addLog() async {
    final valueText = _valueController.text;
    if (valueText.isEmpty) return;

    final value = int.tryParse(valueText);
    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid number')));
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Format date as YYYY-MM-DD
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Get day name (e.g., Mon, Tue) to match desktop format
      final dayName = DateFormat('E').format(_selectedDate);

      // Match desktop payload format - let Supabase generate the ID
      final payload = {
        'section': widget.section,
        'value': value,
        'text': dayName,
        'date': dateStr,
        'user_id': userId,
      };

      // Use .select() to get the inserted record back, matching desktop behavior
      final response = await Supabase.instance.client
          .from('items')
          .insert(payload)
          .select();

      if (response.isNotEmpty) {
        // Add the new item to the list
        final newItem = Item.fromJson(response.first);
        setState(() {
          _logs = [newItem, ..._logs];
        });
      }

      if (mounted) {
        setState(() {
          _showSuccess = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      }

      _valueController.clear();
      // Reset date to today
      setState(() {
        _selectedDate = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding log: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate weekly total
    final weeklyTotal = _getWeeklyTotal();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const FocusAwareBackButton(),
        title: FocusAwareAppBarTitle(
          child: Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: const [FocusAppBarActions(guide: FocusHelpGuide.wellness)],
      ),
      // ── Persistent log input row pinned to the bottom ──────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(40),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Log minutes…',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(100),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                icon: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              FloatingActionButton.small(
                heroTag: 'mbs_add_log',
                onPressed: _addLog,
                backgroundColor: _showSuccess ? Colors.green : widget.color,
                foregroundColor: Colors.white,
                elevation: 0,
                child: Icon(_showSuccess ? Icons.check : Icons.add),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // ── Header Card (tap → log page) ──────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MBSLogPage(
                          title: widget.title,
                          section: widget.section,
                          color: widget.color,
                        ),
                      ),
                    ).then((_) => _fetchLogs()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This week',
                                  style: TextStyle(
                                    color: widget.color.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$weeklyTotal ${widget.unit}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'View Log',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: widget.color.withAlpha(180),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: widget.color.withAlpha(180),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Session Timer button ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionTimerPage(
                              title: widget.title,
                              section: widget.section,
                              label: widget.section == 'meditation_logs'
                                  ? 'Meditate'
                                  : widget.section == 'body_logs'
                                  ? 'Train'
                                  : 'Reflect',
                              color: widget.color,
                            ),
                          ),
                        ).then((_) => _fetchLogs());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.color,
                        side: BorderSide(
                          color: widget.color.withAlpha(80),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: widget.color,
                      ),
                      label: Text(
                        'Session Timer',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Weekly bar chart (always visible) ─────────────────
                  SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _getWeekDays().map((day) {
                        final entry = _getEntryForDay(day);
                        final value = entry?.value ?? 0;
                        final heightFactor = value / 100.0;
                        final isToday =
                            DateFormat('yyyy-MM-dd').format(day) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 22,
                              height:
                                  4 +
                                  56 * (heightFactor > 1 ? 1 : heightFactor),
                              decoration: BoxDecoration(
                                color: value > 0
                                    ? widget.color.withOpacity(0.7)
                                    : widget.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                                border: isToday
                                    ? Border.all(
                                        color: widget.color,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('E').format(day),
                              style: TextStyle(
                                color: isToday
                                    ? widget.color
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(100),
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Habit Tracker ─────────────────────────────────────
                  HabitTrackerWidget(
                    category: _getCategoryFromSection(widget.section),
                    categoryColor: widget.color,
                    section: widget.section,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
