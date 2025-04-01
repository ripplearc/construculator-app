import 'package:cm_sample/todos/todo_list_view.dart';
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo App'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TodoListView(todos: context.watch<TodoProvider>().todos),
            TodoListView(todos: context.watch<TodoProvider>().activeTodos),
            TodoListView(todos: context.watch<TodoProvider>().completedTodos),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTodoDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter todo title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                context.read<TodoProvider>().addTodo(textController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}