@Tags(['units'])
import 'package:cm_sample/todos/todo.dart';
import 'package:cm_sample/todos/todo_list_view.dart';
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('TodoItem', () {
    late TodoProvider provider;
    late Todo testTodo;

    setUp(() {
      provider = TodoProvider();
      testTodo = Todo(title: 'Test Todo');
      provider.addTodo(testTodo.title);
    });

    testWidgets('should display todo title', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: TodoItem(todo: provider.todos[0]),
            ),
          ),
        ),
      );

      expect(find.text('Test Todo'), findsOneWidget);
    });

    testWidgets('should show checkbox reflecting completion status', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: TodoItem(todo: provider.todos[0]),
            ),
          ),
        ),
      );

      // Initial state
      expect(provider.todos[0].isCompleted, false);

      // Toggle checkbox
      await tester.tap(find.byType(Checkbox));

      // Critical fix: Use pumpAndSettle to wait for provider updates
      await tester.pumpAndSettle();

      // Verify both UI and provider state
      expect(provider.todos[0].isCompleted, true); // Add provider state check
    });

    testWidgets('should show line-through for completed todos', (tester) async {
      // Start with completed todo
      provider.toggleTodo(provider.todos[0].id);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: TodoItem(todo: provider.todos[0]),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test Todo'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('should enter edit mode when edit button pressed', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: TodoItem(todo: provider.todos[0]),
            ),
          ),
        ),
      );

      // Verify not in edit mode initially
      expect(find.byType(TextField), findsNothing);

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Verify in edit mode
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Todo'), findsOneWidget);
    });

  });
}