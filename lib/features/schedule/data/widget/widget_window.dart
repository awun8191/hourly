import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';

/// Today and tomorrow, for the widget's rolling window across midnight.
abstract final class WidgetWindow {
  static Future<List<HourEntry>> collect(
    ScheduleRepository repository,
    DateTime now,
  ) async {
    final List<HourEntry> entries = await repository.fetchDay(DateKey.of(now));
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    try {
      entries.addAll(await repository.fetchDay(DateKey.of(tomorrow)));
    } on Object {
      // Tomorrow is optional. Today still paints.
    }
    return entries;
  }
}
