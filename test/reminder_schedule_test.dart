import 'package:ableritemobile/services/reminder_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location london;

  setUpAll(() {
    tz_data.initializeTimeZones();
    london = tz.getLocation('Europe/London');
  });

  group('daily reminders', () {
    test('uses today when the selected time is still ahead', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 0);

      final result = nextDailyReminderDate(
        time: const TimeOfDay(hour: 10, minute: 30),
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 7, 11, 10, 30));
    });

    test('uses tomorrow when the selected time has passed', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 31);

      final result = nextDailyReminderDate(
        time: const TimeOfDay(hour: 10, minute: 30),
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 7, 12, 10, 30));
    });
  });

  group('reminder identity and normalization', () {
    test('uses a deterministic notification ID', () {
      expect(stableNotificationId('affirmations_reminder_user_0'), 1180758636);
      expect(
        stableNotificationId('affirmations_reminder_user_0'),
        stableNotificationId('affirmations_reminder_user_0'),
      );
      expect(
        stableNotificationId('affirmations_reminder_user_0'),
        isNot(stableNotificationId('affirmations_reminder_user_1')),
      );
    });

    test('removes duplicate wall-clock times while preserving order', () {
      expect(
        normalizeReminderTimes(const [
          TimeOfDay(hour: 9, minute: 0),
          TimeOfDay(hour: 18, minute: 30),
          TimeOfDay(hour: 9, minute: 0),
        ]),
        const [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 18, minute: 30)],
      );
    });
  });

  group('weekly reminders', () {
    test('uses the upcoming selected weekday', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 0); // Saturday

      final result = nextWeeklyReminderDate(
        time: const TimeOfDay(hour: 9, minute: 15),
        weekday: DateTime.monday,
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 7, 13, 9, 15));
    });

    test('uses today when the selected weekday time is still ahead', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 0); // Saturday

      final result = nextWeeklyReminderDate(
        time: const TimeOfDay(hour: 10, minute: 30),
        weekday: DateTime.saturday,
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 7, 11, 10, 30));
    });

    test('uses next week when today\'s selected time has passed', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 31); // Saturday

      final result = nextWeeklyReminderDate(
        time: const TimeOfDay(hour: 10, minute: 30),
        weekday: DateTime.saturday,
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 7, 18, 10, 30));
    });

    test('preserves local time across the spring DST transition', () {
      final now = tz.TZDateTime(london, 2026, 3, 28, 10, 0); // Saturday

      final result = nextWeeklyReminderDate(
        time: const TimeOfDay(hour: 9, minute: 0),
        weekday: DateTime.monday,
        now: now,
      );

      expect(result, tz.TZDateTime(london, 2026, 3, 30, 9, 0));
      expect(result.hour, 9);
    });

    test('normalizes duplicate and invalid selected weekdays', () {
      expect(normalizeWeekdays([7, 1, 1, 0, 8, 3]), [1, 3, 7]);
    });

    test('rejects an invalid weekday', () {
      final now = tz.TZDateTime(london, 2026, 7, 11, 10, 0);

      expect(
        () => nextWeeklyReminderDate(
          time: const TimeOfDay(hour: 9, minute: 0),
          weekday: 8,
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
