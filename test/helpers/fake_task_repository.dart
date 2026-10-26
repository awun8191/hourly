import 'package:todo_app/features/tasks/domain/entities/task.dart';
import 'package:todo_app/features/tasks/domain/repositories/task_repository.dart';

/// In-memory [TaskRepository] for unit and widget tests.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task> initial = const <Task>[]]) : stored = <Task>[...initial];

  factory FakeTaskRepository.failingRead() => FakeTaskRepository()..failOnRead = true;

  List<Task> stored;
  bool failOnRead = false;
  bool failOnPersist = false;
  int persistCalls = 0;

  @override
  Future<List<Task>> fetchAll() async {
    if (failOnRead) {
      throw const TaskStorageException('read failed');
    }
    return <Task>[...stored];
  }

  @override
  Future<void> persist(List<Task> tasks) async {
    persistCalls++;
    if (failOnPersist) {
      throw const TaskStorageException('write failed');
    }
    stored = <Task>[...tasks];
  }
}
