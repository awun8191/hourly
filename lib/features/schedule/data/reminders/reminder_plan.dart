import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// One notification the service should arm.
class ReminderItem {
  const ReminderItem({
    required this.dateKey,
    required this.hour,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  final String dateKey;
  final int hour;

  /// The hour label, `09:00`.
  final String title;

  /// The item text.
  final String body;

  /// Local time the notification fires: the start of the hour.
  final DateTime fireAt;
}

/// Pure scheduling rules, shared by the Dart service and its tests.
///
/// An entry notifies only when all of these hold:
/// - it belongs to today,
/// - its text is not blank,
/// - it is still active (completed items are done, not due),
/// - its hour has not started yet.
List<ReminderItem> buildReminderPlan({
  required DateTime now,
  required List<HourEntry> entries,
}) {
  final String today = DateKey.of(now);
  final List<ReminderItem> plan = <ReminderItem>[];
  for (final HourEntry entry in entries) {
    if (entry.dateKey != today) {
      continue;
    }
    if (entry.hour < 0 || entry.hour > 23) {
      continue;
    }
    if (entry.text.trim().isEmpty) {
      continue;
    }
    if (entry.status != HourStatus.active) {
      continue;
    }
    final DateTime fireAt = DateTime(now.year, now.month, now.day, entry.hour);
    if (!fireAt.isAfter(now)) {
      continue;
    }
    plan.add(
      ReminderItem(
        dateKey: entry.dateKey,
        hour: entry.hour,
        title: DateKey.hourLabel(entry.hour),
        body: entry.text.trim(),
        fireAt: fireAt,
      ),
    );
  }
  plan.sort((ReminderItem a, ReminderItem b) => a.hour.compareTo(b.hour));
  return plan;
}
