import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract for the Android widget.
///
/// The widget shows a rolling window that starts at the live hour and runs
/// [slotCount] hours forward, across midnight. Each slot carries its own date,
/// so a row after midnight writes to the next day.
abstract final class WidgetPayload {
  static const int slotCount = 26;

  static Map<String, Object?> build({
    required DateTime now,
    required List<HourEntry> entries,
  }) {
    final Map<String, HourEntry> byKey = <String, HourEntry>{
      for (final HourEntry entry in entries) '${entry.dateKey}:${entry.hour}': entry,
    };
    final DateTime base = DateTime(now.year, now.month, now.day, now.hour);
    final String todayKey = DateKey.of(now);

    final List<Map<String, Object?>> slots = <Map<String, Object?>>[];
    for (int index = 0; index < slotCount; index++) {
      final DateTime moment = base.add(Duration(hours: index));
      final String dateKey = DateKey.of(moment);
      final HourEntry? entry = byKey['$dateKey:${moment.hour}'];
      slots.add(<String, Object?>{
        'date': dateKey,
        'hour': moment.hour,
        'label': DateKey.hourLabel(moment.hour),
        'text': entry?.text ?? '',
        'status': entry?.status.name ?? 'empty',
        'tomorrow': dateKey != todayKey,
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
