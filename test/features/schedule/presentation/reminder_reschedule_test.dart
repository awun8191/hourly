import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/data/reminders/notification_response_handler.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';
import 'package:todo_app/features/schedule/presentation/cubit/day_schedule_cubit.dart';

import '../../../helpers/fake_reminder_service.dart';
import '../../../helpers/fake_schedule_repository.dart';
import '../../../helpers/fake_widget_bridge.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 26, 9, 30);
  const String monday = '2026-10-26';

  HourEntry entry(int hour, String text, {HourStatus status = HourStatus.active}) {
    return HourEntry(dateKey: monday, hour: hour, text: text, updatedAt: now, status: status);
  }

  test('load reschedules today with the stored entries', () async {
    final FakeReminderService reminders = FakeReminderService();
    final DayScheduleCubit cubit = DayScheduleCubit(
      FakeScheduleRepository(<String, List<HourEntry>>{
        monday: <HourEntry>[entry(9, 'Standup'), entry(11, 'Review')],
      }),
      FakeWidgetBridge(),
      clock: () => now,
      reminders: reminders,
    );

    await cubit.load();

    expect(reminders.reschedules, hasLength(1));
    expect(reminders.reschedules.single.now, now);
    expect(
      reminders.reschedules.single.entries.map((HourEntry e) => e.hour),
      <int>[9, 11],
    );
    await cubit.close();
  });

  test('save and delete reschedule, so removed hours never notify', () async {
    final FakeReminderService reminders = FakeReminderService();
    final DayScheduleCubit cubit = DayScheduleCubit(
      FakeScheduleRepository(<String, List<HourEntry>>{
        monday: <HourEntry>[entry(11, 'Review')],
      }),
      FakeWidgetBridge(),
      clock: () => now,
      reminders: reminders,
    );
    await cubit.load();
    reminders.reschedules.clear();

    await cubit.saveEntry(14, 'Call');
    expect(
      reminders.reschedules.last.entries.map((HourEntry e) => e.hour),
      <int>[11, 14],
    );

    await cubit.deleteEntry(11);
    expect(
      reminders.reschedules.last.entries.map((HourEntry e) => e.hour),
      <int>[14],
    );
    await cubit.close();
  });

  test('a reminder failure does not fail the save', () async {
    final FakeReminderService reminders = FakeReminderService()..shouldFail = true;
    final FakeWidgetBridge bridge = FakeWidgetBridge();
    final DayScheduleCubit cubit = DayScheduleCubit(
      FakeScheduleRepository(),
      bridge,
      clock: () => now,
      reminders: reminders,
    );
    await cubit.load();

    final bool saved = await cubit.saveEntry(10, 'Call');

    expect(saved, isTrue);
    expect(cubit.state.entries[10]!.text, 'Call');
    expect(bridge.syncs, isNotEmpty);
    await cubit.close();
  });

  test('another day never reschedules reminders', () async {
    final FakeReminderService reminders = FakeReminderService();
    final DayScheduleCubit cubit = DayScheduleCubit(
      FakeScheduleRepository(),
      FakeWidgetBridge(),
      clock: () => now,
      reminders: reminders,
    );

    await cubit.selectDay(DateTime(2026, 10, 27));

    expect(reminders.reschedules, isEmpty);
    await cubit.close();
  });

  test('reminder payloads round-trip and reject junk', () {
    expect(reminderPayload(monday, 9), 'hourly|2026-10-26|9');
    expect(parseReminderPayload('hourly|2026-10-26|9'), ('2026-10-26', 9));
    expect(parseReminderPayload(null), isNull);
    expect(parseReminderPayload('hourly|2026-10-26'), isNull);
    expect(parseReminderPayload('other|2026-10-26|9'), isNull);
    expect(parseReminderPayload('hourly|2026-10-26|99'), isNull);
  });
}
