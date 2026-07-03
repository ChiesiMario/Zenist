import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../data/datasources/local/isar_datasource.dart';
import '../../data/repositories/todo_repository_impl.dart';

final isarDataSourceProvider = Provider<IsarDataSource>((ref) {
  return IsarDataSource();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final dataSource = ref.watch(isarDataSourceProvider);
  return TodoRepositoryImpl(dataSource);
});

// 監聽 Isar 資料庫變更，自動更新 UI
final todoListStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.watchTodos(includeDeleted: false);
});

final todoNotifierProvider = NotifierProvider<TodoNotifier, void>(() {
  return TodoNotifier();
});

class TodoNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;
    
    final repository = ref.read(todoRepositoryProvider);
    final todo = Todo(
      id: const Uuid().v4(),
      title: title.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(todo);
  }

  Future<void> toggleTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(updatedTodo);
  }

  Future<void> deleteTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.deleteTodo(id); // 觸發軟刪除
  }
}
