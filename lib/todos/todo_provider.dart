import 'package:cm_sample/todos/todo.dart';
import 'package:flutter/cupertino.dart';

class TodoProvider with ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => _todos.toList();

  List<Todo> get completedTodos => _todos.where((todo) => todo.isCompleted).toList();

  List<Todo> get activeTodos => _todos.where((todo) => !todo.isCompleted).toList();

  void addTodo(String title) {
    _todos.add(Todo(title: title));
    notifyListeners();
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(isCompleted: !_todos[index].isCompleted);
      notifyListeners();
    }
  }

  void deleteTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  void updateTodo(String id, String newTitle) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(title: newTitle);
      notifyListeners();
    }
  }
}