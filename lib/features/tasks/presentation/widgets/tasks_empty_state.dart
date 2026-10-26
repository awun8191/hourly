import 'package:flutter/material.dart';

import '../cubit/task_state.dart';

/// Message shown when the current filter has no matching tasks.
class TasksEmptyState extends StatelessWidget {
  const TasksEmptyState({super.key, required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (IconData icon, String title, String message) = switch (filter) {
      TaskFilter.all => (
        Icons.checklist_rounded,
        'No tasks yet',
        'Add your first task to get started.',
      ),
      TaskFilter.active => (
        Icons.task_alt,
        'Nothing left to do',
        'Every task is complete. Add a new one.',
      ),
      TaskFilter.completed => (
        Icons.hourglass_empty,
        'No completed tasks',
        'Finished tasks appear here.',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
