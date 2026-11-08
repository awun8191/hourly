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

  test('the list holds the whole day, midnight to 23:00', () {
    final List<Map<String, Object?>> slots = slotsOf(
      WidgetPayload.build(
        now: DateTime(2026, 10, 30, 20, 34),
        entries: const <HourEntry>[],
      ),
    );

    expect(slots, hasLength(24));
    expect(slots.first['hour'], 0);
    expect(slots.first['label'], '00:00');
    expect(slots.last['hour'], 23);
    expect(slots.last['label'], '23:00');
    for (final Map<String, Object?> slot in slots) {
      expect(slot['date'], '2026-10-30');
    }
  });

  test('morning items still show when the day is almost over', () {
    final List<Map<String, Object?>> slots = slotsOf(
      WidgetPayload.build(
        now: DateTime(2026, 10, 30, 22, 10),
        entries: <HourEntry>[
          entry(9, 'Gym'),
          entry(12, 'Bakery', status: HourStatus.completed),
        ],
      ),
    );

    final Map<String, Object?> morning = slots[9];
    expect(morning['hour'], 9);
    expect(morning['text'], 'Gym');
    expect(morning['status'], 'active');

    final Map<String, Object?> noon = slots[12];
    expect(noon['text'], 'Bakery');
    expect(noon['status'], 'completed');
  });

  test('an empty hour carries no text and an empty status', () {
    final List<Map<String, Object?>> slots = slotsOf(
      WidgetPayload.build(
        now: DateTime(2026, 10, 30, 9, 15),
        entries: const <HourEntry>[],
      ),
    );

    expect(slots[10]['hour'], 10);
    expect(slots[10]['text'], '');
    expect(slots[10]['status'], 'empty');
  });
}
