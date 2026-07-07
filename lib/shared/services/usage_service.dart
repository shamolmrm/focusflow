import 'package:flutter/services.dart';

class AppEntry {
  final String packageName;
  final String appName;
  final Duration usage;
  final Uint8List? icon;
  final bool isDistracting;

  const AppEntry({
    required this.packageName,
    required this.appName,
    required this.usage,
    this.icon,
    required this.isDistracting,
  });

  double get hours => usage.inMilliseconds / 3600000.0;

  String get timeDisplay {
    final h = usage.inHours;
    final m = usage.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class UsageService {
  static const _ch = MethodChannel('focus_flow/usage');
  static final _iconCache = <String, Uint8List?>{};

  static const _distractingPackages = {
    'com.instagram.android',
    'com.google.android.youtube',
    'com.zhiliaoapp.musically',
    'com.ss.android.ugc.trill',
    'com.facebook.katana',
    'com.twitter.android',
    'com.reddit.frontpage',
    'com.snapchat.android',
    'com.pinterest',
    'com.netflix.mediaclient',
    'com.facebook.orca',
  };

  static bool _skipPackage(String pkg, bool isSystem) {
    if (isSystem) return true;
    if (pkg == 'com.focusflow.focus_flow') return true;
    // skip obvious system/launcher packages that are never truly "system" flagged
    const skipPrefixes = [
      'com.android.', 'android.', 'com.google.android.gms',
      'com.google.android.gsf', 'com.google.android.inputmethod',
      'com.oplus.', 'com.oppo.', 'com.coloros.', 'com.heytap.',
    ];
    return skipPrefixes.any((p) => pkg.startsWith(p));
  }

  static Future<bool> hasPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasUsagePermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    await _ch.invokeMethod('openUsageSettings');
  }

  static Future<List<AppEntry>> getUsage({required bool monthly}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = now - Duration(days: monthly ? 30 : 7).inMilliseconds;

    final raw = await _ch.invokeListMethod<Map>(
      'getAppUsage',
      {'startTime': start, 'endTime': now},
    ) ?? [];

    // Filter + sort by usage descending
    final filtered = raw
        .where((m) => !_skipPackage(
              m['packageName'] as String,
              m['isSystem'] as bool,
            ))
        .toList()
      ..sort((a, b) =>
          (b['totalTimeMs'] as int).compareTo(a['totalTimeMs'] as int));

    final top = filtered.take(12).toList();

    // Load icons in parallel
    final entries = await Future.wait(top.map((m) => _buildEntry(m)));
    return entries.whereType<AppEntry>().toList();
  }

  static Future<AppEntry?> _buildEntry(Map m) async {
    final pkg = m['packageName'] as String;
    final name = m['appName'] as String;
    final ms = m['totalTimeMs'] as int;
    try {
      final icon = await _getIcon(pkg);
      return AppEntry(
        packageName: pkg,
        appName: name,
        usage: Duration(milliseconds: ms),
        icon: icon,
        isDistracting: _distractingPackages.contains(pkg),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _getIcon(String pkg) async {
    if (_iconCache.containsKey(pkg)) return _iconCache[pkg];
    try {
      final bytes = await _ch.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': pkg},
      );
      _iconCache[pkg] = bytes;
      return bytes;
    } catch (_) {
      _iconCache[pkg] = null;
      return null;
    }
  }
}
