import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/habit_reminder.dart';
import 'reminder_schedule.dart';

import 'package:flutter_timezone/flutter_timezone.dart';

const String notificationChannelId = 'habit_reminders';
const String notificationChannelName = 'Habit Reminders';
const String notificationChannelDescription =
    'Daily habit reminder notifications';
const String sessionTimerChannelId = 'session_timer_alarms_v2';
const String sessionTimerChannelName = 'Session Timer Alarms';
const String sessionTimerChannelDescription =
    'Alerts when a wellbeing session timer finishes';
const String sessionTimerAlarmSoundName = 'session_alarm';
const String sessionTimerAlarmSoundAsset = 'assets/sounds/session_alarm.wav';
const String workManagerTaskName = 'habitReminderTask';
const int _sessionTimerAlarmRepeatCount = 6;
const Duration _sessionTimerAlarmRepeatInterval = Duration(seconds: 10);

String _notificationHabitName(String habitName) {
  return habitName == 'Pray' ? 'Prayer' : habitName;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Future<void>? _initializationFuture;
  Future<void> _notificationOperations = Future<void>.value();

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    return _initializationFuture ??= _initialize();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelName,
          channelDescription: notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _initialize() async {
    try {
      await _initializePlugin();
      _isInitialized = true;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      await _refreshLocalTimezone();
    } catch (e) {
      debugPrint('Could not initialize local timezone: $e');
    }

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions on Android (notification posting + exact alarms,
    // both required at runtime on API 31+/33+ or zonedSchedule throws)
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // Register workmanager background task (Android only — not supported on iOS)
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        workManagerTaskName,
        workManagerTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    }
  }

  Future<void> _refreshLocalTimezone() async {
    final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _enqueueNotificationOperation(
    Future<void> Function() operation,
  ) {
    final nextOperation = _notificationOperations.then((_) => operation());
    _notificationOperations = nextOperation.catchError((Object error) {
      // Keep the queue usable after surfacing the error to this operation's
      // caller. Otherwise one failed permission request would poison every
      // later reminder update for the rest of the app session.
    });
    return nextOperation;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    const sessionTimerPayloadPrefix = 'session_timer:';
    final payload = response.payload;
    if (payload != null && payload.startsWith(sessionTimerPayloadPrefix)) {
      final timerId = payload.substring(sessionTimerPayloadPrefix.length);
      if (timerId.isNotEmpty) {
        cancelSessionTimerAlarm(timerId);
      }
    }
  }

  int _sessionTimerNotificationId(String timerId, int index) =>
      stableNotificationId('session_timer_${timerId}_$index');

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExactly = await androidPlugin
        ?.canScheduleExactNotifications();

    // Android 14 no longer grants exact-alarm access by default for many new
    // installs. A wellness reminder should still be delivered if the user
    // declines that optional access, even if Android batches it slightly.
    return canScheduleExactly == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> scheduleHabitReminder(HabitReminder habit) {
    return _enqueueNotificationOperation(() => _scheduleHabitReminder(habit));
  }

  Future<void> replaceHabitReminders({
    required String payloadPrefix,
    required List<HabitReminder> reminders,
  }) {
    return _enqueueNotificationOperation(() async {
      await initialize();

      // Clean up by payload rather than only by calculated ID. This removes
      // orphaned requests created by versions that used non-durable IDs.
      final pendingRequests = await _notifications
          .pendingNotificationRequests();
      for (final request in pendingRequests) {
        if (request.payload?.startsWith(payloadPrefix) == true) {
          await _notifications.cancel(request.id);
        }
      }

      // Keeping replacement in one queued operation prevents two rapid
      // settings edits from interleaving their cancel/schedule passes.
      for (final reminder in reminders) {
        await _scheduleHabitReminder(reminder);
      }
    });
  }

  Future<void> scheduleSessionTimerAlarm({
    required String timerId,
    required DateTime endsAt,
    required String label,
  }) {
    return _enqueueNotificationOperation(() async {
      await initialize();
      await _ensureNotificationsAreEnabled();

      final scheduledAt = tz.TZDateTime.from(endsAt, tz.local);
      if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) return;

      for (var index = 0; index < _sessionTimerAlarmRepeatCount; index++) {
        await _notifications.cancel(
          _sessionTimerNotificationId(timerId, index),
        );
      }

      final androidScheduleMode = await _androidScheduleMode();
      // Android supports FLAG_INSISTENT, so one alarm can repeat until the
      // notification is tapped. iOS notification sounds cannot loop, so use
      // six time-sensitive alerts ten seconds apart for the same one-minute
      // alarm window.
      final scheduleCount = Platform.isIOS ? _sessionTimerAlarmRepeatCount : 1;
      for (var index = 0; index < scheduleCount; index++) {
        final alertTime = scheduledAt.add(
          _sessionTimerAlarmRepeatInterval * index,
        );
        await _notifications.zonedSchedule(
          _sessionTimerNotificationId(timerId, index),
          'Session complete',
          'Your $label session has finished. Tap to stop the alarm.',
          alertTime,
          NotificationDetails(
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: true,
              sound: '$sessionTimerAlarmSoundName.wav',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
            android: AndroidNotificationDetails(
              sessionTimerChannelId,
              sessionTimerChannelName,
              channelDescription: sessionTimerChannelDescription,
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound(
                sessionTimerAlarmSoundName,
              ),
              icon: '@mipmap/ic_launcher',
              autoCancel: false,
              ongoing: true,
              timeoutAfter: const Duration(minutes: 1).inMilliseconds,
              additionalFlags: Int32List.fromList(const [4]),
            ),
          ),
          androidScheduleMode: androidScheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'session_timer:$timerId',
        );
      }
    });
  }

  Future<void> cancelSessionTimerAlarm(String timerId) {
    return _enqueueNotificationOperation(() async {
      await initialize();
      for (var index = 0; index < _sessionTimerAlarmRepeatCount; index++) {
        await _notifications.cancel(
          _sessionTimerNotificationId(timerId, index),
        );
      }
    });
  }

  Future<void> _scheduleHabitReminder(HabitReminder habit) async {
    // Callers (e.g. the Wellness habit tracker) may fire this before their
    // own initState's fire-and-forget initialize() call has completed —
    // initialize() itself is idempotent (early-returns if already done), so
    // calling it here guarantees the plugin is ready regardless of caller
    // ordering instead of silently failing to schedule.
    await initialize();

    if (!habit.enabled) {
      await _cancelHabitReminder(habit.id);
      return;
    }

    // The device timezone can change while the app remains alive. Refresh it
    // for every schedule operation so a selected wall-clock time is not
    // interpreted using the zone captured at app startup.
    await _refreshLocalTimezone();
    await _ensureNotificationsAreEnabled();

    // For weekly frequency with selected days, cancel existing and schedule per-day
    if (habit.frequency == ReminderFrequency.weekly) {
      await _scheduleWeeklyReminder(habit);
      return;
    }

    // Daily frequency
    // Clear both the old daily ID and any per-weekday IDs first. Without this,
    // changing a reminder from weekly back to daily leaves the weekly alarms
    // active alongside the new daily reminder.
    await _cancelHabitReminder(habit.id);
    final notificationId = stableNotificationId(habit.id);
    final androidScheduleMode = await _androidScheduleMode();

    await _notifications.zonedSchedule(
      notificationId,
      'Habit Reminder',
      '${habit.habitEmoji} Time for ${_notificationHabitName(habit.habitName)}!',
      nextDailyReminderDate(
        time: habit.reminderTime,
        now: tz.TZDateTime.now(tz.local),
      ),
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelName,
          channelDescription: notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: habit.id,
    );
  }

  Future<void> reconcileWellnessReminders(String userId) {
    return _enqueueNotificationOperation(
      () => _reconcileWellnessReminders(userId),
    );
  }

  Future<void> _reconcileWellnessReminders(String userId) async {
    await initialize();

    // Remove every saved Wellness request using the notification IDs that
    // Android currently knows about. This also cleans up stale requests from
    // older builds and signed-out users before rebuilding the active set.
    final pendingRequests = await _notifications.pendingNotificationRequests();
    for (final request in pendingRequests) {
      final payload = request.payload;
      final isWellnessReminder =
          payload?.startsWith('mind_') == true ||
          payload?.startsWith('body_') == true ||
          payload?.startsWith('spirit_') == true;
      if (isWellnessReminder) {
        await _notifications.cancel(request.id);
      }
    }

    // Read storage after cleanup. The Wellness hub starts this pass without
    // blocking navigation, so the user may enable Think (or another habit)
    // while pending requests are being removed. Reading before cleanup used
    // to restore the stale disabled state and cancel the new reminder.
    final habits = await loadHabitsFromStorage();
    final enabledHabits = habits
        .where((habit) => habit.userId == userId && habit.enabled)
        .toList();

    for (final habit in enabledHabits) {
      await _scheduleHabitReminder(habit);
    }
  }

  Future<void> _scheduleWeeklyReminder(HabitReminder habit) async {
    // Cancel existing notifications first
    await _cancelHabitReminder(habit.id);

    final androidScheduleMode = await _androidScheduleMode();
    final selectedDays = normalizeWeekdays(habit.selectedDays);

    if (selectedDays.isEmpty) {
      debugPrint('Weekly reminder ${habit.id} has no valid selected days');
      return;
    }

    // Schedule for each selected day
    for (final day in selectedDays) {
      final notificationId = stableNotificationId('${habit.id}_$day');

      await _notifications.zonedSchedule(
        notificationId,
        'Habit Reminder',
        '${habit.habitEmoji} Time for ${_notificationHabitName(habit.habitName)}!',
        nextWeeklyReminderDate(
          time: habit.reminderTime,
          weekday: day,
          now: tz.TZDateTime.now(tz.local),
        ),
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            channelDescription: notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );
    }
  }

  Future<void> _ensureNotificationsAreEnabled() async {
    if (Platform.isIOS) {
      final permissions = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (permissions?.isEnabled == false) {
        throw StateError(
          'Notifications are disabled. Enable them in iPhone Settings to set this reminder.',
        );
      }
    }

    if (Platform.isAndroid) {
      final enabled = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (enabled == false) {
        throw StateError(
          'Notifications are disabled. Enable them in Android Settings to set this reminder.',
        );
      }
    }
  }

  Future<void> cancelHabitReminder(String habitId) {
    return _enqueueNotificationOperation(() async {
      await initialize();
      await _cancelHabitReminder(habitId);
    });
  }

  Future<void> _cancelHabitReminder(String habitId) async {
    // Payload survives across app processes, so it is also the migration path
    // for requests made by older versions with a different calculated ID.
    final pendingRequests = await _notifications.pendingNotificationRequests();
    for (final request in pendingRequests) {
      if (request.payload == habitId) {
        await _notifications.cancel(request.id);
      }
    }

    // Cancel main (daily) notification
    await _notifications.cancel(stableNotificationId(habitId));

    // Cancel weekly notifications (per-day)
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(stableNotificationId('${habitId}_$day'));
    }
  }

  Future<void> cancelAllReminders() {
    return _enqueueNotificationOperation(() async {
      await initialize();
      await _notifications.cancelAll();
    });
  }
}

// Helper to save habits to local storage
Future<void> saveHabitsToStorage(List<HabitReminder> habits) async {
  final prefs = await SharedPreferences.getInstance();
  final habitsJson = jsonEncode(habits.map((h) => h.toJson()).toList());
  await prefs.setString('habit_reminders', habitsJson);
}

Future<List<HabitReminder>> loadHabitsFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final habitsJson = prefs.getString('habit_reminders');

  if (habitsJson == null) return [];

  final List<dynamic> habitsList = jsonDecode(habitsJson);
  return habitsList.map((h) => HabitReminder.fromJson(h)).toList();
}

// Initialize default habits for a user
Future<List<HabitReminder>> initializeDefaultHabits(String userId) async {
  final existingHabits = await loadHabitsFromStorage();

  // Check if user already has habits
  if (existingHabits.any((h) => h.userId == userId)) {
    return existingHabits;
  }

  // Create default habits for all categories
  final List<HabitReminder> defaultHabits = [];

  for (final habitDef in HabitDefinitions.mindHabits) {
    defaultHabits.add(
      HabitReminder(
        id: 'mind_${habitDef['name']}_$userId',
        userId: userId,
        category: HabitCategory.mind,
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
  }

  for (final habitDef in HabitDefinitions.bodyHabits) {
    defaultHabits.add(
      HabitReminder(
        id: 'body_${habitDef['name']}_$userId',
        userId: userId,
        category: HabitCategory.body,
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
  }

  for (final habitDef in HabitDefinitions.spiritHabits) {
    defaultHabits.add(
      HabitReminder(
        id: 'spirit_${habitDef['name']}_$userId',
        userId: userId,
        category: HabitCategory.spirit,
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
  }

  await saveHabitsToStorage(defaultHabits);
  return defaultHabits;
}

// Check and reset completedToday if it's a new day
Future<List<HabitReminder>> refreshHabitsForNewDay(
  List<HabitReminder> habits,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  bool needsSave = false;
  final updatedHabits = habits.map((habit) {
    if (habit.lastCompletedDate != null) {
      final lastCompleted = DateTime(
        habit.lastCompletedDate!.year,
        habit.lastCompletedDate!.month,
        habit.lastCompletedDate!.day,
      );
      if (lastCompleted.isBefore(today)) {
        needsSave = true;
        return habit.copyWith(completedToday: false);
      }
    }
    return habit;
  }).toList();

  if (needsSave) {
    await saveHabitsToStorage(updatedHabits);
  }

  return updatedHabits;
}
