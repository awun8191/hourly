import 'package:equatable/equatable.dart';

/// State of one hour block.
///
/// The app uses the user's mapping: [active] is green (the item is in place),
/// [completed] is red (the item is done).
enum HourStatus { active, completed }

/// One item in one hour block of one day.
class HourEntry extends Equatable {
  const HourEntry({
    required this.dateKey,
    required this.hour,
    required this.text,
    required this.updatedAt,
    this.status = HourStatus.active,
  });

  /// Local day, `yyyy-MM-dd`.
  final String dateKey;

  /// 0 to 23.
  final int hour;

  final String text;
  final HourStatus status;
  final DateTime updatedAt;

  bool get isCompleted => status == HourStatus.completed;

  HourEntry copyWith({
    String? text,
    HourStatus? status,
    DateTime? updatedAt,
  }) {
    return HourEntry(
      dateKey: dateKey,
      hour: hour,
      text: text ?? this.text,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[dateKey, hour, text, status, updatedAt];
}
