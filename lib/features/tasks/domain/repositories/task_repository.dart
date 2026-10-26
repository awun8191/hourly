import '../entities/task.dart';

/// Boundary between the task feature and its storage.
///
/// The app talks to this interface only, so the local store can be replaced
/// in one line of the composition root (see `main.dart`).
abstract interface class TaskRepository {
  /// Returns every stored task. Returns an empty list when nothing is stored.
  Future<List<Task>> fetchAll();

  /// Replaces the stored task list with [tasks].
  ///
  /// Throws a `TaskStorageException` when the write fails.
  Future<void> persist(List<Task> tasks);
}

/// Raised when the task store cannot be read or written.
class TaskStorageException implements Exception {
  const TaskStorageException(this.message);

  final String message;

  @override
  String toString() => 'TaskStorageException: $message';
}
