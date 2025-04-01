import 'package:uuid/uuid.dart';

class Todo {
  final String id;
  final String title;
  bool isCompleted;
  final DateTime createdAt;

  Todo({
    required this.title,
    this.isCompleted = false,
    String? id,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}