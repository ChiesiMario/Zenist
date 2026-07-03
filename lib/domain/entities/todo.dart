class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
