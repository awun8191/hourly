import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract between the app and the Android widget.
///
/// The widget shows one hour: the current one. It cannot read Flutter's
/// `SharedPreferences` file, so the app sends this small JSON document through
/// `home_widget`, and the native provider renders it.
abstract final class WidgetPayload {
  static Map<String, Object?> build({
    required DateTime now,
    required List<HourEntry> entries,
  }) {
    final Map<int, HourEntry> byHour = <int, HourEntry>{
      for (final HourEntry entry in entries) entry.hour: entry,
    };
    final HourEntry? entry = byHour[now.hour];
    return <String, Object?>{
      'date': DateKey.of(now),
      'day': _dayLabel(now),
      'hour': now.hour,
      'label': DateKey.hourLabel(now.hour),
      'text': entry?.text ?? '',
      'status': entry?.status.name ?? 'empty',
      'minutesLeft': 60 - now.minute,
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
