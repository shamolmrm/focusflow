import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/user.dart';
import '../shared/models/habit.dart';
import '../shared/models/task.dart';
import '../shared/models/session.dart';
import '../shared/models/planner_task.dart';
import '../shared/services/storage_service.dart';
import '../shared/services/api_service.dart';
import '../shared/services/claude_service.dart';
import '../shared/services/usage_service.dart';

// ─── Onboarding ──────────────────────────────────────────────────────────────

final onboardingCompleteProvider = StateProvider<bool>(
  (ref) => StorageService.onboardingDone,
);

// ─── User ────────────────────────────────────────────────────────────────────

class UserNotifier extends StateNotifier<AppUser?> {
  UserNotifier() : super(_loadUser());

  static AppUser? _loadUser() {
    final json = StorageService.userJson;
    if (json == null) return null;
    return AppUser.fromJson(json);
  }

  Future<void> setUser(AppUser user) async {
    state = user;
    await StorageService.saveUser(user.toJson());
  }

  Future<void> updateGoals(List<String> goals) async {
    if (state == null) return;
    await setUser(state!.copyWith(goals: goals));
  }

  Future<void> updateWakeTime(String t) async {
    if (state == null) return;
    await setUser(state!.copyWith(wakeTime: t));
  }

  Future<void> addXp(int xp) async {
    if (state == null) return;
    final newXp = state!.totalXp + xp;
    final newLevel = (newXp / 500).floor() + 1;
    await setUser(state!.copyWith(totalXp: newXp, level: newLevel));
  }

  Future<void> setPro(bool v) async {
    if (state == null) return;
    await setUser(state!.copyWith(isPro: v));
    await StorageService.setPro(v);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AppUser?>(
  (ref) => UserNotifier(),
);

// ─── Habits ──────────────────────────────────────────────────────────────────

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super(_loadHabits());

  static List<Habit> _loadHabits() {
    final saved = StorageService.habitsJson;
    if (saved.isEmpty) return Habit.defaults;
    return saved.map(Habit.fromJson).toList();
  }

  Future<void> _save() async {
    await StorageService.saveHabits(state.map((h) => h.toJson()).toList());
  }

  Future<void> markComplete(String habitId) async {
    final today = DateTime.now().weekday - 1;
    state = state.map((h) {
      if (h.id != habitId || h.completedToday) return h;
      final updated = List<bool>.from(h.weeklyCompletion);
      if (today < updated.length) updated[today] = true;
      return h.copyWith(
        completedToday: true,
        streakDays: h.streakDays + 1,
        weeklyCompletion: updated,
      );
    }).toList();
    await _save();
  }

  Future<void> addHabit(Habit habit) async {
    state = [...state, habit];
    await _save();
  }

  Future<void> removeHabit(String id) async {
    state = state.where((h) => h.id != id).toList();
    await _save();
  }

  void resetDailyCompletion() {
    state = state.map((h) => h.copyWith(completedToday: false)).toList();
    _save();
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<Habit>>(
  (ref) => HabitsNotifier(),
);

// ─── Schedule ────────────────────────────────────────────────────────────────

final scheduleLoadingProvider = StateProvider<bool>((ref) => false);

class ScheduleNotifier extends StateNotifier<List<ScheduledTask>> {
  ScheduleNotifier() : super(_loadSchedule());

  static List<ScheduledTask> _loadSchedule() {
    final saved = StorageService.scheduleJson;
    return saved.map(ScheduledTask.fromJson).toList();
  }

  Future<void> setTasks(List<ScheduledTask> tasks) async {
    state = tasks;
    await StorageService.saveSchedule(tasks.map((t) => t.toJson()).toList());
  }

  void markComplete(String taskId) {
    state = state.map((t) {
      if (t.id == taskId) return t.copyWith(isCompleted: true);
      return t;
    }).toList();
    StorageService.saveSchedule(state.map((t) => t.toJson()).toList());
  }

  void setLive(String taskId) {
    state = state
        .map((t) => t.copyWith(isLive: t.id == taskId))
        .toList();
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<ScheduledTask>>(
  (ref) => ScheduleNotifier(),
);

// ─── Focus Session ───────────────────────────────────────────────────────────

class SessionNotifier extends StateNotifier<FocusSession> {
  Timer? _timer;
  DateTime? _backgroundedAt;

  SessionNotifier()
      : super(FocusSession(
          id: '1',
          taskName: 'Deep work',
          workMinutes: 25,
          breakMinutes: 5,
        ));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateTaskName(String name) =>
      state = state.copyWith(taskName: name);

  void setDuration(int workMin, int breakMin) => state = state.copyWith(
        workMinutes: workMin,
        breakMinutes: breakMin,
        secondsRemaining: workMin * 60,
        sessionState: SessionState.idle,
      );

  void start() {
    state = state.copyWith(
      sessionState: SessionState.running,
      startedAt: state.startedAt ?? DateTime.now(),
    );
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(sessionState: SessionState.paused);
  }

  void reset() {
    _timer?.cancel();
    state = FocusSession(
      id: state.id,
      taskName: state.taskName,
      workMinutes: state.workMinutes,
      breakMinutes: state.breakMinutes,
    );
  }

  void startBreak() {
    state = state.copyWith(
      sessionState: SessionState.onBreak,
      secondsRemaining: state.breakMinutes * 60,
    );
    _startTimer();
  }

  void completeBreak() {
    _timer?.cancel();
    state = state.copyWith(
      sessionState: SessionState.idle,
      secondsRemaining: state.workMinutes * 60,
    );
  }

  void addDistraction(String appName) => state = state.copyWith(
        distractionAlerts: [...state.distractionAlerts, appName],
      );

  // Called by FocusFlowApp observer when app goes to background
  void onBackground() {
    if (state.isRunning || state.isOnBreak) {
      _backgroundedAt = DateTime.now();
      _timer?.cancel();
    }
  }

  // Called by FocusFlowApp observer when app returns to foreground
  void onForeground() {
    if (_backgroundedAt == null) return;
    if (!state.isRunning && !state.isOnBreak) {
      _backgroundedAt = null;
      return;
    }
    final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
    _backgroundedAt = null;
    final remaining = state.secondsRemaining - elapsed;
    if (remaining <= 0) {
      _handleEnd();
    } else {
      state = state.copyWith(secondsRemaining: remaining);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isRunning && !state.isOnBreak) {
      _timer?.cancel();
      return;
    }
    if (state.secondsRemaining > 0) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    } else {
      _handleEnd();
    }
  }

  void _handleEnd() {
    _timer?.cancel();
    if (state.isOnBreak) {
      state = state.copyWith(
        sessionState: SessionState.idle,
        secondsRemaining: state.workMinutes * 60,
      );
    } else {
      final minutes = state.workMinutes;
      state = state.copyWith(
        sessionState: SessionState.completed,
        completedPomodoros: state.completedPomodoros + 1,
        xpEarned: state.xpEarned + 50,
      );
      StorageService.addFocusMinutes(minutes);
    }
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, FocusSession>(
  (ref) => SessionNotifier(),
);

// ─── Music track ─────────────────────────────────────────────────────────────

final selectedTrackProvider = StateProvider<int>((ref) => 8); // Silent is index 8

// ─── Services ────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider((ref) => ApiService());

final claudeServiceProvider = Provider((ref) {
  const key = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
  return ClaudeService(apiKey: key);
});

// ─── Analytics ───────────────────────────────────────────────────────────────

final analyticsViewProvider = StateProvider<String>((ref) => 'week');

final weeklyFocusProvider = Provider<List<double>>((ref) {
  return StorageService.getWeeklyFocus();
});

/// bool param = isMonthly (false = last 7 days, true = last 30 days)
final appUsageProvider =
    FutureProvider.autoDispose.family<List<AppEntry>, bool>(
  (ref, isMonthly) async {
    final allowed = await UsageService.hasPermission();
    if (!allowed) throw 'no_permission';
    return UsageService.getUsage(monthly: isMonthly);
  },
);

final aiInsightsProvider = StateProvider<List<String>>((ref) => [
  'You focus best 8–11 am. Schedule your hardest tasks then.',
  'Instagram usage is up — try blocking it during focus hours.',
  'Your streak is building momentum — 3 more days to unlock "Week Warrior"!',
]);

// ─── Daily Planner Tasks ──────────────────────────────────────────────────────

class TaskListNotifier extends StateNotifier<List<PlannerTask>> {
  TaskListNotifier() : super([]);

  void addTask(PlannerTask t) {
    final list = [...state, t];
    list.sort((a, b) => a.time.compareTo(b.time));
    state = list;
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void editTask(String id, PlannerTask updated) {
    final list = state.map((t) => t.id == id ? updated : t).toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    state = list;
  }

  void setFromAI(List<PlannerTask> tasks) => state = tasks;

  void clearAll() => state = [];

  void toggleComplete(String id) {
    state = state
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
  }
}

final plannerTasksProvider =
    StateNotifierProvider<TaskListNotifier, List<PlannerTask>>(
  (ref) => TaskListNotifier(),
);

// ─── Theme Mode ──────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return StorageService.darkMode ? ThemeMode.dark : ThemeMode.light;
});

// ─── Custom Tracks ───────────────────────────────────────────────────────────

final customTracksProvider = StateProvider<List<String>>((ref) => []);

// ─── Firebase Auth ────────────────────────────────────────────────────────────

/// Streams the Firebase auth state. null = signed out.
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// True when a Firebase user is signed in.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).valueOrNull != null,
);
