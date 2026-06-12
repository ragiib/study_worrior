// ============================================================================
// Task Model - Represents a study task with priority and due date
// ============================================================================

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  TaskPriority priority;
  DateTime? dueDate;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Database Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: TaskPriority.values[map['priority'] as int],
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }

  // Priority label for display
  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
