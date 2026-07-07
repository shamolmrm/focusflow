import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/user.dart';
import '../../shared/services/storage_service.dart';

const _goalOptions = <(String, IconData)>[
  ('Focus', Icons.center_focus_strong_rounded),
  ('Fitness', Icons.fitness_center_rounded),
  ('Learning', Icons.menu_book_rounded),
  ('Sleep', Icons.bedtime_rounded),
  ('Mindfulness', Icons.self_improvement_rounded),
  ('Career', Icons.trending_up_rounded),
];

class PersonalizeScreen extends ConsumerStatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  ConsumerState<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends ConsumerState<PersonalizeScreen> {
  final _nameCtrl = TextEditingController();
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  final Set<String> _selectedGoals = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickWake() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _wake,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _wake = t);
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: '',
      wakeTime: _fmt(_wake),
      goals: _selectedGoals.toList(),
      createdAt: DateTime.now(),
    );

    await ref.read(userProvider.notifier).setUser(user);
    await StorageService.setOnboardingDone();
    ref.read(onboardingCompleteProvider.notifier).state = true;

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepBar(step: 2),
                  const SizedBox(height: 36),
                  Text('Personalize',
                          style: Theme.of(context).textTheme.headlineMedium)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Tell us about yourself so we can tailor your experience.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4),
                  ).animate().fadeIn(delay: 80.ms),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    const _Label('Your name'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Alex',
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppColors.textMuted),
                      ),
                    ).animate().fadeIn(delay: 120.ms),

                    const SizedBox(height: 28),

                    // Wake time
                    const _Label('Wake-up time'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickWake,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.element),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              _fmt(_wake),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 160.ms),

                    const SizedBox(height: 28),

                    // Goals
                    Row(
                      children: [
                        const _Label('Select your goals'),
                        const Spacer(),
                        Text(
                          '${_selectedGoals.length}/3',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedGoals.length == 3
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Pick up to 3 that matter most',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 14),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.9,
                      ),
                      itemCount: _goalOptions.length,
                      itemBuilder: (_, i) {
                        final label = _goalOptions[i].$1;
                        final icon = _goalOptions[i].$2;
                        final selected = _selectedGoals.contains(label);
                        return _GoalChip(
                          label: label,
                          icon: icon,
                          selected: selected,
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedGoals.remove(label);
                            } else if (_selectedGoals.length < 3) {
                              _selectedGoals.add(label);
                            }
                          }),
                        ).animate().fadeIn(delay: (200 + i * 50).ms);
                      },
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: _saving ? null : _finish,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Build my profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(3, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= step ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      );
}

class _GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.element),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 15),
          ],
        ),
      ),
    );
  }
}
