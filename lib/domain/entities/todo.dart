class Subtask {
  final String id;
  final String title;
  final bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final bool isAnytime;
  final DateTime? completedAt;
  final int? repeatInterval;
  final String? repeatUnit;
  final List<Subtask> subtasks;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.isAnytime = false,
    this.completedAt,
    this.repeatInterval,
    this.repeatUnit,
    this.subtasks = const [],
  });

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? dueDate,
    bool? isAnytime,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearDueDate = false,
    int? repeatInterval,
    String? repeatUnit,
    bool clearRepeat = false,
    List<Subtask>? subtasks,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isAnytime: isAnytime ?? this.isAnytime,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      repeatInterval: clearRepeat ? null : (repeatInterval ?? this.repeatInterval),
      repeatUnit: clearRepeat ? null : (repeatUnit ?? this.repeatUnit),
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
