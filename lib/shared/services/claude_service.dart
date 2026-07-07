import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ClaudeService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';

  // API key should come from secure backend proxy in production.
  // For demo, inject via environment or secure storage.
  final String _apiKey;

  ClaudeService({required String apiKey}) : _apiKey = apiKey; // ignore: prefer_initializing_formals

  Future<List<ScheduledTask>> generateDailySchedule({
    required String userInput,
    required String wakeTime,
    required String sleepTime,
  }) async {
    const systemPrompt =
        'You are a productivity coach. Parse the user\'s daily plan and return ONLY a valid JSON array. '
        'Each item must have: { time, task, duration_minutes, category (work|health|learning|break|personal), priority (high|medium|low) }. '
        'Schedule realistically with 15-min breaks every 90 min. Start from wake time. '
        'No preamble. No markdown. Only raw JSON array.';

    final userMessage =
        'Wake time: $wakeTime, Sleep time: $sleepTime\n\nPlan: $userInput';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 2048,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['content'] as List).first as Map<String, dynamic>;
        final text = content['text'] as String;
        final jsonList = jsonDecode(text) as List<dynamic>;
        return jsonList
            .asMap()
            .entries
            .map((e) {
              final item = Map<String, dynamic>.from(e.value as Map);
              item['id'] = e.key.toString();
              return ScheduledTask.fromJson(item);
            })
            .toList();
      }
      throw Exception('Claude API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to generate schedule: $e');
    }
  }

  Future<List<String>> getWeeklyInsights({
    required Map<String, double> appUsage,
    required double totalFocusHours,
    required double totalWastedHours,
  }) async {
    const systemPrompt =
        'You are a productivity coach. Analyze the user\'s weekly screen time and focus data. '
        'Return ONLY a JSON array of 3 short insight strings (max 80 chars each). No markdown. Raw JSON array only.';

    final usageSummary = appUsage.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}h')
        .join(', ');

    final userMessage =
        'Focus hours: $totalFocusHours, Wasted hours: $totalWastedHours\nApp usage: $usageSummary';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 512,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['content'] as List).first as Map<String, dynamic>;
        final text = content['text'] as String;
        return List<String>.from(jsonDecode(text) as List);
      }
    } catch (_) {}
    return [
      'You focus best 8–11 am. Schedule hardest tasks then.',
      'Try to reduce social media usage by 20% this week.',
      'Your streak is building momentum. Keep it up!',
    ];
  }
}
