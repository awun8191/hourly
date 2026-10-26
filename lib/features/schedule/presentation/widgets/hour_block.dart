import 'package:flutter/material.dart';

import '../../../../core/date/date_key.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hour_entry.dart';

/// One hour row: the time label, then the block.
///
/// Empty: a tap target that opens the editor.
/// Active: green card, switch on.
/// Completed: small red text, switch off.
class HourBlock extends StatelessWidget {
  const HourBlock({
    super.key,
    required this.hour,
    required this.entry,
    required this.isCurrentHour,
    required this.onTap,
    required this.onToggle,
  });

  final int hour;
  final HourEntry? entry;
  final bool isCurrentHour;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  DateKey.hourLabel(hour),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isCurrentHour ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrentHour ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
                if (isCurrentHour)
                  Text(
                    'now',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _block(context, theme, scheme, palette)),
        ],
      ),
    );
  }

  Widget _block(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    StatusPalette palette,
  ) {
    final HourEntry? current = entry;
    final BorderRadius radius = BorderRadius.circular(14);

    if (current == null) {
      return Material(
        color: isCurrentHour ? scheme.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isCurrentHour
                    ? scheme.primary.withValues(alpha: 0.5)
                    : scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: <Widget>[
                Icon(Icons.add_rounded, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Add task',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (current.isCompleted) {
      return Material(
        color: palette.completedSurface.withValues(alpha: 0.5),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 4),
            child: Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.completed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    current.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.completedText,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: palette.completed,
                    ),
                  ),
                ),
                _HourSwitch(
                  key: Key('toggle-$hour'),
                  value: false,
                  palette: palette,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: palette.activeSurface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: palette.active.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  current.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.activeText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _HourSwitch(
                key: Key('toggle-$hour'),
                value: true,
                palette: palette,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourSwitch extends StatelessWidget {
  const _HourSwitch({
    super.key,
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  final bool value;
  final StatusPalette palette;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: (bool _) => onChanged(),
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? palette.active
              : palette.completed;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
