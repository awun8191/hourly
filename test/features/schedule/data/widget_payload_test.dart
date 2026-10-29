import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/data/widget/widget_payload.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

void main() {
  HourEntry entry(int hour, String text, {HourStatus status = HourStatus.active}) {
    return HourEntry(
      dateKey: '2026-10-26',
      hour: hour,
      text: text,
      status: status,
      updatedAt: DateTime(2026, 10, 26),
    );
  }

  test('builds five slots from the current hour', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 9, 30),
      entries: <HourEntry>[
        entry(9, 'Standup'),
        entry(11, 'Review', status: HourStatus.completed),
      ],
    );

    expect(payload['date'], '2026-10-26');
    expect(payload['done'], 1);
    expect(payload['total'], 2);

    final List<Object?> slots = payload['slots']! as List<Object?>;
    expect(slots, hasLength(5));
    final Map<String, Object?> first = slots.first! as Map<String, Object?>;
    expect(first['hour'], 9);
    expect(first['label'], '09:00');
    expect(first['text'], 'Standup');
    expect(first['status'], 'active');
    expect(first['current'], isTrue);
    expect(payload['nowHour'], 9);

    final Map<String, Object?> third = slots[2]! as Map<String, Object?>;
    expect(third['hour'], 11);
    expect(third['status'], 'completed');

    final Map<String, Object?> empty = slots[1]! as Map<String, Object?>;
    expect(empty['hour'], 10);
    expect(empty['status'], 'empty');
    expect(empty['text'], '');
    // Only the live hour is current; a future row must never paint NOW.
    expect(empty['current'], isFalse);
  });

  test('stops at midnight instead of wrapping to the next day', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 23, 15),
      entries: <HourEntry>[entry(23, 'Sleep')],
    );

    expect(payload['slots'], hasLength(1));
    expect((payload['slots']! as List<Object?>).single, containsPair('hour', 23));
  });

  test('counts the whole day, not only the visible slots', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 20),
      entries: <HourEntry>[
        entry(7, 'Gym', status: HourStatus.completed),
        entry(8, 'Work', status: HourStatus.completed),
        entry(21, 'Read'),
      ],
    );

    expect(payload['done'], 2);
    expect(payload['total'], 3);
    expect(payload['day'], 'Monday 26');
  });

  test('reports the minutes into the live hour and its progress', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 9, 42),
      entries: <HourEntry>[entry(9, 'Standup')],
    );

    expect(payload['minutesIntoHour'], 42);
    expect(payload['minutesLeft'], 18);
    expect(payload['hourPercent'], 70);
  });

  test('the hour progress is capped at the end of the hour', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 23, 59),
      entries: <HourEntry>[entry(23, 'Sleep')],
    );

    expect(payload['minutesIntoHour'], 59);
    expect(payload['minutesLeft'], 1);
    expect(payload['hourPercent'], 98);
  });

  test('exposes the next planned item after the live hour', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 9, 5),
      entries: <HourEntry>[
        entry(9, 'Standup'),
        entry(11, 'Review', status: HourStatus.completed),
      ],
    );

    final Map<String, Object?> next = payload['next']! as Map<String, Object?>;
    expect(next['hour'], 11);
    expect(next['label'], '11:00');
    expect(next['text'], 'Review');
    expect(next['status'], 'completed');
  });

  test('there is no next item when the rest of the window is empty', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 21),
      entries: <HourEntry>[entry(9, 'Gym'), entry(21, 'Read')],
    );

    expect(payload['next'], isNull);
  });

  test('day progress uses the whole day, not the visible slots', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 20),
      entries: <HourEntry>[
        entry(7, 'Gym', status: HourStatus.completed),
        entry(8, 'Work', status: HourStatus.completed),
        entry(21, 'Read'),
      ],
    );

    expect(payload['dayPercent'], 67);
  });

  test('lists every planned hour for the widget day meter, in hour order', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 20),
      entries: <HourEntry>[
        entry(21, 'Read'),
        entry(7, 'Gym', status: HourStatus.completed),
        entry(8, 'Work', status: HourStatus.completed),
      ],
    );

    final List<Object?> segments = payload['segments']! as List<Object?>;
    expect(segments, hasLength(3));
    expect(segments.map((Object? item) => (item! as Map<String, Object?>)['hour']),
        <int>[7, 8, 21]);
    expect(segments.map((Object? item) => (item! as Map<String, Object?>)['state']),
        <String>['completed', 'completed', 'active']);
  });

  test('the widget day meter is empty when the day has no items', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 26, 9),
      entries: const <HourEntry>[],
    );

    expect(payload['segments'], isEmpty);
  });
}
