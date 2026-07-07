import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/habit.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/pill_badge.dart';
import 'habit_card.dart';
import 'xp_bar.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final habits = ref.watch(habitsProvider);
    final isPro = user?.isPro ?? false;
    final maxFree = 3;
    final atLimit = !isPro && habits.length >= maxFree;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your habits',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  )),
                              const SizedBox(height: 3),
                              Text(
                                'Level ${user?.level ?? 1} · ${user?.levelName ?? 'Beginner'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPro)
                          GestureDetector(
                            onTap: () => context.push('/upgrade'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.workspace_premium_rounded,
                                      color: AppColors.warning, size: 15),
                                  SizedBox(width: 5),
                                  Text('Upgrade',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    XpBar(
                      currentXp: user?.totalXp ?? 0,
                      targetXp: user?.xpForNextLevel ?? 500,
                    ),
                  ],
                ),
              ),
            ),

            // ── Habits grid ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == habits.length) {
                      return _AddCard(
                        locked: atLimit,
                        onTap: atLimit
                            ? () => context.push('/upgrade')
                            : () => _showAdd(context, ref),
                      ).animate().fadeIn(
                          delay: (i * 60).ms, duration: 300.ms);
                    }
                    return HabitCard(habit: habits[i])
                        .animate()
                        .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                        .slideY(begin: 0.08);
                  },
                  childCount: habits.length + 1,
                ),
              ),
            ),

            // ── Free tier notice ─────────────────────────────────────────────
            if (!isPro)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _FreeNotice(
                    count: habits.length,
                    max: maxFree,
                    onUpgrade: () => context.push('/upgrade'),
                  ),
                ),
              ),

            // ── Achievements ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillBadge(
                        label: 'First week',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.warningLight,
                        textColor: AppColors.warning),
                    PillBadge(
                        label: '7-day streak',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.dangerLight,
                        textColor: AppColors.danger),
                    PillBadge(
                        label: 'Early riser',
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.accentLight,
                        textColor: AppColors.accent),
                    const PillBadge(label: '30-day streak', isLocked: true),
                    const PillBadge(label: 'Century club', isLocked: true),
                    const PillBadge(label: 'Night owl', isLocked: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddHabitSheet(ref: ref),
    );
  }
}

class _FreeNotice extends StatelessWidget {
  final int count;
  final int max;
  final VoidCallback onUpgrade;

  const _FreeNotice({
    required this.count,
    required this.max,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.element),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count/$max habits used. Upgrade Pro for unlimited.',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUpgrade,
            child: const Text(
              'Upgrade',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final bool locked;
  final VoidCallback onTap;

  const _AddCard({required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: locked
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.warningLight
                    : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                locked
                    ? Icons.workspace_premium_rounded
                    : Icons.add_rounded,
                color:
                    locked ? AppColors.warning : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              locked ? 'Upgrade Pro' : 'Add habit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: locked ? AppColors.warning : AppColors.primary,
              ),
            ),
            if (locked)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text(
                  'Limit reached',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add habit bottom sheet ───────────────────────────────────────────────────

const _habitTemplates = <(String, String, HabitCategory)>[
  ('Workout', 'workout', HabitCategory.health),
  ('Read 30 min', 'read', HabitCategory.learning),
  ('Meditate', 'meditate', HabitCategory.mindfulness),
  ('Drink 2L water', 'water', HabitCategory.health),
  ('Journal', 'journal', HabitCategory.personal),
  ('Code practice', 'code', HabitCategory.productivity),
  ('Evening walk', 'walk', HabitCategory.health),
  ('Sleep by 10pm', 'sleep', HabitCategory.health),
];

class _AddHabitSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddHabitSheet({required this.ref});

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _ctrl = TextEditingController();
  String? _selected;
  final HabitCategory _cat = HabitCategory.health;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final name = _selected ?? _ctrl.text.trim();
    if (name.isEmpty) return;

    final template = _habitTemplates.where((t) => t.$1 == name).firstOrNull;
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      iconName: template?.$2 ?? 'star',
      category: template?.$3 ?? _cat,
      weeklyCompletion: List.filled(7, false),
      createdAt: DateTime.now(),
    );

    widget.ref.read(habitsProvider.notifier).addHabit(habit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'New habit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick picks
          const Text(
            'Quick add',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _habitTemplates.map((t) {
              final sel = _selected == t.$1;
              return GestureDetector(
                onTap: () => setState(() {
                  _selected = sel ? null : t.$1;
                  if (!sel) _ctrl.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        sel ? AppColors.primary : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.border),
                  ),
                  child: Text(
                    t.$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          sel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Text(
            'Or type custom',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() => _selected = null),
            decoration: const InputDecoration(
              hintText: 'e.g. Practice guitar',
              prefixIcon: Icon(Icons.edit_outlined,
                  color: AppColors.textMuted, size: 18),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selected != null || _ctrl.text.trim().isNotEmpty)
                ? _add
                : null,
            child: const Text('Add habit'),
          ),
        ],
      ),
    );
  }
}
