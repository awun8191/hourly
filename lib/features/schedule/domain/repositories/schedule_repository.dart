import '../entities/hour_entry.dart';

/// Boundary between the day schedule and its storage.
///
/// One document per day keeps a read and a write small. The widget and the app
/// use this same interface.
abstract interface class ScheduleRepository {
  /// Returns the entries of [dateKey], ordered by hour.
  Future<List<HourEntry>> fetchDay(String dateKey);

  /// Creates or replaces the entry for its (date, hour) slot.
  Future<void> upsert(HourEntry entry);

  /// Removes the entry in [dateKey] at [hour]. Missing entries are ignored.
  Future<void> delete(String dateKey, int hour);
}

/// Raised when the schedule store cannot be read or written.
class ScheduleStorageException implements Exception {
  const ScheduleStorageException(this.message);

  final String message;

  @override
  String toString() => 'ScheduleStorageException: $message';
}
