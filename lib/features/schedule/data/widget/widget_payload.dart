import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract for the Android widget.
///
/// The widget shows the whole of today, midnight to 23:00, in one scrollable
/// list. Each slot carries its own date so a tap writes to the right day, and
/// the window resets at midnight by itself.
abstract final class WidgetPayload {
  static const int firstHour = 0;
  static const int lastHour = 23;

  static Map<String, Object?> build({
    required DateTime now,
    required List<HourEntry> entries,
  }) {
    final Map<int, HourEntry> byHour = <int, HourEntry>{
      for (final HourEntry entry in entries) entry.hour: entry,
    };
    final String todayKey = DateKey.of(now);

    final List<Map<String, Object?>> slots = <Map<String, Object?>>[];
    for (int hour = firstHour; hour <= lastHour; hour++) {
      final HourEntry? entry = byHour[hour];
      slots.add(<String, Object?>{
        'date': todayKey,
        'hour': hour,
        'label': DateKey.hourLabel(hour),
        'text': entry?.text ?? '',
        'status': entry?.status.name ?? 'empty',
      });
    }

    return <String, Object?>{
      'date': todayKey,
      'day': _dayLabel(now),
      'hour': now.hour,
      'slots': slots,
    };
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
