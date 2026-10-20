import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

int stableNotificationId(String value) {
  // FNV-1a gives the OS request a deterministic 31-bit ID. Dart's
  // String.hashCode is not guaranteed to stay the same between app runs,
  // which means a reminder scheduled by an older process may not be
  // cancellable by a newer one.
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

List<TimeOfDay> normalizeReminderTimes(Iterable<TimeOfDay> times) {
  final seenMinutes = <int>{};
  return times.where((time) {
    final minutes = time.hour * 60 + time.minute;
    return seenMinutes.add(minutes);
  }).toList();
}

List<int> normalizeWeekdays(Iterable<int> weekdays) {
  final result =
      weekdays
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .toSet()
          .toList()
        ..sort();
  return result;
}

tz.TZDateTime nextDailyReminderDate({
  required TimeOfDay time,
  required tz.TZDateTime now,
}) {
  var scheduledDate = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  if (!scheduledDate.isAfter(now)) {
    scheduledDate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      time.hour,
      time.minute,
    );
  }

  return scheduledDate;
}

tz.TZDateTime nextWeeklyReminderDate({
  required TimeOfDay time,
  required int weekday,
  required tz.TZDateTime now,
}) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw ArgumentError.value(weekday, 'weekday', 'Must be between 1 and 7');
  }

  var daysAhead = (weekday - now.weekday + 7) % 7;
  var scheduledDate = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + daysAhead,
    time.hour,
    time.minute,
  );

  if (!scheduledDate.isAfter(now)) {
    daysAhead += 7;
    scheduledDate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + daysAhead,
      time.hour,
      time.minute,
    );
  }

  return scheduledDate;
}
