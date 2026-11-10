import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../widget/home_widget_bridge.dart';
import '../widget/widget_window.dart';

/// Action id of the notification's "Mark done" button.
const String markDoneActionId = 'mark_done';

/// Payload shape: `hourly|<dateKey>|<hour>`.
String reminderPayload(String dateKey, int hour) => 'hourly|$dateKey|$hour';

/// Runs on a background isolate when the "Mark done" button is tapped.
///
/// Same pattern as the widget toggle callback: flip the hour to completed in
/// the shared store, then repaint the widget. A tap on the notification body
/// (not the button) opens the app instead and arrives with a null action id,
/// which this handler ignores.
@pragma('vm:entry-point')
Future<void> handleNotificationAction(NotificationResponse response) async {
  if (response.actionId != markDoneActionId) {
    return;
  }
  final (String, int)? target = parseReminderPayload(response.payload);
  if (target == null) {
    return;
  }
  await markHourDone(target.$1, target.$2);
}

/// Visible for testing. Returns null when the payload is not a reminder.
(String, int)? parseReminderPayload(String? payload) {
  if (payload == null) {
    return null;
  }
  final List<String> parts = payload.split('|');
  if (parts.length != 3 || parts[0] != 'hourly' || parts[1].isEmpty) {
    return null;
  }
  final int? hour = int.tryParse(parts[2]);
  if (hour == null || hour < 0 || hour > 23) {
    return null;
  }
  return (parts[1], hour);
}

Future<void> markHourDone(String dateKey, int hour) async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final ScheduleRepository repository = ScheduleLocalRepository(preferences);
  final DateTime now = DateTime.now();

  final List<HourEntry> entries = await repository.fetchDay(dateKey);
  HourEntry? found;
  for (final HourEntry entry in entries) {
    if (entry.hour == hour) {
      found = entry;
      break;
    }
  }
  if (found == null || found.isCompleted) {
    return;
  }
  await repository.upsert(
    found.copyWith(status: HourStatus.completed, updatedAt: now),
  );
  await HomeWidgetBridge().sync(
    now: now,
    entries: await WidgetWindow.collect(repository, now),
  );
}
