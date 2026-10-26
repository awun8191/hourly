import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task.dart';

/// Values returned by the editor sheet.
typedef TaskDraft = ({String title, String notes, DateTime? dueDate});

/// Opens the editor and returns the draft, or null when the user cancels.
Future<TaskDraft?> showTaskEditor(BuildContext context, {Task? task}) {
  return showModalBottomSheet<TaskDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => TaskEditorSheet(task: task),
  );
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task});

  final Task? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController = TextEditingController(
    text: widget.task?.title ?? '',
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.task?.notes ?? '',
  );
  late DateTime? _dueDate = widget.task?.dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop<TaskDraft>((
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      dueDate: _dueDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEditing = widget.task != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              isEditing ? 'Edit task' : 'New task',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('task-title-field'),
              controller: _titleController,
              autofocus: !isEditing,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                counterText: '',
              ),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty) ? 'Give the task a title.' : null,
              onFieldSubmitted: (String _) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('task-notes-field'),
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      _dueDate == null
                          ? 'Add due date'
                          : DateFormat('EEE, d MMM yyyy').format(_dueDate!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_dueDate != null) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    tooltip: 'Remove due date',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEditing ? 'Save changes' : 'Add task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
