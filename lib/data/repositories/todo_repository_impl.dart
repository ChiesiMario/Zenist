import 'package:isar/isar.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/local/isar_datasource.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final IsarDataSource dataSource;

  TodoRepositoryImpl(this.dataSource);

  @override
  Future<List<Todo>> getTodos({bool includeDeleted = false}) async {
    final isar = await dataSource.db;
    final query = isar.todoModels.where();
    
    final results = includeDeleted 
        ? await query.findAll()
        : await query.filter().isDeletedEqualTo(false).findAll();
        
    return results.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<List<Todo>> watchTodos({bool includeDeleted = false}) async* {
    final isar = await dataSource.db;
    final query = includeDeleted 
        ? isar.todoModels.where()
        : isar.todoModels.filter().isDeletedEqualTo(false);
        
    yield* query.watch(fireImmediately: true).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final isar = await dataSource.db;
    final model = TodoModel.fromEntity(todo);
    
    await isar.writeTxn(() async {
      await isar.todoModels.putByUuid(model);
    });
  }

  @override
  Future<void> deleteTodo(String id) async {
    // 實作軟刪除
    final isar = await dataSource.db;
    final existing = await isar.todoModels.getByUuid(id);
    if (existing != null) {
      existing.isDeleted = true;
      existing.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.todoModels.put(existing);
      });
    }
  }
}
