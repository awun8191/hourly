import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/tasks/data/repositories/task_local_repository.dart';
import 'features/tasks/domain/repositories/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final TaskRepository repository = TaskLocalRepository(preferences);
  runApp(TodoApp(taskRepository: repository));
}
