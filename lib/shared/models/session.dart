enum SessionState { idle, running, paused, completed, onBreak }

class FocusSession {
  final String id;
  final String taskName;
  final int workMinutes;
  final int breakMinutes;
  final SessionState sessionState;
  final int secondsRemaining;
  final int completedPomodoros;
  final int xpEarned;
  final DateTime? startedAt;
  final List<String> distractionAlerts;

  FocusSession({
    required this.id,
    required this.taskName,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.sessionState = SessionState.idle,
    int? secondsRemaining,
    this.completedPomodoros = 0,
    this.xpEarned = 0,
    this.startedAt,
    this.distractionAlerts = const [],
  }) : secondsRemaining = secondsRemaining ?? workMinutes * 60;

  bool get isRunning => sessionState == SessionState.running;
  bool get isPaused => sessionState == SessionState.paused;
  bool get isOnBreak => sessionState == SessionState.onBreak;
  bool get isCompleted => sessionState == SessionState.completed;
  bool get isIdle => sessionState == SessionState.idle;

  String get timeDisplay {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = isOnBreak ? breakMinutes * 60 : workMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (secondsRemaining / total).clamp(0.0, 1.0);
  }

  FocusSession copyWith({
    String? id,
    String? taskName,
    int? workMinutes,
    int? breakMinutes,
    SessionState? sessionState,
    int? secondsRemaining,
    int? completedPomodoros,
    int? xpEarned,
    DateTime? startedAt,
    List<String>? distractionAlerts,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      sessionState: sessionState ?? this.sessionState,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      xpEarned: xpEarned ?? this.xpEarned,
      startedAt: startedAt ?? this.startedAt,
      distractionAlerts: distractionAlerts ?? this.distractionAlerts,
    );
  }
}
