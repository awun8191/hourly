import 'package:flutter/material.dart';

import '../../../../core/date/date_key.dart';
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
    final bool isEditing = widget.entry != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            DateKey.hourRangeLabel(widget.hour),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'One line for this hour.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('hour-text-field'),
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'What happens in this hour?',
              counterText: '',
            ),
            onSubmitted: (String _) => _save(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (isEditing)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              FilledButton(
                key: const Key('hour-save-button'),
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
