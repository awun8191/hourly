import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/task_tile.dart';
import '../widgets/tasks_empty_state.dart';

/// Main screen: progress, filter, task list, and the entry points to edit.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Future<void> _openEditor(BuildContext context, {Task? task}) async {
    final TaskCubit cubit = context.read<TaskCubit>();
    final TaskDraft? draft = await showTaskEditor(context, task: task);
    if (draft == null) {
      return;
    }
    if (task == null) {
      await cubit.addTask(
        title: draft.title,
        notes: draft.notes,
        dueDate: draft.dueDate,
      );
      return;
    }
    await cubit.updateTask(
      task.copyWith(
        title: draft.title,
        notes: draft.notes,
        dueDate: draft.dueDate,
        clearDueDate: draft.dueDate == null,
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final TaskCubit cubit = context.read<TaskCubit>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool deleted = await cubit.deleteTask(task.id);
    if (!deleted) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(label: 'Undo', onPressed: cubit.undoDelete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: <Widget>[
          BlocBuilder<TaskCubit, TaskState>(
            buildWhen: (TaskState previous, TaskState current) =>
                previous.hasCompleted != current.hasCompleted,
            builder: (BuildContext context, TaskState state) {
              if (!state.hasCompleted) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (String value) {
                  if (value == 'clear-completed') {
                    context.read<TaskCubit>().clearCompleted();
                  }
                },
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'clear-completed',
                    child: Text('Clear completed'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<TaskCubit, TaskState>(
        listenWhen: (TaskState previous, TaskState current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (BuildContext context, TaskState state) {
          final String? message = state.errorMessage;
          if (message == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (BuildContext context, TaskState state) {
          if (state.status == TaskStatus.initial || state.status == TaskStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Task> visible = state.visibleTasks;
          return Column(
            children: <Widget>[
              _ProgressHeader(state: state),
              _FilterBar(
                filter: state.filter,
                onChanged: (TaskFilter filter) =>
                    context.read<TaskCubit>().setFilter(filter),
              ),
              Expanded(
                child: visible.isEmpty
                    ? TasksEmptyState(filter: state.filter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: visible.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final Task task = visible[index];
                          return TaskTile(
                            key: ValueKey<String>(task.id),
                            task: task,
                            onToggle: () =>
                                context.read<TaskCubit>().toggleTask(task.id),
                            onEdit: () => _openEditor(context, task: task),
                            onDelete: () => _deleteTask(context, task),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final TaskState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int total = state.tasks.length;
    final String label = state.doneCount == total
        ? 'All $total tasks are done'
        : '${state.doneCount} of $total done';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<TaskFilter>(
          segments: TaskFilter.values
              .map(
                (TaskFilter value) => ButtonSegment<TaskFilter>(
                  value: value,
                  label: Text(value.label),
                ),
              )
              .toList(growable: false),
          selected: <TaskFilter>{filter},
          showSelectedIcon: false,
          onSelectionChanged: (Set<TaskFilter> selection) => onChanged(selection.first),
        ),
      ),
    );
  }
}
