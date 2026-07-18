class Subtask {
  final String id;
  final String title;
  final bool isCompleted;

  Subtask({required this.id, required this.title, this.isCompleted = false});

  Subtask copyWith({String? id, String? title, bool? isCompleted}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
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
  final List<DateTime> completionHistory;

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
    this.completionHistory = const [],
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
    List<DateTime>? completionHistory,
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
      repeatInterval: clearRepeat
          ? null
          : (repeatInterval ?? this.repeatInterval),
      repeatUnit: clearRepeat ? null : (repeatUnit ?? this.repeatUnit),
      subtasks: subtasks ?? this.subtasks,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'isDeleted': isDeleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'isAnytime': isAnytime,
    'completedAt': completedAt?.toIso8601String(),
    'repeatInterval': repeatInterval,
    'repeatUnit': repeatUnit,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'completionHistory': completionHistory.map((d) => d.toIso8601String()).toList(),
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isAnytime: json['isAnytime'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      repeatInterval: json['repeatInterval'] as int?,
      repeatUnit: json['repeatUnit'] as String?,
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      completionHistory: (json['completionHistory'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }

  /// Handles completion of a repeating task.
  /// Returns a new [Todo] with the next due date and updated completion history.
  Todo completeRepeatInstance() {
    DateTime? nextDueDate;
    if (dueDate != null && repeatInterval != null && repeatUnit != null) {
      final interval = repeatInterval!;
      switch (repeatUnit) {
        case 'day':
          nextDueDate = dueDate!.add(Duration(days: interval));
          break;
        case 'week':
          nextDueDate = dueDate!.add(Duration(days: 7 * interval));
          break;
        case 'month':
          nextDueDate = DateTime(
            dueDate!.year,
            dueDate!.month + interval,
            dueDate!.day,
            dueDate!.hour,
            dueDate!.minute,
          );
          break;
        case 'year':
          nextDueDate = DateTime(
            dueDate!.year + interval,
            dueDate!.month,
            dueDate!.day,
            dueDate!.hour,
            dueDate!.minute,
          );
          break;
      }
    }

    return copyWith(
      isCompleted: false, // Keep it incomplete to spawn next
      updatedAt: DateTime.now(),
      dueDate: nextDueDate, // Advance due date
      completionHistory: [...completionHistory, DateTime.now()], // Record completion
    );
  }

  /// Handles undoing a completion of a repeating task.
  /// Returns a new [Todo] with the previous due date and updated completion history.
  Todo undoRepeatInstance(DateTime historyDate) {
    // Remove the historyDate from completionHistory
    final newHistory = completionHistory.where((d) => d != historyDate).toList();

    // Revert dueDate backwards
    DateTime? previousDueDate;
    if (dueDate != null && repeatInterval != null && repeatUnit != null) {
      final interval = repeatInterval!;
      switch (repeatUnit) {
        case 'day':
          previousDueDate = dueDate!.subtract(Duration(days: interval));
          break;
        case 'week':
          previousDueDate = dueDate!.subtract(Duration(days: 7 * interval));
          break;
        case 'month':
          previousDueDate = DateTime(
            dueDate!.year,
            dueDate!.month - interval,
            dueDate!.day,
            dueDate!.hour,
            dueDate!.minute,
          );
          break;
        case 'year':
          previousDueDate = DateTime(
            dueDate!.year - interval,
            dueDate!.month,
            dueDate!.day,
            dueDate!.hour,
            dueDate!.minute,
          );
          break;
      }
    } else {
      previousDueDate = dueDate;
    }

    return copyWith(
      dueDate: previousDueDate,
      completionHistory: newHistory,
      updatedAt: DateTime.now(),
    );
  }
}
