import 'package:isar/isar.dart';
import '../../domain/entities/todo.dart';

part 'todo_model.g.dart';

@collection
class TodoModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;
  
  late String title;
  late String description;
  late bool isCompleted;
  late bool isDeleted;
  late DateTime createdAt;
  late DateTime updatedAt;

  // 從 Entity 轉換為 Isar 支援的 Model
  static TodoModel fromEntity(Todo entity) {
    return TodoModel()
      ..uuid = entity.id
      ..title = entity.title
      ..description = entity.description
      ..isCompleted = entity.isCompleted
      ..isDeleted = entity.isDeleted
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }

  // 將 Isar Model 轉換為 Domain 核心的 Entity
  Todo toEntity() {
    return Todo(
      id: uuid,
      title: title,
      description: description,
      isCompleted: isCompleted,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
