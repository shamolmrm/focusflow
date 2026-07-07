class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String wakeTime;
  final String sleepTime;
  final List<String> goals;
  final int totalXp;
  final int level;
  final bool isPro;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.goals = const [],
    this.totalXp = 0,
    this.level = 1,
    this.isPro = false,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  String get levelName {
    if (level < 3) return 'Beginner';
    if (level < 5) return 'Explorer';
    if (level < 8) return 'Achiever';
    if (level < 12) return 'Focus Warrior';
    if (level < 18) return 'Flow Master';
    return 'Productivity Legend';
  }

  int get xpForNextLevel => level * 500;

  AppUser copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? wakeTime,
    String? sleepTime,
    List<String>? goals,
    int? totalXp,
    int? level,
    bool? isPro,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      goals: goals ?? this.goals,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      isPro: isPro ?? this.isPro,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'wakeTime': wakeTime,
        'sleepTime': sleepTime,
        'goals': goals,
        'totalXp': totalXp,
        'level': level,
        'isPro': isPro,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        wakeTime: json['wakeTime'] as String? ?? '07:00',
        sleepTime: json['sleepTime'] as String? ?? '23:00',
        goals: List<String>.from(json['goals'] as List? ?? []),
        totalXp: json['totalXp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        isPro: json['isPro'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
