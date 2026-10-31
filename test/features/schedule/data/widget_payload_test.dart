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

  test('sends only the live hour', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 23, 34),
      entries: <HourEntry>[entry(9, 'Gym'), entry(23, 'Slap Aaliyah')],
    );

    expect(payload['date'], '2026-10-30');
    expect(payload['day'], 'Friday 30');
    expect(payload['hour'], 23);
    expect(payload['label'], '23:00');
    expect(payload['text'], 'Slap Aaliyah');
    expect(payload['status'], 'active');
    expect(payload['minutesLeft'], 26);
    expect(payload.containsKey('slots'), isFalse);
    expect(payload.containsKey('segments'), isFalse);
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
