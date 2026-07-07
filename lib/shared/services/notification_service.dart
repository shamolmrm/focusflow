import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> showDistractionAlert({
    required String appName,
    required int minutesWasted,
  }) async {
    await _plugin.show(
      1001,
      'Stay focused! 🎯',
      'You opened $appName — $minutesWasted min wasted this session',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'distraction_alerts',
          'Distraction Alerts',
          channelDescription: 'Alerts when distracting apps are used during focus',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> showSessionComplete({required int xpEarned}) async {
    await _plugin.show(
      1002,
      'Session complete! 🎉',
      '+$xpEarned XP earned. Take a well-deserved break!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'session_complete',
          'Session Complete',
          channelDescription: 'Notification when a focus session completes',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  static Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    // Scheduled notifications require timezone package in production
    await _plugin.show(
      id,
      'Habit reminder',
      'Time for: $habitName',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily habit reminder notifications',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
