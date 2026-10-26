import 'package:equatable/equatable.dart';

/// A single to-do item. Instances are immutable.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.isDone = false,
    this.dueDate,
  });

  final String id;
  final String title;
  final String notes;
  final bool isDone;
  final DateTime createdAt;

  /// Date-only due date. The time part is always midnight.
  final DateTime? dueDate;

  /// True when the due date is before today and the task is still open.
  bool isOverdueAt(DateTime now) {
    final DateTime? due = dueDate;
    if (isDone || due == null) {
      return false;
    }
    final DateTime today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  Task copyWith({
    String? title,
    String? notes,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, title, notes, isDone, createdAt, dueDate];
}
