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
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      isAnytime: isAnytime ?? this.isAnytime,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
