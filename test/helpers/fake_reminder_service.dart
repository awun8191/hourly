import 'package:todo_app/features/schedule/data/reminders/reminder_service.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

/// Records every reschedule instead of touching the notification tray.
class FakeReminderService implements ReminderService {
  final List<({DateTime now, List<HourEntry> entries})> reschedules =
      <({DateTime now, List<HourEntry> entries})>[];

  int cancelCount = 0;
  bool shouldFail = false;

  @override
  Future<void> rescheduleDay({required DateTime now, required List<HourEntry> entries}) async {
    if (shouldFail) {
      throw StateError('reminder reschedule failed');
    }
    reschedules.add((now: now, entries: List<HourEntry>.of(entries)));
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
  }
}
