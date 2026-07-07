import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PlannerTask {
  final String id;
  final String time;
  final String task;
  final int durationMinutes;
  final String category;
  final bool isCompleted;

  PlannerTask({
    String? id,
    required this.time,
    required this.task,
    required this.durationMinutes,
    required this.category,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  PlannerTask copyWith({
    String? time,
    String? task,
    int? durationMinutes,
    String? category,
    bool? isCompleted,
  }) =>
      PlannerTask(
        id: id,
        time: time ?? this.time,
        task: task ?? this.task,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        category: category ?? this.category,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'task': task,
        'durationMinutes': durationMinutes,
        'category': category,
        'isCompleted': isCompleted,
      };

  factory PlannerTask.fromJson(Map<String, dynamic> json) => PlannerTask(
        id: json['id'] as String?,
        time: (json['time'] ?? json['startTime'] ?? '09:00') as String,
        task: (json['task'] ?? json['title'] ?? json['name'] ?? 'Task') as String,
        durationMinutes:
            (json['durationMinutes'] ?? json['duration'] ?? 30) as int,
        category: _normalizeCategory(
            (json['category'] ?? 'work').toString()),
        isCompleted: (json['isCompleted'] ?? false) as bool,
      );

  static String _normalizeCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('health') || lower.contains('workout') || lower.contains('gym')) {
      return 'health';
    }
    if (lower.contains('learn') || lower.contains('study') || lower.contains('read')) {
      return 'learning';
    }
    if (lower.contains('personal') || lower.contains('meditation') || lower.contains('leisure')) {
      return 'personal';
    }
    if (lower.contains('break') || lower.contains('rest') || lower.contains('lunch')) {
      return 'break';
    }
    return 'work';
  }

  static Color dotColor(String category) {
    switch (category) {
      case 'health':
        return const Color(0xFF1D9E75);
      case 'learning':
        return const Color(0xFF378ADD);
      case 'personal':
        return const Color(0xFF888780);
      case 'break':
        return const Color(0xFFEF9F27);
      default:
        return const Color(0xFF534AB7);
    }
  }

  static Color badgeBg(String category) {
    switch (category) {
      case 'health':
        return const Color(0xFFE1F5EE);
      case 'learning':
        return const Color(0xFFE6F1FB);
      case 'personal':
        return const Color(0xFFF1EFE8);
      case 'break':
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFEEEDFE);
    }
  }
}
