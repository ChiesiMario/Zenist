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

// A custom class to hold the separated todos for a specific tab
class FilteredTodos {
  final List<Todo> uncompleted;
  final List<Todo> completedToday;
  
  FilteredTodos({required this.uncompleted, required this.completedToday});
}

// A provider that filters and sorts todos based on the current tab index
final filteredTodosProvider = Provider.family<AsyncValue<FilteredTodos>, int>((ref, tabIndex) {
  final todosAsync = ref.watch(todoListStreamProvider);
  
  return todosAsync.whenData((allTodos) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final uncompletedTodos = <Todo>[];
    final completedTodayTodos = <Todo>[];

    for (final todo in allTodos) {
      if (!todo.isCompleted) {
        // Extract historical completions for repeating tasks
        if (tabIndex == 0 && todo.completionHistory.isNotEmpty) {
          for (final historyDate in todo.completionHistory) {
            if (!historyDate.isBefore(todayStart) && historyDate.isBefore(todayEnd)) {
              completedTodayTodos.add(todo.copyWith(isCompleted: true, completedAt: historyDate));
            }
          }
        }

        bool matchesTab = false;
        if (tabIndex == 0) {
          // 今天
          if (todo.dueDate != null && !todo.isAnytime) {
            if (todo.dueDate!.isBefore(todayEnd)) {
              matchesTab = true; // 過期或今天之內
            }
          }
        } else if (tabIndex == 1) {
          // 未來
          if (todo.dueDate != null &&
              !todo.isAnytime &&
              todo.dueDate!.isAfter(todayEnd.subtract(const Duration(milliseconds: 1)))) {
            matchesTab = true;
          }
        } else if (tabIndex == 2) {
          // 某天
          if (todo.dueDate == null && !todo.isAnytime) matchesTab = true;
        } else if (tabIndex == 3) {
          // 隨時
          if (todo.isAnytime) matchesTab = true;
        }

        if (matchesTab) {
          uncompletedTodos.add(todo);
        }
      } else {
        // 已完成的任務
        if (tabIndex == 0) {
          // 在「今天」標籤，顯示所有今天打勾完成的任務（戰利品）
          if (todo.completedAt != null &&
              !todo.completedAt!.isBefore(todayStart) &&
              todo.completedAt!.isBefore(todayEnd)) {
            completedTodayTodos.add(todo);
          }
        }
      }
    }

    int compareTodos(Todo a, Todo b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1; // a has due date, b doesn't -> a comes first
      } else if (b.dueDate != null) {
        return 1; // b has due date, a doesn't -> b comes first
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    }

    uncompletedTodos.sort(compareTodos);
    completedTodayTodos.sort((a, b) {
      if (a.completedAt != null && b.completedAt != null) {
        return a.completedAt!.compareTo(b.completedAt!);
      }
      return compareTodos(a, b);
    });

    return FilteredTodos(
      uncompleted: uncompletedTodos,
      completedToday: completedTodayTodos,
    );
  });
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

  }

  Future<void> toggleTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);

    if (!todo.isCompleted &&
        todo.repeatInterval != null &&
        todo.repeatUnit != null &&
        !todo.isAnytime) {
      final updatedTodo = todo.completeRepeatInstance();
      await repository.saveTodo(updatedTodo);
  
      return;
    }

    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: DateTime.now(),
      completedAt: !todo.isCompleted ? DateTime.now() : null,
      clearCompletedAt: todo.isCompleted,
    );
    await repository.saveTodo(updatedTodo);

  }

  Future<void> undoRepeatCompletion(String todoId, DateTime historyDate) async {
    final repository = ref.read(todoRepositoryProvider);
    final todo = await repository.getTodo(todoId);
    if (todo == null) return;

    final updatedTodo = todo.undoRepeatInstance(historyDate);
    await repository.saveTodo(updatedTodo);
  }

  Future<void> deleteTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.deleteTodo(id); // 觸發軟刪除

  }

  Future<void> updateTodoTitle(Todo todo, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final repository = ref.read(todoRepositoryProvider);
    final updatedTodo = todo.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await repository.saveTodo(updatedTodo);

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

  }
}
