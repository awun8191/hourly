import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/tasks/presentation/screens/tasks_screen.dart';

/// Composition root of the widget tree.
///
/// The repository is injected, so the local store can be swapped for any other
/// `TaskRepository` without touching the feature code.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.taskRepository});

  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskCubit>(
      create: (BuildContext context) => TaskCubit(taskRepository)..load(),
      child: MaterialApp(
        title: 'Tasks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const TasksScreen(),
      ),
    );
  }
}
