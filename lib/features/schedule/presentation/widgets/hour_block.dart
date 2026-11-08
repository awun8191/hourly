import 'package:flutter/material.dart';

import '../../../../core/date/date_key.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hour_entry.dart';
import 'hour_toggle.dart';

/// One hour row: the time rail, then the block.
///
/// Empty: a quiet outline that opens the editor.
/// In place: accent card, toggle on.
/// Done: muted red card, struck text, switch off.
///
/// The live hour is the only row that lifts off the page, and it lifts with a
/// neutral depth shadow and a tinted surface, never with a coloured halo. A
/// glow around a card is decoration, and on this screen colour already means
/// state.
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

  /// Depth only, no colour: 8% black. On the black theme it paints nothing, so
  /// the dark live row lifts with its surface and hairline alone.
  static const List<BoxShadow> _lift = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);
    final HourEntry? current = entry;
    final bool isDone = current?.isCompleted ?? false;
    final bool isEmpty = current == null;

    final Color surface = isEmpty
        ? (isCurrentHour ? scheme.primary.withValues(alpha: 0.07) : Colors.transparent)
        : isDone
            ? palette.completedSurface.withValues(alpha: 0.85)
            : palette.activeSurface;
    final Color border = isEmpty
        ? (isCurrentHour
            ? scheme.primary.withValues(alpha: 0.55)
            : scheme.outlineVariant.withValues(alpha: 0.55))
        : isDone
            ? palette.completed.withValues(alpha: 0.30)
            : palette.active.withValues(alpha: 0.38);

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _HourRail(hour: hour, isCurrentHour: isCurrentHour),
          const SizedBox(width: Insets.md),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.state,
              height: isEmpty ? 52 : 58,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: _radius,
                border: Border.all(color: border),
                boxShadow: isCurrentHour ? _lift : null,
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
          Icon(Icons.add_rounded, size: 16, color: tint),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isCurrentHour ? 'Plan this hour' : 'Add task',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                height: 1.2,
                color: tint,
                fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (current.isCompleted) {
      return Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: palette.completed),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              current.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                height: 1.25,
                color: palette.completedText,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.lineThrough,
                decorationColor: palette.completedText,
                decorationThickness: 1.4,
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
        height: 1.25,
        color: palette.activeText,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The left rail: the hour and, for the live hour, a small NOW tag.
///
/// The rail is a fixed column of right aligned tabular figures, so all 24 times
/// share one optical edge and every card starts on one line. The tag sits under
/// the hour rather than beside it, which keeps that edge intact.
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
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            duration: Motion.fast,
            curve: Motion.state,
            style: theme.textTheme.labelMedium!.copyWith(
              height: 1.1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.1,
              color: isCurrentHour ? scheme.primary : scheme.onSurfaceVariant,
            ),
            child: Text(DateKey.hourLabel(hour)),
          ),
          const SizedBox(height: 3),
          if (isCurrentHour)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'NOW',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1.15,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
