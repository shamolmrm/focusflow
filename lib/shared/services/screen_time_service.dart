import 'dart:io';
import 'package:flutter/services.dart';

class ScreenTimeService {
  static const _channel = MethodChannel('com.focusflow/screen_time');

  static const _distractingApps = [
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.facebook.katana',
    'com.snapchat.android',
    'com.twitter.android',
    'com.reddit.frontpage',
    'com.google.android.youtube',
  ];

  static Future<Map<String, double>> getAppUsageStats({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!Platform.isAndroid) return _mockUsageData();

    try {
      final result = await _channel.invokeMethod<Map>('getUsageStats', {
        'fromMillis': from.millisecondsSinceEpoch,
        'toMillis': to.millisecondsSinceEpoch,
      });

      if (result == null) return {};
      return result.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    } catch (_) {
      return _mockUsageData();
    }
  }

  static Future<String?> checkDistractionDuringSession() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<String>('getLastActiveApp');
      if (result != null && _distractingApps.contains(result)) {
        return _appDisplayName(result);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> requestUsagePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final granted = await _channel.invokeMethod<bool>('requestUsagePermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static String _appDisplayName(String packageName) {
    const names = {
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.facebook.katana': 'Facebook',
      'com.snapchat.android': 'Snapchat',
      'com.twitter.android': 'Twitter/X',
      'com.reddit.frontpage': 'Reddit',
      'com.google.android.youtube': 'YouTube',
    };
    return names[packageName] ?? packageName;
  }

  static Map<String, double> _mockUsageData() => {
        'Instagram': 1.2,
        'YouTube': 0.8,
        'VS Code': 3.5,
        'Chrome': 1.1,
        'Slack': 0.6,
        'WhatsApp': 0.4,
        'Notion': 0.9,
      };
}
