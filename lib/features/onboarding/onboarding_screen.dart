import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

              const SizedBox(height: 28),

              Text(
                'Meet FocusFlow',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

              const SizedBox(height: 10),

              Text(
                'Your AI coach for focus,\nhabits, and deep work',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const Spacer(),

              // Feature rows
              ...[
                (Icons.auto_awesome_rounded, AppColors.primary,
                    'AI Scheduler', 'Claude builds your perfect daily plan'),
                (Icons.local_fire_department_rounded, AppColors.danger,
                    'Habit Streaks', 'Build streaks and earn XP rewards'),
                (Icons.shield_rounded, AppColors.accent,
                    'Distraction Blocker', 'Real-time alerts during focus sessions'),
              ].asMap().entries.map((e) {
                final (icon, color, title, sub) = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _FeatureRow(
                    icon: icon,
                    color: color,
                    title: title,
                    subtitle: sub,
                  ).animate().fadeIn(delay: (300 + e.key * 100).ms, duration: 400.ms)
                      .slideX(begin: -0.1),
                );
              }),

              const Spacer(flex: 2),

              ElevatedButton(
                onPressed: () => context.go('/permissions'),
                child: const Text("Get started — it's free"),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => context.go('/permissions'),
                child: const Text('I already have an account'),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 16),

              Text(
                'No credit card needed. Free forever on basic plan.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 900.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
