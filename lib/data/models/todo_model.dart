import 'package:isar/isar.dart';
import '../../domain/entities/todo.dart';

part 'todo_model.g.dart';

@embedded
class CompletionRecordModel {
  late DateTime completedAt;
  DateTime? expectedDueDate;

  static CompletionRecordModel fromEntity(CompletionRecord entity) {
    return CompletionRecordModel()
      ..completedAt = entity.completedAt
      ..expectedDueDate = entity.expectedDueDate;
  }

  CompletionRecord toEntity() {
    return CompletionRecord(
      completedAt: completedAt,
      expectedDueDate: expectedDueDate,
    );
  }
}

@embedded
class SubtaskModel {
  late String uuid;
  late String title;
  late bool isCompleted;

  static SubtaskModel fromEntity(Subtask entity) {
    return SubtaskModel()
      ..uuid = entity.id
      ..title = entity.title
      ..isCompleted = entity.isCompleted;
  }

  Subtask toEntity() {
    return Subtask(id: uuid, title: title, isCompleted: isCompleted);
  }
}

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
  DateTime? dueDate;
  late bool isAnytime;
  @Index()
  DateTime? completedAt;

  int? repeatInterval;
  String? repeatUnit;

  List<SubtaskModel>? subtasks;
  List<CompletionRecordModel>? historyRecords;

  // 從 Entity 轉換為 Isar 支援的 Model
  static TodoModel fromEntity(Todo entity) {
    return TodoModel()
      ..uuid = entity.id
      ..title = entity.title
      ..description = entity.description
      ..isCompleted = entity.isCompleted
      ..isDeleted = entity.isDeleted
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..dueDate = entity.dueDate
      ..isAnytime = entity.isAnytime
      ..completedAt = entity.completedAt
      ..repeatInterval = entity.repeatInterval
      ..repeatUnit = entity.repeatUnit
      ..subtasks = entity.subtasks
          .map((s) => SubtaskModel.fromEntity(s))
          .toList()
      ..historyRecords = entity.completionHistory
          .map((c) => CompletionRecordModel.fromEntity(c))
          .toList();
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
      dueDate: dueDate,
      isAnytime: isAnytime,
      completedAt: completedAt,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      subtasks: subtasks?.map((s) => s.toEntity()).toList() ?? [],
      completionHistory: historyRecords?.map((h) => h.toEntity()).toList() ?? [],
    );
  }
}
