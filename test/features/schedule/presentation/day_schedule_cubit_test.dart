import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';
import 'package:todo_app/features/schedule/presentation/cubit/day_schedule_cubit.dart';
import 'package:todo_app/features/schedule/presentation/cubit/day_schedule_state.dart';

import '../../../helpers/fake_schedule_repository.dart';
import '../../../helpers/fake_widget_bridge.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 26, 9, 30);
  const String monday = '2026-10-26';
  const String tuesday = '2026-10-27';

  HourEntry entry(
    int hour,
    String text, {
    String dateKey = monday,
    HourStatus status = HourStatus.active,
  }) {
    return HourEntry(
      dateKey: dateKey,
      hour: hour,
      text: text,
      status: status,
      updatedAt: now,
    );
  }

  Future<DayScheduleCubit> build({
    FakeScheduleRepository? repository,
    FakeWidgetBridge? bridge,
  }) async {
    final DayScheduleCubit cubit = DayScheduleCubit(
      repository ?? FakeScheduleRepository(),
      bridge ?? FakeWidgetBridge(),
      clock: () => now,
    );
    await cubit.load();
    return cubit;
  }

  test('load fills the day and sorts by hour', () async {
    final DayScheduleCubit cubit = await build(
      repository: FakeScheduleRepository(<String, List<HourEntry>>{
        monday: <HourEntry>[entry(11, 'Review'), entry(9, 'Standup')],
      }),
    );

    expect(cubit.state.status, ScheduleStatus.ready);
    expect(cubit.state.entries.keys, <int>[9, 11]);
    expect(cubit.state.filledCount, 2);
    expect(cubit.state.doneCount, 0);
  });

  test('a read failure reports the error', () async {
    final FakeScheduleRepository repository = FakeScheduleRepository()..failOnRead = true;
    final DayScheduleCubit cubit = DayScheduleCubit(repository, FakeWidgetBridge(), clock: () => now);

    await cubit.load();

    expect(cubit.state.status, ScheduleStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('saveEntry trims the text, starts green, and syncs the widget', () async {
    final FakeWidgetBridge bridge = FakeWidgetBridge();
    final FakeScheduleRepository repository = FakeScheduleRepository();
    final DayScheduleCubit cubit = await build(repository: repository, bridge: bridge);

    final bool saved = await cubit.saveEntry(9, '  Standup  ');

    expect(saved, isTrue);
    expect(cubit.state.entries[9]!.text, 'Standup');
    expect(cubit.state.entries[9]!.isCompleted, isFalse);
    expect(repository.day(monday)[9]!.text, 'Standup');
    expect(bridge.syncs, isNotEmpty);
    expect(bridge.syncs.last.now, now);
    expect(bridge.syncs.last.entries, hasLength(1));
  });

  test('saveEntry with blank text removes the entry', () async {
    final DayScheduleCubit cubit = await build(
      repository: FakeScheduleRepository(<String, List<HourEntry>>{
        monday: <HourEntry>[entry(9, 'Standup')],
      }),
    );

    final bool saved = await cubit.saveEntry(9, '   ');

    expect(saved, isTrue);
    expect(cubit.state.entries, isEmpty);
  });

  test('toggle moves an item from green to red and back', () async {
    final FakeScheduleRepository repository = FakeScheduleRepository(<String, List<HourEntry>>{
      monday: <HourEntry>[entry(9, 'Standup')],
    });
    final DayScheduleCubit cubit = await build(repository: repository);

    await cubit.toggle(9);

    expect(cubit.state.entries[9]!.isCompleted, isTrue);
    expect(cubit.state.doneCount, 1);
    expect(repository.day(monday)[9]!.isCompleted, isTrue);

    await cubit.toggle(9);

    expect(cubit.state.entries[9]!.isCompleted, isFalse);
    expect(cubit.state.doneCount, 0);
  });

  test('deleteEntry removes the hour and saves', () async {
    final FakeScheduleRepository repository = FakeScheduleRepository(<String, List<HourEntry>>{
      monday: <HourEntry>[entry(9, 'Standup'), entry(10, 'Call')],
    });
    final DayScheduleCubit cubit = await build(repository: repository);

    final bool deleted = await cubit.deleteEntry(9);

    expect(deleted, isTrue);
    expect(cubit.state.entries.keys, <int>[10]);
    expect(repository.day(monday).keys, <int>[10]);
  });

  test('a failed write restores the previous state and reports the error', () async {
    final FakeScheduleRepository repository = FakeScheduleRepository(<String, List<HourEntry>>{
      monday: <HourEntry>[entry(9, 'Standup')],
    })
      ..failOnWrite = true;
    final DayScheduleCubit cubit = await build(repository: repository);

    final bool saved = await cubit.saveEntry(10, 'New item');

    expect(saved, isFalse);
    expect(cubit.state.entries.keys, <int>[9]);
    expect(cubit.state.status, ScheduleStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('a failed widget sync does not fail the edit', () async {
    final FakeWidgetBridge bridge = FakeWidgetBridge()..shouldFail = true;
    final DayScheduleCubit cubit = await build(bridge: bridge);

    final bool saved = await cubit.saveEntry(9, 'Standup');

    expect(saved, isTrue);
    expect(cubit.state.entries[9]!.text, 'Standup');
    expect(cubit.state.status, ScheduleStatus.ready);
  });

  test('day navigation loads another day and does not sync the widget', () async {
    final FakeWidgetBridge bridge = FakeWidgetBridge();
    final FakeScheduleRepository repository = FakeScheduleRepository(<String, List<HourEntry>>{
      monday: <HourEntry>[entry(9, 'Monday standup')],
      tuesday: <HourEntry>[entry(9, 'Tuesday standup', dateKey: tuesday)],
    });
    final DayScheduleCubit cubit = await build(repository: repository, bridge: bridge);
    final int syncsBefore = bridge.syncs.length;

    await cubit.shiftDay(1);

    expect(cubit.state.day, DateTime(2026, 10, 27));
    expect(cubit.state.entries[9]!.text, 'Tuesday standup');
    expect(bridge.syncs.length, syncsBefore);

    await cubit.shiftDay(-1);

    expect(cubit.state.entries[9]!.text, 'Monday standup');
  });

  test('currentHourIfToday is null on another day', () async {
    final DayScheduleCubit cubit = await build();

    expect(cubit.currentHourIfToday, 9);

    await cubit.shiftDay(1);

    expect(cubit.currentHourIfToday, isNull);
  });

  test('progress uses the filled hours only', () async {
    final DayScheduleCubit cubit = await build(
      repository: FakeScheduleRepository(<String, List<HourEntry>>{
        monday: <HourEntry>[
          entry(9, 'Done', status: HourStatus.completed),
          entry(10, 'Open'),
          entry(11, 'Done too', status: HourStatus.completed),
        ],
      }),
    );

    expect(cubit.state.progress, closeTo(2 / 3, 0.001));
    expect(cubit.state.isComplete, isFalse);
  });
}
