import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos({bool includeDeleted = false});
  Stream<List<Todo>> watchTodos({bool includeDeleted = false});
  Future<void> saveTodo(Todo todo);
  Future<void> deleteTodo(String id); // 執行軟刪除 (Soft Delete)
}
