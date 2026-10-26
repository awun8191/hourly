import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';
import 'package:todo_app/features/schedule/domain/repositories/schedule_repository.dart';

/// In-memory [ScheduleRepository] for tests.
class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository([Map<String, List<HourEntry>> seed = const {}]) {
    seed.forEach((String dateKey, List<HourEntry> entries) {
      for (final HourEntry entry in entries) {
        (_days[dateKey] ??= <int, HourEntry>{})[entry.hour] = entry;
      }
    });
  }

  final Map<String, Map<int, HourEntry>> _days = <String, Map<int, HourEntry>>{};

  bool failOnRead = false;
  bool failOnWrite = false;
  int writes = 0;

  @override
  Future<List<HourEntry>> fetchDay(String dateKey) async {
    if (failOnRead) {
      throw const ScheduleStorageException('read failed');
    }
    final List<HourEntry> entries = (_days[dateKey] ?? <int, HourEntry>{})
        .values
        .toList(growable: false)
      ..sort((HourEntry a, HourEntry b) => a.hour.compareTo(b.hour));
    return entries;
  }

  @override
  Future<void> upsert(HourEntry entry) async {
    writes++;
    if (failOnWrite) {
      throw const ScheduleStorageException('write failed');
    }
    (_days[entry.dateKey] ??= <int, HourEntry>{})[entry.hour] = entry;
  }

  @override
  Future<void> delete(String dateKey, int hour) async {
    writes++;
    if (failOnWrite) {
      throw const ScheduleStorageException('write failed');
    }
    _days[dateKey]?.remove(hour);
  }

  Map<int, HourEntry> day(String dateKey) => _days[dateKey] ?? <int, HourEntry>{};
}
