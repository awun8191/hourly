import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/features/schedule/data/repositories/schedule_local_repository.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';
import 'package:todo_app/features/schedule/domain/repositories/schedule_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String monday = '2026-10-26';
  const String tuesday = '2026-10-27';

  late SharedPreferences preferences;
  late ScheduleLocalRepository repository;

  HourEntry buildEntry({
    String dateKey = monday,
    int hour = 9,
    String text = 'Standup',
    HourStatus status = HourStatus.active,
  }) {
    return HourEntry(
      dateKey: dateKey,
      hour: hour,
      text: text,
      status: status,
      updatedAt: DateTime(2026, 10, 26, 9, 5),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = ScheduleLocalRepository(preferences);
  });

  test('returns an empty list for an empty day', () async {
    expect(await repository.fetchDay(monday), isEmpty);
  });

  test('saves and reads an entry for its hour', () async {
    await repository.upsert(buildEntry(hour: 9, text: 'Standup'));
    await repository.upsert(buildEntry(hour: 7, text: 'Gym', status: HourStatus.completed));

    final List<HourEntry> entries = await repository.fetchDay(monday);

    expect(entries.map((HourEntry entry) => entry.hour), <int>[7, 9]);
    expect(entries.first.text, 'Gym');
    expect(entries.first.isCompleted, isTrue);
    expect(entries.last.text, 'Standup');
    expect(entries.last.isCompleted, isFalse);
  });

  test('replaces the entry in the same hour', () async {
    await repository.upsert(buildEntry(hour: 9, text: 'Standup'));
    await repository.upsert(buildEntry(hour: 9, text: 'Review'));

    final List<HourEntry> entries = await repository.fetchDay(monday);

    expect(entries, hasLength(1));
    expect(entries.single.text, 'Review');
  });

  test('keeps days apart', () async {
    await repository.upsert(buildEntry(hour: 9, text: 'Monday standup'));

    expect(await repository.fetchDay(tuesday), isEmpty);

    await repository.upsert(buildEntry(dateKey: tuesday, hour: 9, text: 'Tuesday standup'));

    expect((await repository.fetchDay(monday)).single.text, 'Monday standup');
    expect((await repository.fetchDay(tuesday)).single.text, 'Tuesday standup');
  });

  test('delete removes the hour and then the whole day document', () async {
    await repository.upsert(buildEntry(hour: 9));

    await repository.delete(monday, 9);

    expect(await repository.fetchDay(monday), isEmpty);
    expect(preferences.getString(ScheduleLocalRepository.keyFor(monday)), isNull);
  });

  test('delete of a missing hour does nothing', () async {
    await repository.delete(monday, 12);

    expect(await repository.fetchDay(monday), isEmpty);
  });

  test('skips a bad hour key and a blank text', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ScheduleLocalRepository.keyFor(monday): jsonEncode(<String, Object?>{
        '9': <String, Object?>{'text': 'Good', 'status': 'active'},
        '99': <String, Object?>{'text': 'Bad hour', 'status': 'active'},
        'x': <String, Object?>{'text': 'Bad key', 'status': 'active'},
        '10': <String, Object?>{'text': '   ', 'status': 'active'},
      }),
    });
    final SharedPreferences fresh = await SharedPreferences.getInstance();

    final List<HourEntry> entries = await ScheduleLocalRepository(fresh).fetchDay(monday);

    expect(entries.map((HourEntry entry) => entry.text), <String>['Good']);
  });

  test('throws ScheduleStorageException on invalid JSON', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ScheduleLocalRepository.keyFor(monday): 'not json',
    });
    final SharedPreferences fresh = await SharedPreferences.getInstance();

    expect(
      ScheduleLocalRepository(fresh).fetchDay(monday),
      throwsA(isA<ScheduleStorageException>()),
    );
  });

  test('a failed upsert reports the failure', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ScheduleLocalRepository.keyFor(monday): 'not json',
    });
    final SharedPreferences fresh = await SharedPreferences.getInstance();

    expect(
      ScheduleLocalRepository(fresh).upsert(buildEntry()),
      throwsA(isA<ScheduleStorageException>()),
    );
  });
}
