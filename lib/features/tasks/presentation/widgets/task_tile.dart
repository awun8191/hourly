import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task.dart';

/// One row in the task list. Swipe left to delete, tap to edit.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool overdue = task.isOverdueAt(DateTime.now());

    return Dismissible(
      key: ValueKey<String>('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (DismissDirection _) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: task.isDone,
                  onChanged: (bool? _) => onToggle(),
                  semanticLabel: task.isDone
                      ? 'Mark ${task.title} as not done'
                      : 'Mark ${task.title} as done',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? scheme.onSurfaceVariant : scheme.onSurface,
                        ),
                      ),
                      if (task.notes.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          task.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (task.dueDate != null) ...<Widget>[
                        const SizedBox(height: 8),
                        _DueBadge(
                          date: task.dueDate!,
                          overdue: overdue,
                          isDone: task.isDone,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({
    required this.date,
    required this.overdue,
    required this.isDone,
  });

  final DateTime date;
  final bool overdue;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = overdue
        ? scheme.error
        : isDone
        ? scheme.onSurfaceVariant
        : scheme.primary;
    final Color background = overdue
        ? scheme.errorContainer.withValues(alpha: 0.5)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.event_outlined, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            DateFormat('EEE, d MMM').format(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (overdue) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              'Overdue',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
