import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/hour_entry.dart';
import 'notification_response_handler.dart';
import 'reminder_plan.dart';
import 'reminder_service.dart';

/// Schedules today's remaining hour items with the system notification tray.
///
/// One channel, `hourly_reminders`, high importance. The service asks for the
/// runtime notification permission and the exact-alarms permission on
/// initialize; when exact alarms are not granted it falls back to inexact
/// alarms instead of failing. Tapping a notification opens the app; the
/// "Mark done" button completes the hour without opening it.
class LocalReminderService implements ReminderService {
  LocalReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'hourly_reminders';
  static const String channelName = 'Hourly';

  bool _ready = false;

  /// Creates the channel and asks for notification and exact-alarm permission.
  /// Safe to call once at startup; failures never throw.
  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      tz.initializeTimeZones();
      final String identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
      try {
        tz.setLocalLocation(tz.getLocation(identifier));
      } on Object {
        // Unknown zone name: keep the default location.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (_) {},
        onDidReceiveBackgroundNotificationResponse: handleNotificationAction,
      );
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Reminders for each planned hour.',
          importance: Importance.high,
        ),
      );
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      _ready = true;
    } on Object {
      // Reminders stay off; the schedule itself always works.
      _ready = false;
    }
  }

  @override
  Future<void> rescheduleDay({required DateTime now, required List<HourEntry> entries}) async {
    if (defaultTargetPlatform != TargetPlatform.android || !_ready) {
      return;
    }
    try {
      await _plugin.cancelAll();
      final List<ReminderItem> plan = buildReminderPlan(now: now, entries: entries);
      if (plan.isEmpty) {
        return;
      }
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool exact = await android?.canScheduleExactNotifications() ?? false;
      final AndroidScheduleMode mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      for (final ReminderItem item in plan) {
        await _plugin.zonedSchedule(
          id: item.hour,
          title: item.title,
          body: item.body,
          scheduledDate: tz.TZDateTime.from(item.fireAt, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'Reminders for each planned hour.',
              importance: Importance.high,
              priority: Priority.high,
              actions: const <AndroidNotificationAction>[
                AndroidNotificationAction(markDoneActionId, 'Mark done'),
              ],
            ),
          ),
          androidScheduleMode: mode,
          payload: reminderPayload(item.dateKey, item.hour),
        );
      }
    } on Object {
      // A missed reminder must never break the schedule edit.
    }
  }

  @override
  Future<void> cancelAll() async {
    if (defaultTargetPlatform != TargetPlatform.android || !_ready) {
      return;
    }
    try {
      await _plugin.cancelAll();
    } on Object {
      // Ignore. There is nothing for the user to do about it.
    }
  }
}
