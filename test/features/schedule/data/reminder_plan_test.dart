import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/data/reminders/reminder_plan.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 26, 9, 30);
  const String today = '2026-10-26';

  HourEntry entry(int hour, String text, {HourStatus status = HourStatus.active, String dateKey = today}) {
    return HourEntry(dateKey: dateKey, hour: hour, text: text, updatedAt: now, status: status);
  }

  test('schedules future active hours with hour title and item text', () {
    final List<ReminderItem> plan = buildReminderPlan(
      now: now,
      entries: <HourEntry>[entry(10, 'Call'), entry(14, 'Review')],
    );

    expect(plan.map((ReminderItem item) => item.hour), <int>[10, 14]);
    expect(plan.first.title, '10:00');
    expect(plan.first.body, 'Call');
    expect(plan.first.fireAt, DateTime(2026, 10, 26, 10));
  });

  test('skips the live hour and past hours', () {
    final List<ReminderItem> plan = buildReminderPlan(
      now: now,
      entries: <HourEntry>[entry(8, 'Past'), entry(9, 'Live'), entry(10, 'Next')],
    );

    expect(plan.map((ReminderItem item) => item.hour), <int>[10]);
  });

  test('skips blank text, completed items, and other days', () {
    final List<ReminderItem> plan = buildReminderPlan(
      now: now,
      entries: <HourEntry>[
        entry(10, '   '),
        entry(11, 'Done', status: HourStatus.completed),
        entry(12, 'Tomorrow', dateKey: '2026-10-27'),
        entry(13, 'Later'),
      ],
    );

    expect(plan.map((ReminderItem item) => item.hour), <int>[13]);
  });

  test('returns an empty plan when nothing is due', () {
    expect(buildReminderPlan(now: now, entries: const <HourEntry>[]), isEmpty);
    expect(
      buildReminderPlan(now: now, entries: <HourEntry>[entry(8, 'Past')]),
      isEmpty,
    );
  });

  test('fires at midnight start boundary: hour 0 counts before it starts', () {
    final List<ReminderItem> plan = buildReminderPlan(
      now: DateTime(2026, 10, 26, 0, 0, 1),
      entries: <HourEntry>[entry(0, 'Midnight'), entry(1, 'One')],
    );

    expect(plan.map((ReminderItem item) => item.hour), <int>[1]);
  });
}
