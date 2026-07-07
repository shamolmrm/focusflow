import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/habit.dart';

class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  const HabitCard({super.key, required this.habit});

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.93), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.93, end: 1.04), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove habit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Remove "${widget.habit.name}" from your habits?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(habitsProvider.notifier).removeHabit(widget.habit.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _markDone() async {
    if (widget.habit.completedToday) return;
    HapticFeedback.lightImpact();
    _bounce.forward(from: 0);
    ref.read(habitsProvider.notifier).markComplete(widget.habit.id);
    ref.read(userProvider.notifier).addXp(widget.habit.xpReward);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('+${widget.habit.xpReward} XP · ${widget.habit.name} done!'),
            ],
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final color = h.categoryColor;
    final done = h.completedToday;
    final today = DateTime.now().weekday - 1;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _markDone,
        onLongPress: _confirmDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: done ? color.withValues(alpha: 0.07) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: done
                  ? color.withValues(alpha: 0.45)
                  : AppColors.border,
              width: done ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + streak
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: done ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(h.icon,
                        color: done ? color : color.withValues(alpha: 0.7),
                        size: 20),
                  ),
                  const Spacer(),
                  if (h.streakDays > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: done
                            ? color.withValues(alpha: 0.15)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 11,
                              color: done ? color : AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            '${h.streakDays}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: done ? color : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (done) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 15, color: AppColors.danger),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                h.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Status
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  done ? '✓ Done today' : 'Tap to complete',
                  key: ValueKey(done),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    color: done ? color : AppColors.textMuted,
                  ),
                ),
              ),

              const Spacer(),

              // Weekly dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final filled =
                      i < h.weeklyCompletion.length && h.weeklyCompletion[i];
                  final isToday = i == today;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: filled ? color : AppColors.border,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: color, width: 1.5)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
