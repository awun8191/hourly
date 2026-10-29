import 'package:equatable/equatable.dart';

import '../../../../core/date/date_key.dart';
import 'hour_entry.dart';

/// State of one segment of the day meter.
///
/// The colours keep the app's mapping: [active] is green (the item is in
/// place), [completed] is red (the item is done), [empty] is the faint track.
enum DaySegmentState { empty, active, completed }

/// One hour of the day meter: which hour it stands for, what is in it, and
/// whether it is the live hour.
class DaySegment extends Equatable {
  const DaySegment({
    required this.hour,
    required this.state,
    this.isLive = false,
  });

  /// 0 to 23.
  final int hour;

  final DaySegmentState state;

  /// True for the hour that is running now. The meter outlines it.
  final bool isLive;

  bool get isPlanned => state != DaySegmentState.empty;

  @override
  List<Object?> get props => <Object?>[hour, state, isLive];
}

/// Turns a day's entries into the 24 fixed segments the day meter paints.
///
/// The model is pure: the widget only decides how to paint it. One segment per
/// hour, always 24, so the meter is a minimap of the day list under it and an
/// empty hour reads as an empty slot rather than as missing data.
abstract final class DayMeter {
  /// One segment per hour of the day.
  static const int hoursInDay = 24;

  /// Segments per part of day (night, morning, afternoon, evening). The meter
  /// draws a wider gap between groups, matching the list sections.
  static const int groupSize = 6;

  /// Builds the 24 segments for [day] from [entries].
  ///
  /// The live hour is [liveHour] when the caller already resolved it from the
  /// cubit's clock, otherwise the hour of [now] when [now] falls on [day].
  /// Entries outside 0 to 23 are skipped.
  static List<DaySegment> forDay({
    required Iterable<HourEntry> entries,
    required DateTime day,
    DateTime? now,
    int? liveHour,
  }) {
    final Map<int, HourStatus> byHour = <int, HourStatus>{};
    for (final HourEntry entry in entries) {
      if (entry.hour < 0 || entry.hour >= hoursInDay) {
        continue;
      }
      byHour[entry.hour] = entry.status;
    }

    final int? live = liveHour ??
        (now != null && DateKey.isSameDay(day, now) ? now.hour : null);
    final int? liveInRange =
        live != null && live >= 0 && live < hoursInDay ? live : null;

    return List<DaySegment>.generate(
      hoursInDay,
      (int hour) => DaySegment(
        hour: hour,
        state: switch (byHour[hour]) {
          HourStatus.active => DaySegmentState.active,
          HourStatus.completed => DaySegmentState.completed,
          null => DaySegmentState.empty,
        },
        isLive: hour == liveInRange,
      ),
      growable: false,
    );
  }

  /// The one sentence the meter gives to a screen reader.
  ///
  /// It carries the counts and the live hour, so a reader gets the whole meter
  /// without walking 24 decorative segments.
  static String describe(List<DaySegment> segments) {
    int done = 0;
    int inPlace = 0;
    int? live;
    for (final DaySegment segment in segments) {
      switch (segment.state) {
        case DaySegmentState.completed:
          done++;
        case DaySegmentState.active:
          inPlace++;
        case DaySegmentState.empty:
          break;
      }
      if (segment.isLive) {
        live = segment.hour;
      }
    }
    final int free = segments.length - done - inPlace;
    final StringBuffer label = StringBuffer(
      'Day meter, ${segments.length} hours: $done done, $inPlace in place, $free free',
    );
    if (live != null) {
      label.write('. Now ${DateKey.hourLabel(live)}');
    }
    return label.toString();
  }
}
