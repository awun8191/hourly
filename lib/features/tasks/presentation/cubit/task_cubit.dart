import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_state.dart';

/// Owns the task list, applies the mutations, and writes through the repository.
class TaskCubit extends Cubit<TaskState> {
  TaskCubit(this._repository) : super(const TaskState());

  final TaskRepository _repository;

  static const Uuid _uuid = Uuid();
  static const String _readError = 'The saved tasks could not be loaded.';
  static const String _writeError = 'The change could not be saved.';

  Future<void> load() async {
    emit(state.copyWith(status: TaskStatus.loading, clearError: true));
    try {
      final List<Task> tasks = await _repository.fetchAll();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          tasks: List<Task>.unmodifiable(tasks),
          status: TaskStatus.ready,
          clearError: true,
        ),
      );
    } on Object {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: _readError));
    }
  }

  void setFilter(TaskFilter filter) {
    emit(state.copyWith(filter: filter, clearError: true));
  }

  Future<bool> addTask({
    required String title,
    String notes = '',
    DateTime? dueDate,
  }) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future<bool>.value(false);
    }
    final Task task = Task(
      id: _uuid.v4(),
      title: trimmed,
      notes: notes.trim(),
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    return _commit(<Task>[task, ...state.tasks], clearDeleted: true);
  }

  Future<bool> updateTask(Task updated) {
    if (!state.tasks.any((Task task) => task.id == updated.id)) {
      return Future<bool>.value(false);
    }
    final List<Task> next = state.tasks
        .map((Task task) => task.id == updated.id ? updated : task)
        .toList();
    return _commit(next, clearDeleted: true);
  }

  Future<bool> toggleTask(String id) {
    final List<Task> next = state.tasks
        .map((Task task) => task.id == id ? task.copyWith(isDone: !task.isDone) : task)
        .toList();
    return _commit(next, clearDeleted: true);
  }

  Future<bool> deleteTask(String id) async {
    final int index = state.tasks.indexWhere((Task task) => task.id == id);
    if (index < 0) {
      return false;
    }
    final Task removed = state.tasks[index];
    final List<Task> next = <Task>[...state.tasks]..removeAt(index);
    return _commit(
      next,
      deleted: removed,
      deletedIndex: index,
    );
  }

  Future<bool> undoDelete() {
    final Task? removed = state.lastDeleted;
    if (removed == null) {
      return Future<bool>.value(false);
    }
    final List<Task> next = <Task>[...state.tasks];
    final int index = (state.lastDeletedIndex ?? next.length).clamp(0, next.length).toInt();
    next.insert(index, removed);
    return _commit(next, clearDeleted: true);
  }

  Future<bool> clearCompleted() {
    final List<Task> next = state.tasks.where((Task task) => !task.isDone).toList();
    if (next.length == state.tasks.length) {
      return Future<bool>.value(true);
    }
    return _commit(next, clearDeleted: true);
  }

  /// Applies [next] to the state first, then writes it. A failed write restores
  /// the previous state and reports the error.
  Future<bool> _commit(
    List<Task> next, {
    Task? deleted,
    int? deletedIndex,
    bool clearDeleted = false,
  }) async {
    final TaskState previous = state;
    emit(
      state.copyWith(
        tasks: List<Task>.unmodifiable(next),
        status: TaskStatus.ready,
        clearError: true,
        lastDeleted: deleted,
        lastDeletedIndex: deletedIndex,
        clearDeleted: clearDeleted && deleted == null,
      ),
    );
    try {
      await _repository.persist(next);
    } on Object {
      if (isClosed) {
        return false;
      }
      emit(previous.copyWith(status: TaskStatus.failure, errorMessage: _writeError));
      return false;
    }
    if (isClosed) {
      return false;
    }
    return true;
  }
}
