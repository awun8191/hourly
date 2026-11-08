import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

/// Date, day navigation, and the planned count.
///
/// The hierarchy steps down three times: the chip, the date, then the
/// count. Each step changes weight and tracking, not only size, so the header
/// reads as one block instead of labels set at the same emphasis.
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
    final String weekday = DateFormat('EEEE').format(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.sm, Insets.lg, Insets.sm),
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
                    const SizedBox(height: 6),
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
                      child: Column(
                        key: ValueKey<String>('day-${day.toIso8601String()}'),
                        children: <Widget>[
                          Text(
                            weekday,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d MMMM yyyy').format(day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                              height: 1.3,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
          const SizedBox(height: Insets.lg),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Nothing planned yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    'Pick an hour below to plan it.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Insets.md),
          Row(
            children: <Widget>[
              Expanded(
                child: total > 0
                    ? Text(
                        '$doneCount of $total planned hours done',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
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
      iconSize: 20,
      style: IconButton.styleFrom(
        minimumSize: const Size(Insets.touch, Insets.touch),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.40),
        foregroundColor: scheme.onSurfaceVariant,
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
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: foreground),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              height: 1.2,
              color: foreground,
              fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(8),
          child: chip,
        ),
      ),
    );
  }
}
