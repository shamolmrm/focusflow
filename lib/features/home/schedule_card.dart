import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/task.dart';

class ScheduleCard extends ConsumerWidget {
  final ScheduledTask task;
  final int index;

  const ScheduleCard({super.key, required this.task, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dotColor = Color(task.categoryColorValue);
    final isDone = task.isCompleted;
    final isLive = task.isLive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.bgSurface
            : isLive
                ? AppColors.primaryLight
                : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isLive
              ? AppColors.primary.withValues(alpha: 0.5)
              : isDone
                  ? AppColors.border.withValues(alpha: 0.6)
                  : AppColors.border,
          width: isLive ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 50,
              child: Text(
                task.time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Colored dot
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: isDone ? AppColors.accent : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Task name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.task,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.durationMinutes} min · ${task.categoryLabel}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Action / badge
            if (isLive)
              _LiveBadge()
            else if (isDone)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 22)
            else
              _DoneButton(onTap: () {
                ref.read(scheduleProvider.notifier).markComplete(task.id);
                ref.read(userProvider.notifier).addXp(20);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('+20 XP'),
                      ],
                    ),
                    backgroundColor: AppColors.accent,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.check_rounded,
            size: 16, color: AppColors.textMuted),
      ),
    );
  }
}
