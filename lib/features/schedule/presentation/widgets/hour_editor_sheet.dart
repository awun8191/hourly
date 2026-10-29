import 'package:flutter/material.dart';

import '../../../../core/date/date_key.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hour_entry.dart';

enum HourEditorAction { save, delete }

typedef HourEditorResult = ({HourEditorAction action, String text});

/// Opens the editor for [hour]. Returns null when the user closes the sheet.
Future<HourEditorResult?> showHourEditor(
  BuildContext context, {
  required int hour,
  HourEntry? entry,
}) {
  return showModalBottomSheet<HourEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => HourEditorSheet(hour: hour, entry: entry),
  );
}

class HourEditorSheet extends StatefulWidget {
  const HourEditorSheet({super.key, required this.hour, this.entry});

  final int hour;
  final HourEntry? entry;

  @override
  State<HourEditorSheet> createState() => _HourEditorSheetState();
}

class _HourEditorSheetState extends State<HourEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.entry?.text ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    Navigator.of(context).pop<HourEditorResult>((
      action: HourEditorAction.save,
      text: text,
    ));
  }

  void _delete() {
    Navigator.of(context).pop<HourEditorResult>((
      action: HourEditorAction.delete,
      text: '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);
    final bool isEditing = widget.entry != null;
    final bool isDone = widget.entry?.isCompleted ?? false;

    final String stateLabel = !isEditing
        ? 'EMPTY'
        : isDone
            ? 'DONE'
            : 'IN PLACE';
    final Color stateColor = !isEditing
        ? scheme.onSurfaceVariant
        : isDone
            ? palette.completed
            : palette.active;
    final Color stateSurface = !isEditing
        ? scheme.surfaceContainerHighest
        : isDone
            ? palette.completedSurface
            : palette.activeSurface;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Insets.xl,
          Insets.xs,
          Insets.xl,
          MediaQuery.viewInsetsOf(context).bottom + Insets.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    DateKey.hourRangeLabel(widget.hour),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stateSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.xs + 2),
            Text(
              isEditing
                  ? 'Edit the one item in this hour.'
                  : 'One item per hour. Keep it to a single line.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.lg),
            TextField(
              key: const Key('hour-text-field'),
              controller: _controller,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'What happens in this hour?',
                counterStyle: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              onSubmitted: (String _) => _save(),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: <Widget>[
                if (isEditing)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                    ),
                  ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('hour-save-button'),
                  onPressed: _save,
                  icon: Icon(
                    isEditing ? Icons.check_rounded : Icons.add_rounded,
                    size: 19,
                  ),
                  label: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
