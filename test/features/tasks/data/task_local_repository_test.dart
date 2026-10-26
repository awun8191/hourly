import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo_app/features/tasks/domain/entities/task.dart';
import 'package:todo_app/features/tasks/domain/repositories/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late TaskLocalRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = TaskLocalRepository(preferences);
  });

  test('returns an empty list when nothing is stored', () async {
    expect(await repository.fetchAll(), isEmpty);
  });

  test('round-trips a task with notes, completion, and a due date', () async {
    final Task task = Task(
      id: 't1',
      title: 'Pay rent',
      notes: 'Before noon',
      isDone: true,
      createdAt: DateTime.utc(2026, 1, 2, 3, 4),
      dueDate: DateTime(2026, 1, 5),
    );

    await repository.persist(<Task>[task]);
    final List<Task> loaded = await repository.fetchAll();

    expect(loaded, hasLength(1));
    expect(loaded.single, task);
  });

  test('skips records without a usable id or title', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tasks.v1': jsonEncode(<Object>[
        <String, Object>{
          'id': 'ok',
          'title': 'Valid',
          'isDone': false,
          'createdAt': '2026-01-01T00:00:00.000',
        },
        <String, Object>{'title': 'No id'},
        <String, Object>{'id': 'no-title'},
        'not a map',
      ]),
    });
    final SharedPreferences freshPreferences = await SharedPreferences.getInstance();
    final TaskLocalRepository freshRepository = TaskLocalRepository(freshPreferences);

    final List<Task> loaded = await freshRepository.fetchAll();

    expect(loaded.map((Task task) => task.title), <String>['Valid']);
  });

  test('throws TaskStorageException when the payload is not JSON', () {
    SharedPreferences.setMockInitialValues(<String, Object>{'tasks.v1': 'not json'});

    return SharedPreferences.getInstance().then((SharedPreferences prefs) {
      final TaskLocalRepository broken = TaskLocalRepository(prefs);
      expect(broken.fetchAll(), throwsA(isA<TaskStorageException>()));
    });
  });

  test('persist writes a JSON list under the storage key', () async {
    await repository.persist(<Task>[
      Task(id: 'a', title: 'A', createdAt: DateTime.utc(2026, 5, 1)),
    ]);

    final String? raw = preferences.getString(TaskLocalRepository.storageKey);

    expect(raw, isNotNull);
    final List<dynamic> decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded.single, containsPair('title', 'A'));
  });
}
