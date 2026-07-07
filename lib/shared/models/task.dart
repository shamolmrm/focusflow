enum TaskCategory { work, health, learning, breakTime, personal }

enum TaskPriority { high, medium, low }

class ScheduledTask {
  final String id;
  final String time;
  final String task;
  final int durationMinutes;
  final TaskCategory category;
  final TaskPriority priority;
  final bool isCompleted;
  final bool isLive;

  const ScheduledTask({
    required this.id,
    required this.time,
    required this.task,
    required this.durationMinutes,
    required this.category,
    required this.priority,
    this.isCompleted = false,
    this.isLive = false,
  });

  ScheduledTask copyWith({
    String? id,
    String? time,
    String? task,
    int? durationMinutes,
    TaskCategory? category,
    TaskPriority? priority,
    bool? isCompleted,
    bool? isLive,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      time: time ?? this.time,
      task: task ?? this.task,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isLive: isLive ?? this.isLive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'task': task,
        'duration_minutes': durationMinutes,
        'category': _categoryName(category),
        'priority': _priorityName(priority),
        'isCompleted': isCompleted,
        'isLive': isLive,
      };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: json['time'] as String? ?? '09:00',
      task: json['task'] as String? ?? 'Task',
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      category: _parseCategory(json['category'] as String? ?? 'work'),
      priority: _parsePriority(json['priority'] as String? ?? 'medium'),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isLive: json['isLive'] as bool? ?? false,
    );
  }

  static String _categoryName(TaskCategory c) {
    switch (c) {
      case TaskCategory.work:
        return 'work';
      case TaskCategory.health:
        return 'health';
      case TaskCategory.learning:
        return 'learning';
      case TaskCategory.breakTime:
        return 'break';
      case TaskCategory.personal:
        return 'personal';
    }
  }

  static String _priorityName(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static TaskCategory _parseCategory(String v) {
    switch (v.toLowerCase()) {
      case 'work':
        return TaskCategory.work;
      case 'health':
        return TaskCategory.health;
      case 'learning':
        return TaskCategory.learning;
      case 'break':
        return TaskCategory.breakTime;
      default:
        return TaskCategory.personal;
    }
  }

  static TaskPriority _parsePriority(String v) {
    switch (v.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.breakTime:
        return 'Break';
      case TaskCategory.personal:
        return 'Personal';
    }
  }

  int get categoryColorValue {
    switch (category) {
      case TaskCategory.work:
        return 0xFF534AB7;
      case TaskCategory.health:
        return 0xFF1D9E75;
      case TaskCategory.learning:
        return 0xFF8B5CF6;
      case TaskCategory.breakTime:
        return 0xFFEF9F27;
      case TaskCategory.personal:
        return 0xFFEC4899;
    }
  }
}
