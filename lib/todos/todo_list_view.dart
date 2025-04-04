import 'package:cm_sample/todos/todo.dart';
import 'package:cm_sample/todos/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//changing for fun
class TodoListView extends StatelessWidget {
  final List<Todo> todos;

  const TodoListView({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Center(
        child: Text('No todos found'),
      );
    }

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) => TodoItem(todo: todos[index]),
    );
  }
}

class TodoItem extends StatefulWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  late TextEditingController _textController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.todo.title);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.todo.id),
      background: Container(color: Colors.red),
      onDismissed: (_) => context.read<TodoProvider>().deleteTodo(widget.todo.id),
      child: ListTile(
        leading: Checkbox(
          value: widget.todo.isCompleted,
          onChanged: (_) => context.read<TodoProvider>().toggleTodo(widget.todo.id),
        ),
        title: _isEditing
            ? TextField(
          controller: _textController,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<TodoProvider>().updateTodo(widget.todo.id, value.trim());
            }
            setState(() => _isEditing = false);
          },
        )
            : Text(
          widget.todo.title,
          style: widget.todo.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        trailing: _isEditing
            ? null
            : IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => setState(() => _isEditing = true),
        ),
      ),
    );
  }
}