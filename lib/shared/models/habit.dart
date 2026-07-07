import 'package:flutter/material.dart';

enum HabitCategory { health, learning, mindfulness, productivity, personal }

class Habit {
  final String id;
  final String name;
  final String iconName;
  final HabitCategory category;
  final int streakDays;
  final List<bool> weeklyCompletion; // 7 bools, Mon–Sun
  final bool completedToday;
  final int xpReward;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.iconName,
    required this.category,
    this.streakDays = 0,
    required this.weeklyCompletion,
    this.completedToday = false,
    this.xpReward = 50,
    required this.createdAt,
  });

  IconData get icon {
    switch (iconName) {
      case 'workout':
        return Icons.fitness_center;
      case 'read':
        return Icons.menu_book;
      case 'meditate':
        return Icons.self_improvement;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'journal':
        return Icons.edit_note;
      case 'code':
        return Icons.code;
      case 'walk':
        return Icons.directions_walk;
      default:
        return Icons.star;
    }
  }

  Color get categoryColor {
    switch (category) {
      case HabitCategory.health:
        return const Color(0xFF1D9E75);
      case HabitCategory.learning:
        return const Color(0xFF534AB7);
      case HabitCategory.mindfulness:
        return const Color(0xFF8B5CF6);
      case HabitCategory.productivity:
        return const Color(0xFFEF9F27);
      case HabitCategory.personal:
        return const Color(0xFFEC4899);
    }
  }

  Habit copyWith({
    String? name,
    int? streakDays,
    List<bool>? weeklyCompletion,
    bool? completedToday,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      iconName: iconName,
      category: category,
      streakDays: streakDays ?? this.streakDays,
      weeklyCompletion: weeklyCompletion ?? this.weeklyCompletion,
      completedToday: completedToday ?? this.completedToday,
      xpReward: xpReward,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'category': category.name,
        'streakDays': streakDays,
        'weeklyCompletion': weeklyCompletion,
        'completedToday': completedToday,
        'xpReward': xpReward,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String,
        category: HabitCategory.values.byName(json['category'] as String),
        streakDays: json['streakDays'] as int? ?? 0,
        weeklyCompletion:
            List<bool>.from(json['weeklyCompletion'] as List? ?? List.filled(7, false)),
        completedToday: json['completedToday'] as bool? ?? false,
        xpReward: json['xpReward'] as int? ?? 50,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<Habit> get defaults => [
        Habit(
          id: 'workout',
          name: 'Workout',
          iconName: 'workout',
          category: HabitCategory.health,
          weeklyCompletion: List.filled(7, false),
          createdAt: DateTime.now(),
        ),
        Habit(
          id: 'read',
          name: 'Read 30 min',
          iconName: 'read',
          category: HabitCategory.learning,
          weeklyCompletion: List.filled(7, false),
          createdAt: DateTime.now(),
        ),
        Habit(
          id: 'meditate',
          name: 'Meditate',
          iconName: 'meditate',
          category: HabitCategory.mindfulness,
          weeklyCompletion: List.filled(7, false),
          createdAt: DateTime.now(),
        ),
        Habit(
          id: 'water',
          name: 'Drink 2L water',
          iconName: 'water',
          category: HabitCategory.health,
          weeklyCompletion: List.filled(7, false),
          createdAt: DateTime.now(),
        ),
      ];
}
