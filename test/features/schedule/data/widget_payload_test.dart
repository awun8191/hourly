import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/schedule/data/widget/widget_payload.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

void main() {
  HourEntry entry(
    int hour,
    String text, {
    String dateKey = '2026-10-30',
    HourStatus status = HourStatus.active,
  }) {
    return HourEntry(
      dateKey: dateKey,
      hour: hour,
      text: text,
      status: status,
      updatedAt: DateTime(2026, 10, 30),
    );
  }

  List<Map<String, Object?>> slotsOf(Map<String, Object?> payload) {
    return (payload['slots']! as List<Object?>).cast<Map<String, Object?>>();
  }

  test('the window starts at the live hour and runs across midnight', () {
    final Map<String, Object?> payload = WidgetPayload.build(
      now: DateTime(2026, 10, 30, 22, 34),
      entries: <HourEntry>[
        entry(9, 'Gym'),
        entry(22, 'Brush teeth'),
        entry(1, 'Sleep', dateKey: '2026-10-31'),
      ],
    );

    final List<Map<String, Object?>> slots = slotsOf(payload);
    expect(slots, hasLength(26));
    expect(payload['date'], '2026-10-30');
    expect(payload['hour'], 22);

    final Map<String, Object?> live = slots.first;
    expect(live['date'], '2026-10-30');
    expect(live['hour'], 22);
    expect(live['label'], '22:00');
    expect(live['text'], 'Brush teeth');
    expect(live['status'], 'active');
    expect(live['tomorrow'], isFalse);

    final Map<String, Object?> midnight = slots[2];
    expect(midnight['date'], '2026-10-31');
    expect(midnight['hour'], 0);
    expect(midnight['tomorrow'], isTrue);
    expect(midnight['text'], '');

    final Map<String, Object?> nextDay = slots[3];
    expect(nextDay['hour'], 1);
    expect(nextDay['text'], 'Sleep');
  });

  test('an empty hour carries no text and an empty status', () {
    final List<Map<String, Object?>> slots = slotsOf(
      WidgetPayload.build(
        now: DateTime(2026, 10, 30, 9, 15),
        entries: const <HourEntry>[],
      ),
    );

    expect(slots[1]['hour'], 10);
    expect(slots[1]['text'], '');
    expect(slots[1]['status'], 'empty');
  });

  test('a done hour keeps its status', () {
    final List<Map<String, Object?>> slots = slotsOf(
      WidgetPayload.build(
        now: DateTime(2026, 10, 30, 12, 5),
        entries: <HourEntry>[entry(12, 'Bakery', status: HourStatus.completed)],
      ),
    );

    expect(slots.first['status'], 'completed');
    expect(slots.first['text'], 'Bakery');
  });
}
