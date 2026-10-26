import '../../domain/entities/hour_entry.dart';

/// JSON shape of one hour entry inside its day document.
abstract final class HourEntryMapper {
  static Map<String, Object?> toJson(HourEntry entry) {
    return <String, Object?>{
      'text': entry.text,
      'status': entry.status.name,
      'updatedAt': entry.updatedAt.toIso8601String(),
    };
  }

  /// Returns null when the record cannot be used.
  static HourEntry? fromJson(String dateKey, int hour, Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final Object? text = raw['text'];
    if (text is! String || text.trim().isEmpty) {
      return null;
    }
    final Object? status = raw['status'];
    return HourEntry(
      dateKey: dateKey,
      hour: hour,
      text: text,
      status: status == HourStatus.completed.name
          ? HourStatus.completed
          : HourStatus.active,
      updatedAt:
          DateTime.tryParse(raw['updatedAt'] is String ? raw['updatedAt'] as String : '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
