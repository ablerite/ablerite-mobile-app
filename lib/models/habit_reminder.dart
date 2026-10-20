import 'package:flutter/material.dart';

enum HabitCategory { mind, body, spirit }

enum ReminderFrequency { daily, weekly }

class HabitReminder {
  final String id;
  final String userId;
  final HabitCategory category;
  final String habitName;
  final String habitEmoji;
  final TimeOfDay reminderTime;
  final TimeOfDay? startTime; // When reminders become active (e.g., 7am)
  final TimeOfDay? endTime; // When reminders stop (e.g., 10pm)
  final ReminderFrequency frequency;
  final List<int>
  selectedDays; // 1-7 for Monday-Sunday (used when frequency is weekly)
  final bool enabled;
  final bool completedToday;
  final DateTime? lastCompletedDate;

  HabitReminder({
    required this.id,
    required this.userId,
    required this.category,
    required this.habitName,
    required this.habitEmoji,
    required this.reminderTime,
    this.startTime,
    this.endTime,
    this.frequency = ReminderFrequency.daily,
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7], // All days by default
    this.enabled = true,
    this.completedToday = false,
    this.lastCompletedDate,
  });

  HabitReminder copyWith({
    String? id,
    String? userId,
    HabitCategory? category,
    String? habitName,
    String? habitEmoji,
    TimeOfDay? reminderTime,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ReminderFrequency? frequency,
    List<int>? selectedDays,
    bool? enabled,
    bool? completedToday,
    DateTime? lastCompletedDate,
  }) {
    return HabitReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      habitName: habitName ?? this.habitName,
      habitEmoji: habitEmoji ?? this.habitEmoji,
      reminderTime: reminderTime ?? this.reminderTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? this.selectedDays,
      enabled: enabled ?? this.enabled,
      completedToday: completedToday ?? this.completedToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category.name,
      'habit_name': habitName,
      'habit_emoji': habitEmoji,
      'reminder_hour': reminderTime.hour,
      'reminder_minute': reminderTime.minute,
      'start_time_hour': startTime?.hour,
      'start_time_minute': startTime?.minute,
      'end_time_hour': endTime?.hour,
      'end_time_minute': endTime?.minute,
      'frequency': frequency.name,
      'selected_days': selectedDays.join(','),
      'enabled': enabled,
      'completed_today': completedToday,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
    };
  }

  factory HabitReminder.fromJson(Map<String, dynamic> json) {
    List<int> parseSelectedDays(dynamic value) {
      if (value == null) return [1, 2, 3, 4, 5, 6, 7];
      if (value is List) return value.cast<int>();
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => int.tryParse(e) ?? 1).toList();
      }
      return [1, 2, 3, 4, 5, 6, 7];
    }

    return HabitReminder(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      category: HabitCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HabitCategory.mind,
      ),
      habitName: json['habit_name'] ?? '',
      habitEmoji: json['habit_emoji'] ?? '',
      reminderTime: TimeOfDay(
        hour: json['reminder_hour'] ?? 9,
        minute: json['reminder_minute'] ?? 0,
      ),
      startTime: json['start_time_hour'] != null
          ? TimeOfDay(
              hour: json['start_time_hour'],
              minute: json['start_time_minute'] ?? 0,
            )
          : null,
      endTime: json['end_time_hour'] != null
          ? TimeOfDay(
              hour: json['end_time_hour'],
              minute: json['end_time_minute'] ?? 0,
            )
          : null,
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      selectedDays: parseSelectedDays(json['selected_days']),
      enabled: json['enabled'] ?? true,
      completedToday: json['completed_today'] ?? false,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.tryParse(json['last_completed_date'])
          : null,
    );
  }

  bool isWithinActiveWindow() {
    if (startTime == null || endTime == null) return true;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    // Handle overnight windows (e.g., 10pm to 7am)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  bool isScheduledForToday() {
    if (frequency == ReminderFrequency.daily) return true;
    // selectedDays: 1 = Monday, 7 = Sunday
    final today = DateTime.now().weekday;
    return selectedDays.contains(today);
  }
}

// Predefined habits per category
class HabitDefinitions {
  static const List<Map<String, String>> mindHabits = [
    {'name': 'Meditate', 'emoji': '🧘'},
    {'name': 'Think', 'emoji': '💭'},
    {'name': 'Reflect', 'emoji': '🤔'},
  ];

  static const List<Map<String, String>> bodyHabits = [
    {'name': 'Exercise', 'emoji': '🏃'},
    {'name': 'Walk', 'emoji': '🚶'},
    {'name': 'Gym', 'emoji': '💪'},
  ];

  static const List<Map<String, String>> spiritHabits = [
    {'name': 'Pray', 'emoji': '🙏'},
    {'name': 'Worship', 'emoji': '✨'},
    {'name': 'Tithe', 'emoji': '💝'},
  ];

  static List<Map<String, String>> getHabitsForCategory(
    HabitCategory category,
  ) {
    switch (category) {
      case HabitCategory.mind:
        return mindHabits;
      case HabitCategory.body:
        return bodyHabits;
      case HabitCategory.spirit:
        return spiritHabits;
    }
  }
}

// Day names for display
const Map<int, String> dayNames = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

const Map<int, String> dayNamesFull = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};
