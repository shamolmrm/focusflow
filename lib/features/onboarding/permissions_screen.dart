import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notifGranted = false;
  bool _usageGranted = false;

  Future<void> _requestNotif() async {
    final s = await Permission.notification.request();
    setState(() => _notifGranted = s.isGranted);
  }

  Future<void> _requestUsage() async {
    // Opens system settings for usage access on Android
    await Permission.ignoreBatteryOptimizations.request();
    if (mounted) setState(() => _usageGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _StepBar(step: 1),
              const SizedBox(height: 36),

              Text('Quick setup',
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 8),
              Text(
                'FocusFlow needs a couple of permissions to protect your focus time.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 32),

              _PermCard(
                icon: Icons.notifications_rounded,
                color: AppColors.primary,
                title: 'Notifications',
                desc: 'Habit reminders, focus alerts & distraction warnings — delivered at the right time.',
                granted: _notifGranted,
                onTap: _requestNotif,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.08),

              const SizedBox(height: 14),

              _PermCard(
                icon: Icons.phone_android_rounded,
                color: AppColors.accent,
                title: 'Usage Access',
                desc: 'Detect distracting apps opened during focus sessions so we can alert you instantly.',
                granted: _usageGranted,
                onTap: _requestUsage,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.08),

              const Spacer(),

              ElevatedButton(
                onPressed: () => context.go('/personalize'),
                child: const Text('Continue'),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/personalize'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _PermCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool granted;
  final VoidCallback onTap;

  const _PermCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: granted ? color.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: granted ? color.withValues(alpha: 0.5) : AppColors.border,
          width: granted ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: granted ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: granted ? AppColors.accent : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (granted)
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  if (granted) const SizedBox(width: 4),
                  Text(
                    granted ? 'Done' : 'Allow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
