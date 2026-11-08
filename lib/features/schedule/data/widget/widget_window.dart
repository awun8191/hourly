import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';

/// Today only, for the widget's full-day list. The window resets at midnight
/// by itself because every slot carries its own date.
abstract final class WidgetWindow {
  static Future<List<HourEntry>> collect(
    ScheduleRepository repository,
    DateTime now,
  ) {
    return repository.fetchDay(DateKey.of(now));
  }
}
