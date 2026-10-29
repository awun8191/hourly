import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/domain/entities/day_segments.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

void main() {
  final DateTime monday = DateTime(2026, 10, 26);

  HourEntry entry(int hour, {HourStatus status = HourStatus.active}) {
    return HourEntry(
      dateKey: '2026-10-26',
      hour: hour,
      text: 'Item $hour',
      status: status,
      updatedAt: monday,
    );
  }

  test('always builds 24 segments, one per hour, in hour order', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: const <HourEntry>[],
      day: monday,
    );

    expect(segments, hasLength(DayMeter.hoursInDay));
    expect(segments.map((DaySegment s) => s.hour), List<int>.generate(24, (int i) => i));
    expect(segments.every((DaySegment s) => s.state == DaySegmentState.empty), isTrue);
    expect(segments.every((DaySegment s) => s.isLive), isFalse);
  });

  test('maps green to in place and red to done per hour', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: <HourEntry>[
        entry(9),
        entry(11, status: HourStatus.completed),
      ],
      day: monday,
    );

    expect(segments[9].state, DaySegmentState.active);
    expect(segments[11].state, DaySegmentState.completed);
    expect(segments[10].state, DaySegmentState.empty);
    expect(segments[9].isPlanned, isTrue);
    expect(segments[10].isPlanned, isFalse);
  });

  test('marks the live hour from now on the same day', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: <HourEntry>[],
      day: monday,
      now: DateTime(2026, 10, 26, 14, 20),
    );

    expect(segments.where((DaySegment s) => s.isLive).single.hour, 14);
  });

  test('no segment is live when now is another day', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: <HourEntry>[],
      day: monday,
      now: DateTime(2026, 10, 27, 14, 20),
    );

    expect(segments.any((DaySegment s) => s.isLive), isFalse);
  });

  test('a resolved live hour wins over now, and out of range is dropped', () {
    final List<DaySegment> fromHour = DayMeter.forDay(
      entries: <HourEntry>[],
      day: monday,
      now: DateTime(2026, 10, 26, 14, 20),
      liveHour: 7,
    );
    final List<DaySegment> outOfRange = DayMeter.forDay(
      entries: <HourEntry>[],
      day: monday,
      liveHour: 24,
    );

    expect(fromHour.where((DaySegment s) => s.isLive).single.hour, 7);
    expect(outOfRange.any((DaySegment s) => s.isLive), isFalse);
  });

  test('skips entries outside the day', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: <HourEntry>[entry(-1), entry(24), entry(3)],
      day: monday,
    );

    expect(segments.where((DaySegment s) => s.isPlanned).single.hour, 3);
  });

  test('describes the meter in one sentence for a screen reader', () {
    final List<DaySegment> segments = DayMeter.forDay(
      entries: <HourEntry>[
        entry(9),
        entry(11, status: HourStatus.completed),
        entry(12, status: HourStatus.completed),
      ],
      day: monday,
      liveHour: 9,
    );
    final List<DaySegment> quiet = DayMeter.forDay(
      entries: <HourEntry>[],
      day: monday,
    );

    expect(
      DayMeter.describe(segments),
      'Day meter, 24 hours: 2 done, 1 in place, 21 free. Now 09:00',
    );
    expect(DayMeter.describe(quiet), 'Day meter, 24 hours: 0 done, 0 in place, 24 free');
  });

  test('segments group into four parts of day', () {
    expect(DayMeter.groupSize * 4, DayMeter.hoursInDay);
  });
}
