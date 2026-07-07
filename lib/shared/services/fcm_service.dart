import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

// Must be top-level for background handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this fires in background
}

class FcmService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'focus_flow_channel';
  static const _channelName = 'FocusFlow Notifications';

  static Future<void> init() async {
    // Background handler must be registered before anything else
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications (for foreground display)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Save FCM token to Firestore
    final token = await _fcm.getToken();
    if (token != null) await FirestoreService.saveFcmToken(token);

    // Refresh token when it changes
    _fcm.onTokenRefresh.listen(FirestoreService.saveFcmToken);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigate based on payload if needed
  }

  static Future<String?> getToken() => _fcm.getToken();

  static Future<void> subscribeToTopic(String topic) =>
      _fcm.subscribeToTopic(topic);

  static Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);

  static Future<void> deleteToken() async {
    final token = await _fcm.getToken();
    if (token != null) await FirestoreService.removeFcmToken(token);
    await _fcm.deleteToken();
  }
}
