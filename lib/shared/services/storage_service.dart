import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() must be called first');
    return _prefs!;
  }

  // Onboarding
  static bool get onboardingDone => _p.getBool('onboarding_done') ?? false;
  static Future<void> setOnboardingDone() => _p.setBool('onboarding_done', true);

  // Auth — skip-login flag (user chose "use without account")
  static bool get skipLogin => _p.getBool('skip_login') ?? false;
  static Future<void> setSkipLogin(bool v) => _p.setBool('skip_login', v);

  // User
  static Map<String, dynamic>? get userJson {
    final s = _p.getString('user');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> saveUser(Map<String, dynamic> json) =>
      _p.setString('user', jsonEncode(json));

  // Habits
  static List<Map<String, dynamic>> get habitsJson {
    final s = _p.getString('habits');
    if (s == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(s) as List);
  }

  static Future<void> saveHabits(List<Map<String, dynamic>> list) =>
      _p.setString('habits', jsonEncode(list));

  // Schedule
  static List<Map<String, dynamic>> get scheduleJson {
    final s = _p.getString('schedule_${_todayKey()}');
    if (s == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(s) as List);
  }

  static Future<void> saveSchedule(List<Map<String, dynamic>> list) =>
      _p.setString('schedule_${_todayKey()}', jsonEncode(list));

  // Focus stats (daily)
  static double getTodayFocusHours() =>
      _p.getDouble('focus_${_todayKey()}') ?? 0.0;

  static Future<void> addFocusMinutes(int minutes) async {
    final key = 'focus_${_todayKey()}';
    final current = _p.getDouble(key) ?? 0.0;
    await _p.setDouble(key, current + minutes / 60.0);
  }

  // Weekly focus (last 7 days)
  static List<double> getWeeklyFocus() {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final key = 'focus_${_dateKey(date)}';
      return _p.getDouble(key) ?? 0.0;
    });
  }

  // Pro status
  static bool get isPro => _p.getBool('is_pro') ?? false;
  static Future<void> setPro(bool v) => _p.setBool('is_pro', v);

  // Settings
  static bool get reminderEnabled => _p.getBool('reminder_enabled') ?? true;
  static Future<void> setReminderEnabled(bool v) => _p.setBool('reminder_enabled', v);

  static String get reminderTime => _p.getString('reminder_time') ?? '08:00';
  static Future<void> setReminderTime(String v) => _p.setString('reminder_time', v);

  static bool get hapticEnabled => _p.getBool('haptic_enabled') ?? true;
  static Future<void> setHapticEnabled(bool v) => _p.setBool('haptic_enabled', v);

  static bool get soundEnabled => _p.getBool('sound_enabled') ?? true;
  static Future<void> setSoundEnabled(bool v) => _p.setBool('sound_enabled', v);

  static bool get focusAlerts => _p.getBool('focus_alerts') ?? true;
  static Future<void> setFocusAlerts(bool v) => _p.setBool('focus_alerts', v);

  static bool get darkMode => _p.getBool('dark_mode') ?? false;
  static Future<void> setDarkMode(bool v) => _p.setBool('dark_mode', v);

  static Future<void> clearAllData() async {
    final prefs = _p;
    await prefs.clear();
  }

  // Helpers
  static String _todayKey() => _dateKey(DateTime.now());
  static String _dateKey(DateTime d) =>
      '${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';
}
