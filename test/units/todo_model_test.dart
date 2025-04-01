@Tags(['units'])
import 'package:cm_sample/todos/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo Model', () {
    test('should create todo with default values', () {
      final todo = Todo(title: 'Test Todo');

      expect(todo.title, 'Test Todo');
      expect(todo.isCompleted, false);
      expect(todo.id, isNotEmpty);
      expect(todo.createdAt, isA<DateTime>());
    });

    test('should create todo with custom values', () {
      final customTime = DateTime(2023, 1, 1);
      final todo = Todo(
        title: 'Custom Todo',
        isCompleted: true,
        id: 'custom-id',
        createdAt: customTime,
      );

      expect(todo.title, 'Custom Todo');
      expect(todo.isCompleted, true);
      expect(todo.id, 'custom-id');
      expect(todo.createdAt, customTime);
    });

    test('copyWith should update specified fields', () {
      final original = Todo(title: 'Original');
      final updated = original.copyWith(
        title: 'Updated',
        isCompleted: true,
      );

      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith should keep original values when not specified', () {
      final original = Todo(title: 'Original', isCompleted: true);
      final updated = original.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true); // Keeps original value
    });
  });
}