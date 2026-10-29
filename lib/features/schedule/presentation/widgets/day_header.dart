import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_segments.dart';
import '../../domain/entities/hour_entry.dart';

/// Date, day navigation, the segmented day meter, and the color legend.
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
          const SizedBox(height: Insets.sm + 2),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.xs + 2),
              child: Text(
                'Tap an hour to plan it',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            _DayMeter(
              segments: segments,
              palette: palette,
              track: scheme.surfaceContainerHighest,
              ring: scheme.onSurface,
            ),
          const SizedBox(height: Insets.sm),
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

/// The segmented day meter: one segment per hour, 24 in all, drawn as four
/// groups of six to match the night, morning, afternoon, and evening sections
/// of the list below it.
///
/// Red is done, green is in place, the faint track is a free hour, and the live
/// hour carries a ring and a small lift. The whole meter is one semantics node;
/// the segments themselves are decorative.
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
        boxShadow: segment.isLive
            ? <BoxShadow>[
                BoxShadow(
                  color: fill.withValues(alpha: 0.4),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
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
