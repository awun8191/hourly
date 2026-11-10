import '../../domain/entities/hour_entry.dart';

/// Schedules one notification per upcoming hour item.
///
/// The cubit calls [rescheduleDay] alongside the widget sync: on app start
/// and after every edit. The implementation cancels the outstanding items
/// first, so deleted or completed hours never notify.
abstract interface class ReminderService {
  /// Replaces today's outstanding reminders with [entries].
  Future<void> rescheduleDay({required DateTime now, required List<HourEntry> entries});

  /// Drops every outstanding reminder.
  Future<void> cancelAll();
}

/// Builds without plugins. Lets the cubit stay testable and lets
/// non-Android builds skip scheduling entirely.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> rescheduleDay({required DateTime now, required List<HourEntry> entries}) async {}

  @override
  Future<void> cancelAll() async {}
}
