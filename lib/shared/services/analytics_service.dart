import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Identity ────────────────────────────────────────────────────────────────

  static Future<void> setUser(String uid, String name) async {
    await _analytics.setUserId(id: uid);
    await _analytics.setUserProperty(name: 'display_name', value: name);
  }

  static Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
  }

  // ── Auth events ─────────────────────────────────────────────────────────────

  static Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  static Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  // ── Focus events ────────────────────────────────────────────────────────────

  static Future<void> logSessionStarted(int durationMinutes) =>
      _analytics.logEvent(
        name: 'session_started',
        parameters: {'duration_min': durationMinutes},
      );

  static Future<void> logSessionCompleted(int durationMinutes, int xpEarned) =>
      _analytics.logEvent(
        name: 'session_completed',
        parameters: {
          'duration_min': durationMinutes,
          'xp_earned': xpEarned,
        },
      );

  static Future<void> logSessionPaused() =>
      _analytics.logEvent(name: 'session_paused');

  // ── Habit events ────────────────────────────────────────────────────────────

  static Future<void> logHabitCompleted(String habitName, int xp) =>
      _analytics.logEvent(
        name: 'habit_completed',
        parameters: {'habit_name': habitName, 'xp': xp},
      );

  static Future<void> logHabitDeleted(String habitName) =>
      _analytics.logEvent(
        name: 'habit_deleted',
        parameters: {'habit_name': habitName},
      );

  // ── Screen events ───────────────────────────────────────────────────────────

  static Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  // ── Generic ─────────────────────────────────────────────────────────────────

  static Future<void> logEvent(String name,
          [Map<String, Object>? params]) =>
      _analytics.logEvent(name: name, parameters: params);
}
