import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_mapper.dart';

/// Stores tasks as one JSON list in [SharedPreferences].
///
/// A to-do list is small, so one document per write keeps the store simple and
/// makes the data easy to inspect on every platform.
class TaskLocalRepository implements TaskRepository {
  TaskLocalRepository(this._preferences);

  final SharedPreferences _preferences;

  static const String storageKey = 'tasks.v1';

  @override
  Future<List<Task>> fetchAll() async {
    final String? raw = _preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <Task>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Task>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskMapper.fromJson)
          .whereType<Task>()
          .toList(growable: false);
    } on FormatException {
      throw const TaskStorageException('The saved task list is not valid JSON.');
    }
  }

  @override
  Future<void> persist(List<Task> tasks) async {
    final String encoded = jsonEncode(
      tasks.map(TaskMapper.toJson).toList(growable: false),
    );
    final bool saved = await _preferences.setString(storageKey, encoded);
    if (!saved) {
      throw const TaskStorageException('The task list could not be saved.');
    }
  }
}
