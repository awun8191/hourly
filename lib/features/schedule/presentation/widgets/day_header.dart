import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

/// Date, day navigation, done progress, and the color legend.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.doneCount,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime day;
  final bool isToday;
  final int doneCount;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);
    final String weekday = DateFormat('EEEE').format(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.sm, Insets.xs, Insets.sm, Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ArrowButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous day',
                onPressed: onPrevious,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _DayChip(
                      label: isToday ? 'TODAY' : weekday.toUpperCase(),
                      isLive: isToday,
                      onPressed: isToday ? null : onToday,
                    ),
                    const SizedBox(height: Insets.xs + 2),
                    AnimatedSwitcher(
                      duration: Motion.normal,
                      switchInCurve: Motion.enter,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        DateFormat('d MMMM yyyy').format(day),
                        key: ValueKey<String>('day-${day.toIso8601String()}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ArrowButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next day',
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.xs),
              child: Text(
                'Tap an hour to plan it',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _DoneBar(
                    value: total == 0 ? 0 : doneCount / total,
                    color: palette.completed,
                    track: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: Insets.md),
                Text(
                  '$doneCount of $total done',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          const SizedBox(height: Insets.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _LegendTag(
                color: palette.active,
                label: 'In place',
                background: palette.activeSurface.withValues(alpha: 0.7),
                foreground: palette.activeText,
              ),
              const SizedBox(width: Insets.sm),
              _LegendTag(
                color: palette.completed,
                label: 'Done',
                background: palette.completedSurface.withValues(alpha: 0.7),
                foreground: palette.completedText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 22,
      style: IconButton.styleFrom(
        minimumSize: const Size(Insets.touch, Insets.touch),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
    );
  }
}

/// The small tag above the date. Tapping it returns to today.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isLive,
    required this.onPressed,
  });

  final String label;
  final bool isLive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color foreground = isLive ? scheme.primary : scheme.onSurfaceVariant;
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isLive
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: foreground),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return chip;
    }
    return Semantics(
      button: true,
      label: 'Go to today',
      child: Tooltip(
        message: 'Back to today',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(7),
          child: chip,
        ),
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  const _DoneBar({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
      duration: Motion.slow,
      curve: Motion.enter,
      builder: (BuildContext context, double animated, Widget? child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: animated,
            minHeight: 6,
            backgroundColor: track,
            color: color,
          ),
        );
      },
    );
  }
}

class _LegendTag extends StatelessWidget {
  const _LegendTag({
    required this.color,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final Color color;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 10.5,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
