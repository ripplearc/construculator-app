@Tags(['screenshots'])
import 'package:cm_sample/main.dart';
import 'package:cm_sample/todos/todo_list_screen.dart';
import 'package:cm_sample/todos/todo_list_view.dart';
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Verify Initial Todo List UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TodoProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodoListScreen),
      matchesGoldenFile('golden/initial_todo_list.png'),
    );
  });

  testWidgets('Verify Todo List With Items', (WidgetTester tester) async {
    final provider = TodoProvider();
    provider.addTodo('Buy groceries');
    provider.addTodo('Walk the dog');
    provider.toggleTodo(provider.todos[1].id); // Complete second item

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodoListScreen),
      matchesGoldenFile('golden/todo_list_with_items.png'),
    );
  });

  testWidgets('Verify Active Todos Tab', (WidgetTester tester) async {
    final provider = TodoProvider();
    provider.addTodo('Active Item 1');
    provider.addTodo('Active Item 2');
    provider.addTodo('Completed Item');
    provider.toggleTodo(provider.todos[2].id);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ),
    );

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodoListScreen),
      matchesGoldenFile('golden/active_todos_tab.png'),
    );
  });

  testWidgets('Verify Completed Todos Tab', (WidgetTester tester) async {
    final provider = TodoProvider();
    provider.addTodo('Active Item');
    provider.addTodo('Completed Item 1');
    provider.addTodo('Completed Item 2');
    provider.toggleTodo(provider.todos[1].id);
    provider.toggleTodo(provider.todos[2].id);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ),
    );

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodoListScreen),
      matchesGoldenFile('golden/completed_todos_tab.png'),
    );
  });

  testWidgets('Verify Add Todo Dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TodoProvider(),
        child: const MyApp(),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AlertDialog),
      matchesGoldenFile('golden/add_todo_dialog.png'),
    );
  });

  testWidgets('Verify Todo Item Edit Mode', (WidgetTester tester) async {
    final provider = TodoProvider();
    provider.addTodo('Item to edit');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodoItem),
      matchesGoldenFile('golden/todo_item_edit_mode.png'),
    );
  });
}