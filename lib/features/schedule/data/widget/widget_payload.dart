import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract between the app and the Android widget.
///
/// The widget cannot read Flutter's `SharedPreferences` file, so the app sends
/// it a small JSON document through `home_widget`, and the native provider
/// renders that document.
abstract final class WidgetPayload {
  /// Rows the widget shows: the current hour and the next four.
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
    return <String, Object?>{
      'date': DateKey.of(now),
      'day': _dayLabel(now),
      'done': entries.where((HourEntry entry) => entry.isCompleted).length,
      'total': entries.length,
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
