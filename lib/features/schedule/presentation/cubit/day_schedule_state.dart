import 'package:equatable/equatable.dart';

import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';

enum ScheduleStatus { initial, loading, ready, failure }

/// Immutable state of one day.
class DayScheduleState extends Equatable {
  const DayScheduleState({
    required this.day,
    this.entries = const <int, HourEntry>{},
    this.status = ScheduleStatus.initial,
    this.errorMessage,
  });

  /// Local date at midnight.
  final DateTime day;

  /// Entry for each filled hour. An absent hour is empty.
  final Map<int, HourEntry> entries;

  final ScheduleStatus status;
  final String? errorMessage;

  HourEntry? entryAt(int hour) => entries[hour];

  int get filledCount => entries.length;

  int get doneCount => entries.values.where((HourEntry entry) => entry.isCompleted).length;

  int get activeCount => filledCount - doneCount;

  double get progress => filledCount == 0 ? 0 : doneCount / filledCount;

  bool get isComplete => filledCount > 0 && doneCount == filledCount;

  bool isTodayAt(DateTime now) => DateKey.isSameDay(day, now);

  DayScheduleState copyWith({
    DateTime? day,
    Map<int, HourEntry>? entries,
    ScheduleStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DayScheduleState(
      day: day ?? this.day,
      entries: entries ?? this.entries,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[day, entries, status, errorMessage];
}
