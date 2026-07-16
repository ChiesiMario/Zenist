import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../data/datasources/local/isar_datasource.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../application/services/auto_sync_manager.dart';
import '../../application/services/audio_service.dart';

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

  Future<void> addTodo(
    String title, {
    String description = '',
    DateTime? dueDate,
    bool isAnytime = false,
    int? repeatInterval,
    String? repeatUnit,
    List<Subtask> subtasks = const [],
  }) async {
    if (title.trim().isEmpty) return;

    final repository = ref.read(todoRepositoryProvider);
    final todo = Todo(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: dueDate,
      isAnytime: isAnytime,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      subtasks: subtasks,
    );
    await repository.saveTodo(todo);
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }

  Future<void> toggleTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);

    if (!todo.isCompleted &&
        todo.repeatInterval != null &&
        todo.repeatUnit != null &&
        !todo.isAnytime) {
      DateTime? nextDueDate;
      if (todo.dueDate != null) {
        final interval = todo.repeatInterval!;
        switch (todo.repeatUnit) {
          case 'day':
            nextDueDate = todo.dueDate!.add(Duration(days: interval));
            break;
          case 'week':
            nextDueDate = todo.dueDate!.add(Duration(days: 7 * interval));
            break;
          case 'month':
            nextDueDate = DateTime(
              todo.dueDate!.year,
              todo.dueDate!.month + interval,
              todo.dueDate!.day,
              todo.dueDate!.hour,
              todo.dueDate!.minute,
            );
            break;
          case 'year':
            nextDueDate = DateTime(
              todo.dueDate!.year + interval,
              todo.dueDate!.month,
              todo.dueDate!.day,
              todo.dueDate!.hour,
              todo.dueDate!.minute,
            );
            break;
        }
      }

      final nextTodo = Todo(
        id: const Uuid().v4(),
        title: todo.title,
        description: todo.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: nextDueDate,
        isAnytime: todo.isAnytime,
        repeatInterval: todo.repeatInterval,
        repeatUnit: todo.repeatUnit,
        subtasks: todo.subtasks
            .map((s) => s.copyWith(isCompleted: false))
            .toList(),
      );
      await repository.saveTodo(nextTodo);

      final updatedTodo = todo.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
        clearRepeat: true,
      );
      await repository.saveTodo(updatedTodo);
      ref.read(audioServiceProvider).playTaskCompleteSound();
      ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
      return;
    }

    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: DateTime.now(),
      completedAt: !todo.isCompleted ? DateTime.now() : null,
      clearCompletedAt: todo.isCompleted,
    );
    await repository.saveTodo(updatedTodo);
    if (!todo.isCompleted) {
      ref.read(audioServiceProvider).playTaskCompleteSound();
    }
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }

  Future<void> deleteTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.deleteTodo(id); // 觸發軟刪除
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }

  Future<void> updateTodoTitle(Todo todo, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final repository = ref.read(todoRepositoryProvider);
    final updatedTodo = todo.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(updatedTodo);
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }

  Future<void> updateTodoDetails(
    Todo todo,
    String newTitle,
    DateTime? newDueDate, {
    String description = '',
    bool isAnytime = false,
    int? repeatInterval,
    String? repeatUnit,
    List<Subtask>? newSubtasks,
  }) async {
    if (newTitle.trim().isEmpty) return;
    final repository = ref.read(todoRepositoryProvider);
    final updatedTodo = todo.copyWith(
      title: newTitle.trim(),
      description: description,
      dueDate: newDueDate,
      clearDueDate: newDueDate == null,
      isAnytime: isAnytime,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      clearRepeat: repeatInterval == null || repeatUnit == null,
      subtasks: newSubtasks ?? todo.subtasks,
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(updatedTodo);
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }

  Future<void> toggleSubtask(Todo todo, String subtaskId) async {
    final repository = ref.read(todoRepositoryProvider);
    bool justCompleted = false;
    final updatedSubtasks = todo.subtasks.map((s) {
      if (s.id == subtaskId) {
        justCompleted = !s.isCompleted;
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final updatedTodo = todo.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(updatedTodo);
    if (justCompleted) {
      ref.read(audioServiceProvider).playTaskCompleteSound();
    }
    ref.read(autoSyncManagerProvider.notifier).scheduleSyncAfterMutation();
  }
}
