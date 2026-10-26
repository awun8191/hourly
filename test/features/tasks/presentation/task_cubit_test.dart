import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/tasks/domain/entities/task.dart';
import 'package:todo_app/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:todo_app/features/tasks/presentation/cubit/task_state.dart';

import '../../../helpers/fake_task_repository.dart';

void main() {
  Task buildTask({
    String id = 'a',
    String title = 'Task A',
    bool isDone = false,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 1, 1),
      isDone: isDone,
      dueDate: dueDate,
    );
  }

  group('load', () {
    blocTest<TaskCubit, TaskState>(
      'emits loading then ready with the stored tasks',
      build: () => TaskCubit(FakeTaskRepository(<Task>[buildTask()])),
      act: (TaskCubit cubit) => cubit.load(),
      expect: () => <Matcher>[
        isA<TaskState>().having((TaskState state) => state.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((TaskState state) => state.status, 'status', TaskStatus.ready)
            .having((TaskState state) => state.tasks.length, 'task count', 1),
      ],
    );

    blocTest<TaskCubit, TaskState>(
      'reports a read failure without crashing',
      build: () => TaskCubit(FakeTaskRepository.failingRead()),
      act: (TaskCubit cubit) => cubit.load(),
      expect: () => <Matcher>[
        isA<TaskState>().having((TaskState state) => state.status, 'status', TaskStatus.loading),
        isA<TaskState>()
            .having((TaskState state) => state.status, 'status', TaskStatus.failure)
            .having((TaskState state) => state.errorMessage, 'error message', isNotNull),
      ],
    );
  });

  group('mutations', () {
    late FakeTaskRepository repository;

    blocTest<TaskCubit, TaskState>(
      'addTask trims the fields, prepends the task, and persists it',
      build: () {
        repository = FakeTaskRepository(<Task>[buildTask(id: 'old', title: 'Old')]);
        return TaskCubit(repository);
      },
      act: (TaskCubit cubit) async {
        await cubit.load();
        await cubit.addTask(title: '  Buy milk  ', notes: '  2 litres  ');
      },
      verify: (TaskCubit cubit) {
        expect(cubit.state.tasks, hasLength(2));
        expect(cubit.state.tasks.first.title, 'Buy milk');
        expect(cubit.state.tasks.first.notes, '2 litres');
        expect(cubit.state.tasks.last.title, 'Old');
        expect(repository.stored.first.title, 'Buy milk');
      },
    );

    blocTest<TaskCubit, TaskState>(
      'addTask rejects a blank title',
      build: () => TaskCubit(FakeTaskRepository()),
      act: (TaskCubit cubit) => cubit.addTask(title: '   '),
      expect: () => const <Matcher>[],
      verify: (TaskCubit cubit) {
        expect(cubit.state.tasks, isEmpty);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'toggleTask flips the completion flag and saves it',
      build: () => TaskCubit(FakeTaskRepository(<Task>[buildTask(id: 'a')])),
      act: (TaskCubit cubit) async {
        await cubit.load();
        await cubit.toggleTask('a');
      },
      verify: (TaskCubit cubit) {
        expect(cubit.state.tasks.single.isDone, isTrue);
        expect(cubit.state.doneCount, 1);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'updateTask replaces the matching task and keeps the rest',
      build: () => TaskCubit(
        FakeTaskRepository(<Task>[buildTask(id: 'a'), buildTask(id: 'b')]),
      ),
      act: (TaskCubit cubit) async {
        await cubit.load();
        await cubit.updateTask(buildTask(id: 'a', title: 'Renamed', isDone: true));
      },
      verify: (TaskCubit cubit) {
        expect(cubit.state.tasks.first.title, 'Renamed');
        expect(cubit.state.tasks.first.isDone, isTrue);
        expect(cubit.state.tasks, hasLength(2));
      },
    );

    blocTest<TaskCubit, TaskState>(
      'clearCompleted removes only done tasks',
      build: () => TaskCubit(
        FakeTaskRepository(<Task>[
          buildTask(id: 'open'),
          buildTask(id: 'done', isDone: true),
        ]),
      ),
      act: (TaskCubit cubit) async {
        await cubit.load();
        await cubit.clearCompleted();
      },
      verify: (TaskCubit cubit) {
        expect(cubit.state.tasks.map((Task task) => task.id), <String>['open']);
        expect(cubit.state.hasCompleted, isFalse);
      },
    );
  });

  group('delete and undo', () {
    test('undo restores the task at its original index', () async {
      final FakeTaskRepository repository = FakeTaskRepository(<Task>[
        buildTask(id: 'a'),
        buildTask(id: 'b'),
        buildTask(id: 'c'),
      ]);
      final TaskCubit cubit = TaskCubit(repository);

      await cubit.load();
      await cubit.deleteTask('b');

      expect(cubit.state.tasks.map((Task task) => task.id), <String>['a', 'c']);
      expect(cubit.state.lastDeleted?.id, 'b');
      expect(cubit.state.lastDeletedIndex, 1);

      await cubit.undoDelete();

      expect(cubit.state.tasks.map((Task task) => task.id), <String>['a', 'b', 'c']);
      expect(cubit.state.lastDeleted, isNull);
      expect(repository.stored.map((Task task) => task.id), <String>['a', 'b', 'c']);
    });

    test('undo without a deleted task does nothing', () async {
      final TaskCubit cubit = TaskCubit(FakeTaskRepository(<Task>[buildTask()]));

      await cubit.load();

      expect(await cubit.undoDelete(), isFalse);
      expect(cubit.state.tasks, hasLength(1));
    });
  });

  group('persistence failures', () {
    test('a failed write restores the previous list and reports the error', () async {
      final FakeTaskRepository repository = FakeTaskRepository(<Task>[buildTask(id: 'a')])
        ..failOnPersist = true;
      final TaskCubit cubit = TaskCubit(repository);

      await cubit.load();
      final bool added = await cubit.addTask(title: 'New task');

      expect(added, isFalse);
      expect(cubit.state.tasks, hasLength(1));
      expect(cubit.state.tasks.single.title, 'Task A');
      expect(cubit.state.status, TaskStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });

  group('filtering and ordering', () {
    test('filters by completion and keeps open tasks first', () async {
      final TaskCubit cubit = TaskCubit(
        FakeTaskRepository(<Task>[
          buildTask(id: 'done', isDone: true),
          buildTask(id: 'open'),
        ]),
      );

      await cubit.load();

      expect(cubit.state.visibleTasks.map((Task task) => task.id), <String>['open', 'done']);

      cubit.setFilter(TaskFilter.active);
      expect(cubit.state.visibleTasks.map((Task task) => task.id), <String>['open']);

      cubit.setFilter(TaskFilter.completed);
      expect(cubit.state.visibleTasks.map((Task task) => task.id), <String>['done']);

      await cubit.close();
    });

    test('orders open tasks by due date, then by creation time', () async {
      final TaskCubit cubit = TaskCubit(
        FakeTaskRepository(<Task>[
          buildTask(id: 'no-date'),
          buildTask(id: 'late', dueDate: DateTime(2026, 3, 10)),
          buildTask(id: 'soon', dueDate: DateTime(2026, 3, 2)),
        ]),
      );

      await cubit.load();

      expect(
        cubit.state.visibleTasks.map((Task task) => task.id),
        <String>['soon', 'late', 'no-date'],
      );

      await cubit.close();
    });

    test('isOverdueAt ignores done tasks and compares dates only', () {
      final Task overdue = buildTask(dueDate: DateTime(2026, 3, 2));
      final Task finished = buildTask(isDone: true, dueDate: DateTime(2026, 3, 2));

      expect(overdue.isOverdueAt(DateTime(2026, 3, 2, 23, 59)), isFalse);
      expect(overdue.isOverdueAt(DateTime(2026, 3, 3, 0, 1)), isTrue);
      expect(finished.isOverdueAt(DateTime(2026, 3, 3, 0, 1)), isFalse);
    });
  });
}
