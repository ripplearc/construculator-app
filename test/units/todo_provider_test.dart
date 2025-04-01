@Tags(['units'])
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  late TodoProvider provider;

  setUp(() {
    provider = TodoProvider();
  });

  group('TodoProvider', () {
    test('initial state should have empty todos', () {
      expect(provider.todos, isEmpty);
      expect(provider.activeTodos, isEmpty);
      expect(provider.completedTodos, isEmpty);
    });

    test('addTodo should add new todo', () {
      provider.addTodo('New Todo');

      expect(provider.todos.length, 1);
      expect(provider.todos[0].title, 'New Todo');
      expect(provider.todos[0].isCompleted, false);
    });

    test('toggleTodo should change completion status', () {
      provider.addTodo('Toggle Test');
      final id = provider.todos[0].id;

      // Toggle to completed
      provider.toggleTodo(id);
      expect(provider.todos[0].isCompleted, true);
      expect(provider.completedTodos.length, 1);
      expect(provider.activeTodos.length, 0);

      // Toggle back to active
      provider.toggleTodo(id);
      expect(provider.todos[0].isCompleted, false);
      expect(provider.completedTodos.length, 0);
      expect(provider.activeTodos.length, 1);
    });

    test('toggleTodo should do nothing for invalid id', () {
      provider.addTodo('Test');
      final initialCount = provider.todos.length;

      provider.toggleTodo('invalid-id');

      expect(provider.todos.length, initialCount);
    });

    test('deleteTodo should remove todo', () {
      provider.addTodo('To Delete');
      final id = provider.todos[0].id;

      provider.deleteTodo(id);

      expect(provider.todos, isEmpty);
    });

    test('deleteTodo should do nothing for invalid id', () {
      provider.addTodo('Test');
      final initialCount = provider.todos.length;

      provider.deleteTodo('invalid-id');

      expect(provider.todos.length, initialCount);
    });

    test('updateTodo should change title', () {
      provider.addTodo('Old Title');
      final id = provider.todos[0].id;

      provider.updateTodo(id, 'New Title');

      expect(provider.todos[0].title, 'New Title');
    });

    test('updateTodo should do nothing for invalid id', () {
      provider.addTodo('Original');
      final originalTitle = provider.todos[0].title;

      provider.updateTodo('invalid-id', 'New Title');

      expect(provider.todos[0].title, originalTitle);
    });

    test('completedTodos should only return completed todos', () {
      provider.addTodo('Active 1');
      provider.addTodo('Active 2');
      provider.addTodo('Completed 1');
      provider.addTodo('Completed 2');

      // Complete last two todos
      provider.toggleTodo(provider.todos[2].id);
      provider.toggleTodo(provider.todos[3].id);

      expect(provider.completedTodos.length, 2);
      expect(provider.completedTodos[0].title, 'Completed 1');
      expect(provider.completedTodos[1].title, 'Completed 2');
    });

    test('activeTodos should only return active todos', () {
      provider.addTodo('Active 1');
      provider.addTodo('Active 2');
      provider.addTodo('Completed');

      // Complete last todo
      provider.toggleTodo(provider.todos[2].id);

      expect(provider.activeTodos.length, 2);
      expect(provider.activeTodos[0].title, 'Active 1');
      expect(provider.activeTodos[1].title, 'Active 2');
    });

    test('should notify listeners on changes', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.addTodo('Test');

      expect(notified, true);
    });
  });
}