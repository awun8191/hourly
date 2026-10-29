import 'package:flutter/material.dart';

import '../../../../core/date/date_key.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hour_entry.dart';
import 'hour_toggle.dart';

/// One hour row: the time rail, then the block.
///
/// Empty: a quiet outline that opens the editor.
/// In place: green card, switch on.
/// Done: muted red card, struck text, switch off.
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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);
    final HourEntry? current = entry;
    final bool isDone = current?.isCompleted ?? false;
    final bool isEmpty = current == null;

    final Color surface = isEmpty
        ? (isCurrentHour ? scheme.primary.withValues(alpha: 0.06) : Colors.transparent)
        : isDone
            ? palette.completedSurface.withValues(alpha: 0.55)
            : palette.activeSurface;
    final Color border = isEmpty
        ? (isCurrentHour
            ? scheme.primary.withValues(alpha: 0.6)
            : scheme.outlineVariant.withValues(alpha: 0.7))
        : isDone
            ? palette.completed.withValues(alpha: 0.22)
            : palette.active.withValues(alpha: 0.42);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _HourRail(hour: hour, isCurrentHour: isCurrentHour),
          const SizedBox(width: Insets.md),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.state,
              height: isEmpty ? 50 : 58,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: _radius,
                border: Border.all(color: border),
                boxShadow: isCurrentHour
                    ? <BoxShadow>[
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      container: true,
                      button: true,
                      label: _semanticsLabel(current),
                      onTap: onTap,
                      child: ExcludeSemantics(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: _radius,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: _radius,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: Insets.lg,
                                right: isEmpty ? Insets.lg : Insets.xs,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _content(theme, scheme, palette, current),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: HourToggle(
                      key: Key('toggle-$hour'),
                      value: current != null && !isDone,
                      semanticLabel: _toggleLabel(current),
                      onChanged: isEmpty ? onTap : onToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toggleLabel(HourEntry? current) {
    if (current == null) {
      return 'Plan this hour';
    }
    return current.isCompleted
        ? 'Put "${current.text}" back in place'
        : 'Mark "${current.text}" done';
  }

  String _semanticsLabel(HourEntry? current) {
    if (current == null) {
      return '${DateKey.hourRangeLabel(hour)}, empty. Double tap to plan this hour.';
    }
    final String state = current.isCompleted ? 'done' : 'in place';
    return '${DateKey.hourRangeLabel(hour)}, ${current.text}, $state. '
        'Double tap to edit.';
  }

  Widget _content(
    ThemeData theme,
    ColorScheme scheme,
    StatusPalette palette,
    HourEntry? current,
  ) {
    if (current == null) {
      final Color tint = isCurrentHour ? scheme.primary : scheme.onSurfaceVariant;
      return Row(
        children: <Widget>[
          Icon(Icons.add_rounded, size: 18, color: tint),
          const SizedBox(width: Insets.sm),
          Flexible(
            child: Text(
              isCurrentHour ? 'Plan this hour' : 'Add task',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tint,
                fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    if (current.isCompleted) {
      return Row(
        children: <Widget>[
          AnimatedContainer(
            duration: Motion.normal,
            curve: Motion.state,
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.completed,
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              current.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13.5,
                height: 1.2,
                color: palette.completedText,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
                decorationColor: palette.completed,
                decorationThickness: 1.6,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      current.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 15,
        color: palette.activeText,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The left rail: the hour and, for the live hour, a small NOW tag.
class _HourRail extends StatelessWidget {
  const _HourRail({
    required this.hour,
    required this.isCurrentHour,
  });

  final int hour;
  final bool isCurrentHour;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            duration: Motion.fast,
            curve: Motion.state,
            style: theme.textTheme.labelMedium!.copyWith(
              fontSize: 12.5,
              height: 1.1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              fontWeight: isCurrentHour ? FontWeight.w800 : FontWeight.w500,
              color: isCurrentHour
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            child: Text(DateKey.hourLabel(hour)),
          ),
          const SizedBox(height: 3),
          if (isCurrentHour)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'NOW',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  height: 1.2,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            )
          else
            const SizedBox(height: 11),
        ],
      ),
    );
  }
}

