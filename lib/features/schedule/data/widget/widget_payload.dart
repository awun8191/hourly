import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

/// Data contract between the app and the Android widget.
///
/// The widget shows the live hour as a card, then the next few hours as fields
/// the user can tap and fill. It cannot read Flutter's `SharedPreferences`
/// file, so the app sends this small JSON document through `home_widget`.
abstract final class WidgetPayload {
  /// Hour fields after the live card. Three fit a 4x3 cell.
  static const int upcomingHours = 3;

  static Map<String, Object?> build({
    required DateTime now,
    required List<HourEntry> entries,
  }) {
    final Map<int, HourEntry> byHour = <int, HourEntry>{
      for (final HourEntry entry in entries) entry.hour: entry,
    };
    final HourEntry? entry = byHour[now.hour];

    final List<Map<String, Object?>> upcoming = <Map<String, Object?>>[];
    for (int i = 1; i <= upcomingHours; i++) {
      final int hour = now.hour + i;
      if (hour > 23) {
        break;
      }
      final HourEntry? next = byHour[hour];
      upcoming.add(<String, Object?>{
        'hour': hour,
        'label': DateKey.hourLabel(hour),
        'text': next?.text ?? '',
        'status': next?.status.name ?? 'empty',
      });
    }

    return <String, Object?>{
      'date': DateKey.of(now),
      'day': _dayLabel(now),
      'hour': now.hour,
      'label': DateKey.hourLabel(now.hour),
      'text': entry?.text ?? '',
      'status': entry?.status.name ?? 'empty',
      'minutesLeft': 60 - now.minute,
      'upcoming': upcoming,
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
