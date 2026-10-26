import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../models/hour_entry_mapper.dart';

/// Stores one JSON document per day under `hours.v1.<yyyy-MM-dd>`.
///
/// A document maps the hour number to its entry. A read or a write touches one
/// day only, which keeps the widget update cheap.
class ScheduleLocalRepository implements ScheduleRepository {
  ScheduleLocalRepository(this._preferences);

  final SharedPreferences _preferences;

  /// Serializes writes so two fast taps cannot interleave a read and a write.
  Future<void> _tail = Future<void>.value();

  static String keyFor(String dateKey) => 'hours.v1.$dateKey';

  @override
  Future<List<HourEntry>> fetchDay(String dateKey) async {
    final Map<String, Object?> day = _readDay(dateKey);
    final List<HourEntry> entries = <HourEntry>[];
    for (final MapEntry<String, Object?> row in day.entries) {
      final int? hour = int.tryParse(row.key);
      if (hour == null || hour < 0 || hour > 23) {
        continue;
      }
      final HourEntry? entry = HourEntryMapper.fromJson(dateKey, hour, row.value);
      if (entry != null) {
        entries.add(entry);
      }
    }
    entries.sort((HourEntry a, HourEntry b) => a.hour.compareTo(b.hour));
    return entries;
  }

  @override
  Future<void> upsert(HourEntry entry) {
    return _enqueue(() async {
      final Map<String, Object?> day = _readDay(entry.dateKey);
      day[entry.hour.toString()] = HourEntryMapper.toJson(entry);
      await _writeDay(entry.dateKey, day);
    });
  }

  @override
  Future<void> delete(String dateKey, int hour) {
    return _enqueue(() async {
      final Map<String, Object?> day = _readDay(dateKey);
      if (day.remove(hour.toString()) == null) {
        return;
      }
      if (day.isEmpty) {
        await _preferences.remove(keyFor(dateKey));
        return;
      }
      await _writeDay(dateKey, day);
    });
  }

  Map<String, Object?> _readDay(String dateKey) {
    final String? raw = _preferences.getString(keyFor(dateKey));
    if (raw == null || raw.trim().isEmpty) {
      return <String, Object?>{};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ScheduleStorageException('The saved day is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ScheduleStorageException('The saved day is not a JSON object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<void> _writeDay(String dateKey, Map<String, Object?> day) async {
    final bool saved = await _preferences.setString(keyFor(dateKey), jsonEncode(day));
    if (!saved) {
      throw const ScheduleStorageException('The day could not be saved.');
    }
  }

  Future<void> _enqueue(Future<void> Function() job) {
    final Future<void> run = _tail.then((_) => job());
    _tail = run.catchError((Object _) {});
    return run;
  }
}
