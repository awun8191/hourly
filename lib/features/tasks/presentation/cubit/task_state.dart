import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';

enum TaskStatus { initial, loading, ready, failure }

enum TaskFilter {
  all,
  active,
  completed;

  String get label => switch (this) {
    TaskFilter.all => 'All',
    TaskFilter.active => 'Active',
    TaskFilter.completed => 'Done',
  };
}

/// Immutable view state for the task list.
class TaskState extends Equatable {
  const TaskState({
    this.tasks = const <Task>[],
    this.filter = TaskFilter.all,
    this.status = TaskStatus.initial,
    this.errorMessage,
    this.lastDeleted,
    this.lastDeletedIndex,
  });

  final List<Task> tasks;
  final TaskFilter filter;
  final TaskStatus status;

  /// Set when a storage operation fails. The UI shows it once.
  final String? errorMessage;

  /// Most recent deleted task, kept for the undo action.
  final Task? lastDeleted;
  final int? lastDeletedIndex;

  /// Tasks that match the active filter, open tasks first, then by due date.
  List<Task> get visibleTasks {
    final List<Task> filtered = tasks.where((Task task) {
      return switch (filter) {
        TaskFilter.all => true,
        TaskFilter.active => !task.isDone,
        TaskFilter.completed => task.isDone,
      };
    }).toList();
    filtered.sort(_compare);
    return List<Task>.unmodifiable(filtered);
  }

  static int _compare(Task a, Task b) {
    if (a.isDone != b.isDone) {
      return a.isDone ? 1 : -1;
    }
    final DateTime? aDue = a.dueDate;
    final DateTime? bDue = b.dueDate;
    if (aDue != null && bDue != null && aDue != bDue) {
      return aDue.compareTo(bDue);
    }
    if (aDue != null && bDue == null) {
      return -1;
    }
    if (aDue == null && bDue != null) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  int get doneCount => tasks.where((Task task) => task.isDone).length;

  int get activeCount => tasks.length - doneCount;

  bool get isEmpty => tasks.isEmpty;

  bool get hasCompleted => doneCount > 0;

  double get progress => tasks.isEmpty ? 0 : doneCount / tasks.length;

  TaskState copyWith({
    List<Task>? tasks,
    TaskFilter? filter,
    TaskStatus? status,
    String? errorMessage,
    bool clearError = false,
    Task? lastDeleted,
    int? lastDeletedIndex,
    bool clearDeleted = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDeleted: clearDeleted ? null : (lastDeleted ?? this.lastDeleted),
      lastDeletedIndex: clearDeleted ? null : (lastDeletedIndex ?? this.lastDeletedIndex),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    tasks,
    filter,
    status,
    errorMessage,
    lastDeleted,
    lastDeletedIndex,
  ];
}
