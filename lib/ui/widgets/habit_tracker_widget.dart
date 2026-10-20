import 'package:flutter/material.dart';
import 'ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/habit_reminder.dart';
import '../../services/notification_service.dart';

class HabitTrackerWidget extends StatefulWidget {
  final HabitCategory category;
  final Color categoryColor;
  final String section; // for logging to Supabase

  const HabitTrackerWidget({
    super.key,
    required this.category,
    required this.categoryColor,
    required this.section,
  });

  @override
  State<HabitTrackerWidget> createState() => _HabitTrackerWidgetState();
}

class _HabitTrackerWidgetState extends State<HabitTrackerWidget> {
  List<HabitReminder> _habits = [];
  bool _isLoading = true;
  String? _expandedHabitId;

  @override
  void initState() {
    super.initState();
    _loadAndInitializeHabits();
  }

  Future<void> _loadAndInitializeHabits() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // Initialize default habits if needed
    var habits = await initializeDefaultHabits(userId);

    // Refresh for new day
    habits = await refreshHabitsForNewDay(habits);

    final categoryHabits = habits
        .where((h) => h.userId == userId && h.category == widget.category)
        .toList();

    if (!mounted) return;
    setState(() {
      _habits = categoryHabits;
      _isLoading = false;
    });
  }

  Future<void> _loadHabits() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final habits = await loadHabitsFromStorage();
    final refreshedHabits = await refreshHabitsForNewDay(habits);
    if (!mounted) return;
    setState(() {
      _habits = refreshedHabits
          .where((h) => h.userId == userId && h.category == widget.category)
          .toList();
    });
  }

  /// Persists [updatedHabit], replacing the existing entry with the same id
  /// or appending it if this habit hasn't been saved to storage yet (e.g. a
  /// freshly-built default that the user is interacting with for the first
  /// time). Previously the "append" case was missing, so the very first
  /// toggle/edit on a not-yet-persisted habit was silently dropped and the
  /// UI snapped back after the next reload.
  Future<void> _persistHabit(HabitReminder updatedHabit) async {
    final allHabits = await loadHabitsFromStorage();
    final index = allHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      allHabits[index] = updatedHabit;
    } else {
      allHabits.add(updatedHabit);
    }
    await saveHabitsToStorage(allHabits);
  }

  /// Wraps [NotificationService.scheduleHabitReminder] so a scheduling
  /// failure (e.g. exact-alarm permission denied on Android 12+) surfaces to
  /// the user instead of failing silently while the toggle still shows "on".
  Future<bool> _scheduleReminder(HabitReminder habit) async {
    try {
      await NotificationService().scheduleHabitReminder(habit);
      return true;
    } catch (e) {
      debugPrint('Error scheduling habit reminder: $e');
      if (mounted) {
        final message = e
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set reminder: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _toggleHabit(HabitReminder habit, bool enabled) async {
    final updatedHabit = habit.copyWith(enabled: enabled);
    await _persistHabit(updatedHabit);

    if (enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) {
        // Do not leave a reminder looking enabled when no OS notification was
        // registered. Restore the exact prior state after a scheduling or
        // permission failure.
        await _persistHabit(habit);
      }
    } else {
      await NotificationService().cancelHabitReminder(habit.id);
    }

    await _loadHabits();
  }

  Future<void> _updateReminderTime(HabitReminder habit, TimeOfDay time) async {
    final updatedHabit = habit.copyWith(reminderTime: time);
    await _persistHabit(updatedHabit);

    if (habit.enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) await _persistHabit(habit);
    }

    await _loadHabits();
  }

  Future<void> _updateStartTime(HabitReminder habit, TimeOfDay? time) async {
    final updatedHabit = habit.copyWith(startTime: time);
    await _persistHabit(updatedHabit);

    if (habit.enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) await _persistHabit(habit);
    }

    await _loadHabits();
  }

  Future<void> _updateEndTime(HabitReminder habit, TimeOfDay? time) async {
    final updatedHabit = habit.copyWith(endTime: time);
    await _persistHabit(updatedHabit);

    if (habit.enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) await _persistHabit(habit);
    }

    await _loadHabits();
  }

  Future<void> _updateFrequency(
    HabitReminder habit,
    ReminderFrequency frequency,
  ) async {
    final updatedHabit = habit.copyWith(frequency: frequency);
    await _persistHabit(updatedHabit);

    if (habit.enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) await _persistHabit(habit);
    }

    await _loadHabits();
  }

  Future<void> _toggleDay(HabitReminder habit, int day) async {
    final currentDays = List<int>.from(habit.selectedDays);

    if (currentDays.contains(day)) {
      // Don't allow removing all days
      if (currentDays.length > 1) {
        currentDays.remove(day);
      }
    } else {
      currentDays.add(day);
    }

    currentDays.sort();
    final updatedHabit = habit.copyWith(selectedDays: currentDays);
    await _persistHabit(updatedHabit);

    if (habit.enabled) {
      final scheduled = await _scheduleReminder(updatedHabit);
      if (!scheduled) await _persistHabit(habit);
    }

    await _loadHabits();
  }

  @override
  Widget build(BuildContext context) {
    final habitsForCategory = HabitDefinitions.getHabitsForCategory(
      widget.category,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Habits',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.categoryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(child: AbleriteLoadingIndicator())
        else
          ...habitsForCategory.map((habitDef) {
            final habit = _habits.firstWhere(
              (h) => h.habitName == habitDef['name'],
              orElse: () => HabitReminder(
                id: '${widget.category.name}_${habitDef['name']}_${Supabase.instance.client.auth.currentUser?.id ?? ''}',
                userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                category: widget.category,
                habitName: habitDef['name']!,
                habitEmoji: habitDef['emoji']!,
                reminderTime: const TimeOfDay(hour: 9, minute: 0),
                startTime: const TimeOfDay(hour: 7, minute: 0),
                endTime: const TimeOfDay(hour: 22, minute: 0),
                frequency: ReminderFrequency.daily,
                selectedDays: const [1, 2, 3, 4, 5, 6, 7],
                enabled: false,
                completedToday: false,
              ),
            );
            return _buildHabitCard(habit);
          }),
      ],
    );
  }

  Widget _buildHabitCard(HabitReminder habit) {
    final isCompleted = habit.completedToday;
    final isExpanded = _expandedHabitId == habit.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedHabitId = isExpanded ? null : habit.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? widget.categoryColor.withAlpha(15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? widget.categoryColor
                : isCompleted
                ? widget.categoryColor.withAlpha(100)
                : Theme.of(context).dividerColor.withAlpha(30),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Emoji
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withAlpha(
                      isCompleted ? 50 : 30,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      habit.habitEmoji,
                      style: TextStyle(
                        fontSize: 20,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.habitName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150)
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 12,
                            color: habit.enabled
                                ? widget.categoryColor
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(100),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(habit.reminderTime),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: habit.enabled
                                  ? widget.categoryColor
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Toggle switch
                Switch(
                  value: habit.enabled,
                  onChanged: (value) => _toggleHabit(habit, value),
                  activeTrackColor: widget.categoryColor.withAlpha(150),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return widget.categoryColor;
                    }
                    return Colors.grey;
                  }),
                ),

                // Expand button
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ],
            ),

            // Expanded content
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Time settings
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSetting(
                      'Reminder Time',
                      habit.reminderTime,
                      Icons.alarm,
                      (time) => _updateReminderTime(habit, time!),
                      null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTimeSetting(
                      'Start Time',
                      habit.startTime,
                      Icons.play_arrow,
                      (time) => _updateStartTime(habit, time),
                      () => _updateStartTime(habit, null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeSetting(
                      'End Time',
                      habit.endTime,
                      Icons.stop,
                      (time) => _updateEndTime(habit, time),
                      () => _updateEndTime(habit, null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Frequency setting
              _buildFrequencySetting(habit),
              const SizedBox(height: 8),

              // Info text
              Text(
                'The reminder uses the exact Reminder Time. Start and end describe your preferred practice window.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySetting(HabitReminder habit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.repeat, size: 14, color: widget.categoryColor),
            const SizedBox(width: 4),
            Text(
              'Frequency',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFrequencyChip(
              'Daily',
              habit.frequency == ReminderFrequency.daily,
              () => _updateFrequency(habit, ReminderFrequency.daily),
            ),
            const SizedBox(width: 8),
            _buildFrequencyChip(
              'Weekly',
              habit.frequency == ReminderFrequency.weekly,
              () => _updateFrequency(habit, ReminderFrequency.weekly),
            ),
          ],
        ),
        if (habit.frequency == ReminderFrequency.weekly) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [1, 2, 3, 4, 5, 6, 7].map((day) {
              final isSelected = habit.selectedDays.contains(day);
              return GestureDetector(
                onTap: () => _toggleDay(habit, day),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.categoryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? widget.categoryColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencyChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.categoryColor.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? widget.categoryColor
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? widget.categoryColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSetting(
    String label,
    TimeOfDay? time,
    IconData icon,
    Function(TimeOfDay?) onTimeChanged,
    VoidCallback? onClear,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: widget.categoryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: widget.categoryColor),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onTimeChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(50),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? _formatTime(time) : 'Not set',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: time != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                if (onClear != null && time != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(100),
                    ),
                  )
                else
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: widget.categoryColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
