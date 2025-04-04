@Tags(["widgets"])
import 'package:cm_sample/todos/todo_list_screen.dart';
import 'package:cm_sample/todos/todo_list_view.dart';
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Todo App Widget Tests', () {
    testWidgets('App starts with empty todo list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => TodoProvider(),
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      expect(find.text('No todos found'), findsOneWidget);
    });

    testWidgets('Add new todo through Fab', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => TodoProvider(),
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Enter text in dialog
      await tester.enterText(find.byType(TextField), 'Test Todo');
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Verify todo appears in list
      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.text('No todos found'), findsNothing);
    });

    testWidgets('Toggle todo completion', (WidgetTester tester) async {
      final provider = TodoProvider();
      provider.addTodo('Test Todo');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      // Verify initial state
      expect(find.text('Test Todo'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Verify updated state
      final updatedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(updatedCheckbox.value, isTrue);
      expect(find.text('Test Todo'), findsOneWidget);
    });

    testWidgets('Delete todo by swiping', (WidgetTester tester) async {
      final provider = TodoProvider();
      provider.addTodo('Test Todo');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      expect(find.text('Test Todo'), findsOneWidget);

      // Swipe to dismiss
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Test Todo'), findsNothing);
    });

    testWidgets('Edit todo title', (WidgetTester tester) async {
      final provider = TodoProvider();
      provider.addTodo('Test Todo');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Verify edit mode
      expect(find.byType(TextField), findsOneWidget);

      // Edit text
      await tester.enterText(find.byType(TextField), 'Updated Todo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify update
      expect(find.text('Updated Todo'), findsOneWidget);
      expect(find.text('Test Todo'), findsNothing);
    });

    testWidgets('Tab navigation', (WidgetTester tester) async {
      final provider = TodoProvider();
      provider.addTodo('Active Todo');
      provider.addTodo('Completed Todo');
      provider.toggleTodo(provider.todos[1].id); // Complete second todo

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );

      // Initial verification (All tab)
      expect(find.text('Active Todo'), findsOneWidget);
      expect(find.text('Completed Todo'), findsOneWidget);

      // Switch to Active tab with proper animation handling
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle(); // Changed from pump()

      // Verify active todos
      expect(find.text('Active Todo'), findsOneWidget);
      expect(find.byType(TodoItem), findsOneWidget); // Added count verification
      expect(find.text('Completed Todo'), findsNothing);

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle(); // Changed from pump()

      // Verify completed todos
      expect(find.text('Completed Todo'), findsOneWidget);
      expect(find.byType(TodoItem), findsOneWidget);
      expect(find.text('Active Todo'), findsNothing);

      // Return to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Verify all todos
      expect(find.byType(TodoItem), findsNWidgets(2));
      expect(find.text('Active Todo'), findsOneWidget);
      expect(find.text('Completed Todo'), findsOneWidget);
    });
  });
}