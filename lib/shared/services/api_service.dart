import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/planner_task.dart';

class ApiService {
  static const _baseUrl = 'https://api.focusflow.app';

  Future<List<PlannerTask>> generateSchedule({
    required String input,
    required String wakeTime,
    required String sleepTime,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/schedule/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'input': input,
              'wakeTime': wakeTime,
              'sleepTime': sleepTime,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => PlannerTask.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _mockSchedule(input, wakeTime);
  }

  List<PlannerTask> _mockSchedule(String input, String wakeTime) {
    final parts = wakeTime.split(':');
    var hour = int.tryParse(parts[0]) ?? 7;
    var minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    PlannerTask next(String task, int dur, String cat) {
      final t =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      minute += dur;
      while (minute >= 60) {
        hour++;
        minute -= 60;
      }
      return PlannerTask(time: t, task: task, durationMinutes: dur, category: cat);
    }

    final lower = input.toLowerCase();
    final tasks = <PlannerTask>[];

    tasks.add(next('Morning routine', 30, 'health'));

    if (lower.contains('gym') || lower.contains('workout')) {
      tasks.add(next('Gym / Workout', 60, 'health'));
    }

    tasks.add(next('Deep work session', 90, 'work'));
    tasks.add(next('Break', 15, 'break'));

    if (lower.contains('meeting')) {
      tasks.add(next('Team meeting', 60, 'work'));
    } else {
      tasks.add(next('Email & review', 30, 'work'));
    }

    tasks.add(next('Lunch', 60, 'health'));
    tasks.add(next('Focus session', 90, 'work'));
    tasks.add(next('Break', 15, 'break'));

    if (lower.contains('read')) {
      tasks.add(next('Reading', 30, 'learning'));
    }

    if (lower.contains('meditat')) {
      tasks.add(next('Meditation', 20, 'personal'));
    }

    tasks.add(next('Wind down', 30, 'personal'));

    return tasks;
  }
}
