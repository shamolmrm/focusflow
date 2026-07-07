import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/planner_task.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'ai_planner_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final habits = ref.watch(habitsProvider);
    final tasks = ref.watch(plannerTasksProvider);

    final streak = habits.isNotEmpty
        ? habits.map((h) => h.streakDays).reduce((a, b) => a > b ? a : b)
        : 0;
    final completedTasks = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.bgLight,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    // Avatar → profile
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.initials ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user?.name ?? 'Friend',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Settings icon
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats row (tappable) ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Day streak',
                        value: '$streak 🔥',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                        onTap: () => _showStreakSheet(context, ref),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Total XP',
                        value: '${user?.totalXp ?? 0}',
                        icon: Icons.bolt_rounded,
                        color: AppColors.warning,
                        onTap: () => _showXpSheet(context, ref),
                      ).animate().fadeIn(delay: 60.ms, duration: 400.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Tasks done',
                        value: tasks.isEmpty
                            ? '${habits.where((h) => h.completedToday).length}/${habits.length}'
                            : '$completedTasks/${tasks.length}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.accent,
                        onTap: () => _showTasksSheet(context, ref),
                      ).animate().fadeIn(delay: 120.ms, duration: 400.ms).slideY(begin: 0.1),
                    ),
                  ],
                ),
              ),
            ),

            // ── Daily Planner ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const DailyPlannerCard()
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 400.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  void _showStreakSheet(BuildContext context, WidgetRef ref) {
    final habits = ref.read(habitsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: 'Habit streaks',
        icon: Icons.local_fire_department_rounded,
        iconColor: AppColors.primary,
        child: habits.isEmpty
            ? const _EmptyHint('No habits yet. Add habits to track streaks.')
            : Column(
                children: habits.map((h) {
                  return _SheetRow(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(h.icon, size: 18, color: AppColors.primary),
                    ),
                    title: h.name,
                    subtitle: '${h.streakDays} day streak',
                    trailing: h.completedToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Done',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text('Pending',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted)),
                          ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  void _showXpSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final xp = user?.totalXp ?? 0;
    final level = user?.level ?? 1;
    final nextLevelXp = user?.xpForNextLevel ?? 500;
    final progress = (xp % 500) / 500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: 'XP & Level',
        icon: Icons.bolt_rounded,
        iconColor: AppColors.warning,
        child: Column(
          children: [
            // Level card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Level $level — ${user?.levelName ?? "Beginner"}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$xp XP',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      Text('Next: $nextLevelXp XP',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SheetRow(
              leading: _XpDot(color: AppColors.accent),
              title: 'Task completed',
              subtitle: 'Each task marked done',
              trailing: const Text('+20 XP',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ),
            _SheetRow(
              leading: _XpDot(color: AppColors.primary),
              title: 'Habit done',
              subtitle: 'Each habit checked off',
              trailing: const Text('+30 XP',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            _SheetRow(
              leading: _XpDot(color: AppColors.warning),
              title: 'Focus session',
              subtitle: 'Complete a Pomodoro',
              trailing: const Text('+50 XP',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTasksSheet(BuildContext context, WidgetRef ref) {
    final tasks = ref.read(plannerTasksProvider);
    final habits = ref.read(habitsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: "Today's progress",
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.accent,
        child: tasks.isEmpty
            ? Column(
                children: [
                  const _EmptyHint('No tasks planned yet. Use the planner to build your day.'),
                  const SizedBox(height: 16),
                  const Text('Habits today',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (habits.isEmpty)
                    const _EmptyHint('No habits set up yet.')
                  else
                    ...habits.map((h) => _SheetRow(
                          leading: Icon(h.icon,
                              size: 20,
                              color: h.completedToday
                                  ? AppColors.accent
                                  : AppColors.textMuted),
                          title: h.name,
                          trailing: Icon(
                            h.completedToday
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: h.completedToday
                                ? AppColors.accent
                                : AppColors.border,
                            size: 20,
                          ),
                        )),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  Builder(builder: (_) {
                    final done = tasks.where((t) => t.isCompleted).length;
                    final pct =
                        tasks.isEmpty ? 0.0 : done / tasks.length;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$done / ${tasks.length} done',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('${(pct * 100).round()}%',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: AppColors.bgSurface,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  ...tasks.map((t) => _SheetRow(
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: t.isCompleted
                                ? AppColors.accent
                                : PlannerTask.dotColor(t.category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: t.task,
                        subtitle: '${t.time} · ${t.durationMinutes}min',
                        trailing: Icon(
                          t.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: t.isCompleted
                              ? AppColors.accent
                              : AppColors.border,
                          size: 20,
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}

// ── Stat card (tappable) ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet shell ────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BottomSheet({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Sheet row ─────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SheetRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                if (subtitle case final s?) Text(s,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center),
    );
  }
}

class _XpDot extends StatelessWidget {
  final Color color;
  const _XpDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
