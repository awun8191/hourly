import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_segments.dart';
import '../../domain/entities/hour_entry.dart';

/// Date, day navigation, the segmented day meter, and the color legend.
///
/// The hierarchy steps down four times: the chip, the date, the meter, then the
/// count. Each step changes weight and tracking, not only size, so the header
/// reads as one block instead of five labels set at the same emphasis.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.doneCount,
    required this.total,
    required this.entries,
    required this.liveHour,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPlanHour,
  });

  final DateTime day;
  final bool isToday;
  final int doneCount;
  final int total;

  /// The selected day's items, one per hour.
  final Iterable<HourEntry> entries;

  /// The hour running now, or null when the selected day is not today.
  final int? liveHour;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  /// Opens the editor for the hour the empty day CTA points at.
  final ValueChanged<int> onPlanHour;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final StatusPalette palette = StatusPalette.of(context);
    final String weekday = DateFormat('EEEE').format(day);
    final List<DaySegment> segments = DayMeter.forDay(
      entries: entries,
      day: day,
      liveHour: liveHour,
    );

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
                    'Pick an hour below, or start with this one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  FilledButton(
                    onPressed: () => onPlanHour(liveHour ?? 9),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Plan the current hour'),
                  ),
                ],
              ),
            )
          else
            _DayMeter(
              segments: segments,
              palette: palette,
              track: scheme.surfaceContainerHighest,
              ring: scheme.onSurface,
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
              const SizedBox(width: Insets.sm),
              _LegendTag(
                color: palette.active,
                label: 'In place',
                background: palette.activeSurface.withValues(alpha: 0.65),
                foreground: palette.activeText,
              ),
              const SizedBox(width: Insets.sm),
              _LegendTag(
                color: palette.completed,
                label: 'Done',
                background: palette.completedSurface.withValues(alpha: 0.75),
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

/// The segmented day meter: one segment per hour, 24 in all, drawn as four
/// groups of six to match the night, morning, afternoon, and evening sections
/// of the list below it.
///
/// Red is done, the accent is in place, the faint track is a free hour, and the live
/// hour carries a ring and a small lift. The whole meter is one semantics node;
/// the segments themselves are decorative.
///
/// The lift is height and a hairline ring only. A tick that glowed its own fill
/// blurred into its neighbours: a status strip has to read as state, not as a
/// light source.
class _DayMeter extends StatelessWidget {
  const _DayMeter({
    required this.segments,
    required this.palette,
    required this.track,
    required this.ring,
  });

  final List<DaySegment> segments;
  final StatusPalette palette;
  final Color track;
  final Color ring;

  /// Height of a quiet segment.
  static const double _height = 8;

  /// Height of the live segment. The extra two points are the "lift".
  static const double _liveHeight = 12;

  static const double _gap = 2;
  static const double _groupGap = 6;

  @override
  Widget build(BuildContext context) {
    final int groups = (segments.length / DayMeter.groupSize).ceil();
    final List<Widget> bars = <Widget>[];
    for (int group = 0; group < groups; group++) {
      final int start = group * DayMeter.groupSize;
      final int end = math.min(start + DayMeter.groupSize, segments.length);
      if (group > 0) {
        bars.add(const SizedBox(width: _groupGap));
      }
      for (int index = start; index < end; index++) {
        if (index > start) {
          bars.add(const SizedBox(width: _gap));
        }
        final DaySegment segment = segments[index];
        bars.add(
          Expanded(
            child: _DayMeterBar(
              segment: segment,
              fill: switch (segment.state) {
                DaySegmentState.completed => palette.completed,
                DaySegmentState.active => palette.active,
                DaySegmentState.empty => track,
              },
              ring: ring,
              height: segment.isLive ? _liveHeight : _height,
            ),
          ),
        );
      }
    }

    return Semantics(
      key: const Key('day-meter'),
      container: true,
      label: DayMeter.describe(segments),
      child: ExcludeSemantics(
        child: SizedBox(
          height: _liveHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: bars,
          ),
        ),
      ),
    );
  }
}

class _DayMeterBar extends StatelessWidget {
  const _DayMeterBar({
    required this.segment,
    required this.fill,
    required this.ring,
    required this.height,
  });

  final DaySegment segment;
  final Color fill;
  final Color ring;
  final double height;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(3);
    return AnimatedContainer(
      key: Key('day-seg-${segment.hour}'),
      duration: Motion.fast,
      curve: Motion.state,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: segment.isLive ? Border.all(color: ring, width: 1.4) : null,
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              height: 1.2,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
