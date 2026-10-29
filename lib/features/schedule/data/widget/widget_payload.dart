import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract between the app and the Android widget.
///
/// The widget cannot read Flutter's `SharedPreferences` file, so the app sends
/// it a small JSON document through `home_widget`, and the native provider
/// renders that document.
abstract final class WidgetPayload {
  /// Rows the widget may show: the current hour and the next four.
  static const int maxSlots = 5;

  static Map<String, Object?> build({
    required DateTime now,
    required List<HourEntry> entries,
  }) {
    final Map<int, HourEntry> byHour = <int, HourEntry>{
      for (final HourEntry entry in entries) entry.hour: entry,
    };
    final int count = (24 - now.hour).clamp(1, maxSlots);
    final List<Map<String, Object?>> slots = <Map<String, Object?>>[];
    for (int i = 0; i < count; i++) {
      final int hour = now.hour + i;
      final HourEntry? entry = byHour[hour];
      slots.add(<String, Object?>{
        'hour': hour,
        'label': DateKey.hourLabel(hour),
        'text': entry?.text ?? '',
        'status': entry?.status.name ?? 'empty',
      });
    }
    final int done = entries.where((HourEntry entry) => entry.isCompleted).length;
    final int total = entries.length;

    return <String, Object?>{
      'date': DateKey.of(now),
      'day': _dayLabel(now),
      'done': done,
      'total': total,
      // The live hour, so the widget can draw its progress without a timer.
      'minutesIntoHour': now.minute,
      'minutesLeft': 60 - now.minute,
      'hourPercent': (now.minute * 100 / 60).round(),
      'dayPercent': total == 0 ? 0 : (done * 100 / total).round(),
      'next': _nextSlot(slots),
      'slots': slots,
    };
  }

  /// The first planned hour after the live one, or null when the rest of the
  /// visible window is empty. It reuses the slot map so both sides share one
  /// shape.
  static Map<String, Object?>? _nextSlot(List<Map<String, Object?>> slots) {
    for (int i = 1; i < slots.length; i++) {
      if (slots[i]['status'] != 'empty') {
        return slots[i];
      }
    }
    return null;
  }

  static String _dayLabel(DateTime now) {
    const List<String> names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${names[now.weekday - 1]} ${now.day}';
  }
}
