import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/data/widget/widget_payload.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

void main() {
  HourEntry entry(int hour, String text, {HourStatus status = HourStatus.active}) {
    return HourEntry(
      dateKey: '2026-10-30',
      hour: hour,
      text: text,
      status: status,
      updatedAt: DateTime(2026, 10, 30),
    );
  }

  test('sends the live hour and the next three hours', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 20, 34),
      entries: <HourEntry>[
        entry(9, 'Gym'),
        entry(20, 'Slap Aaliyah'),
        entry(22, 'Read'),
      ],
    );

    expect(payload['date'], '2026-10-30');
    expect(payload['day'], 'Friday 30');
    expect(payload['hour'], 20);
    expect(payload['label'], '20:00');
    expect(payload['text'], 'Slap Aaliyah');
    expect(payload['status'], 'active');
    expect(payload['minutesLeft'], 26);

    final List<Object?> upcoming = payload['upcoming']! as List<Object?>;
    expect(upcoming, hasLength(3));
    final Map<String, Object?> first = upcoming.first! as Map<String, Object?>;
    expect(first['hour'], 21);
    expect(first['label'], '21:00');
    expect(first['text'], '');
    expect(first['status'], 'empty');
    final Map<String, Object?> second = upcoming[1]! as Map<String, Object?>;
    expect(second['hour'], 22);
    expect(second['text'], 'Read');
    expect(second['status'], 'active');
  });

  test('stops the fields at midnight', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 22, 10),
      entries: const <HourEntry>[],
    );

    final List<Object?> upcoming = payload['upcoming']! as List<Object?>;
    expect(upcoming, hasLength(1));
    expect((upcoming.single! as Map<String, Object?>)['hour'], 23);
  });

  test('an empty live hour has no text and an empty status', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 9, 0),
      entries: <HourEntry>[entry(10, 'Later')],
    );

    expect(payload['hour'], 9);
    expect(payload['text'], '');
    expect(payload['status'], 'empty');
    expect(payload['minutesLeft'], 60);
  });

  test('a done live hour keeps its text and status', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 12, 15),
      entries: <HourEntry>[entry(12, 'Bakery', status: HourStatus.completed)],
    );

    expect(payload['text'], 'Bakery');
    expect(payload['status'], 'completed');
    expect(payload['minutesLeft'], 45);
  });

  test('the minutes left never name another hour', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 23, 59),
      entries: const <HourEntry>[],
    );

    expect(payload['minutesLeft'], 1);
  });
}
