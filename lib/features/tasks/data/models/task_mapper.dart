import '../../domain/entities/task.dart';

/// Converts [Task] instances to and from the JSON shape used on disk.
abstract final class TaskMapper {
  static Map<String, dynamic> toJson(Task task) {
    return <String, dynamic>{
      'id': task.id,
      'title': task.title,
      'notes': task.notes,
      'isDone': task.isDone,
      'createdAt': task.createdAt.toIso8601String(),
      'dueDate': task.dueDate?.toIso8601String(),
    };
  }

  /// Returns null when the record lacks a usable id or title.
  static Task? fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? title = json['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    return Task(
      id: id,
      title: title,
      notes: json['notes'] is String ? json['notes'] as String : '',
      isDone: json['isDone'] is bool ? json['isDone'] as bool : false,
      createdAt:
          DateTime.tryParse(json['createdAt'] is String ? json['createdAt'] as String : '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueDate: DateTime.tryParse(json['dueDate'] is String ? json['dueDate'] as String : ''),
    );
  }
}
