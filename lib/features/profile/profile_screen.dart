import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/user.dart';

const _goalOptions = [
  ('Deep focus', '🎯'),
  ('Build habits', '🔥'),
  ('Reduce screen time', '📵'),
  ('Learn faster', '📚'),
  ('Work-life balance', '⚖️'),
  ('Exercise more', '💪'),
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TimeOfDay _wakeTime;
  late TimeOfDay _sleepTime;
  late Set<String> _selectedGoals;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _wakeTime = _parseTime(u?.wakeTime ?? '07:00');
    _sleepTime = _parseTime(u?.sleepTime ?? '23:00');
    _selectedGoals = Set.from(u?.goals ?? []);
    _nameCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _changed = true);

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(p[0]) ?? 7,
      minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isWake) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isWake ? _wakeTime : _sleepTime,
    );
    if (t != null) {
      setState(() {
        if (isWake) {
          _wakeTime = t;
        } else {
          _sleepTime = t;
        }
        _changed = true;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final u = ref.read(userProvider);
    if (u != null) {
      final updated = u.copyWith(
        name: name,
        wakeTime: _formatTime(_wakeTime),
        sleepTime: _formatTime(_sleepTime),
        goals: _selectedGoals.toList(),
      );
      await ref.read(userProvider.notifier).setUser(updated);
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _changed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isPro = user?.isPro ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.settings_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar ─────────────────────────────────────────────────────
            _AvatarSection(user: user, isPro: isPro)
                .animate()
                .fadeIn(duration: 350.ms),

            const SizedBox(height: 16),

            // ── Personal info ───────────────────────────────────────────────
            _SectionCard(
              title: 'Personal info',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  _InputField(
                    label: 'Full name',
                    controller: _nameCtrl,
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: 'Email',
                    controller: _emailCtrl,
                    icon: Icons.email_rounded,
                    readOnly: true,
                    hint: 'Cannot be changed',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePicker(
                          label: 'Wake up',
                          icon: Icons.wb_sunny_rounded,
                          time: _formatTime(_wakeTime),
                          iconColor: AppColors.warning,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimePicker(
                          label: 'Bedtime',
                          icon: Icons.bedtime_rounded,
                          time: _formatTime(_sleepTime),
                          iconColor: AppColors.primary,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

            const SizedBox(height: 12),

            // ── Goals ───────────────────────────────────────────────────────
            _SectionCard(
              title: 'My goals',
              icon: Icons.flag_rounded,
              subtitle: 'Select up to 3',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goalOptions.map((g) {
                  final label = g.$1;
                  final active = _selectedGoals.contains(label);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (active) {
                          _selectedGoals.remove(label);
                        } else if (_selectedGoals.length < 3) {
                          _selectedGoals.add(label);
                        }
                        _changed = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryLight
                            : AppColors.bgSurface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '${g.$2} $label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

            const SizedBox(height: 12),

            // ── Membership ──────────────────────────────────────────────────
            _MembershipCard(isPro: isPro)
                .animate()
                .fadeIn(delay: 140.ms, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Save button ─────────────────────────────────────────────────
            if (_changed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Save changes',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Avatar section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final AppUser? user;
  final bool isPro;
  const _AvatarSection({required this.user, required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.initials ?? 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (isPro)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            user?.email ?? '',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(
                label: 'Level ${user?.level ?? 1}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: user?.levelName ?? 'Beginner',
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: isPro ? 'Pro ⭐' : 'Free',
                color: isPro ? AppColors.warning : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (subtitle != null) ...[
                const Spacer(),
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;
  final String? hint;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.readOnly = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
              fontSize: 14,
              color:
                  readOnly ? AppColors.textMuted : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: readOnly ? AppColors.bgSurface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.element),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.element),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.element),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Time picker row ───────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.element),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(time,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Membership card ───────────────────────────────────────────────────────────

class _MembershipCard extends StatelessWidget {
  final bool isPro;
  const _MembershipCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPro ? AppColors.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isPro
              ? AppColors.primaryDark
              : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPro ? Icons.star_rounded : Icons.lock_outline_rounded,
                size: 16,
                color: isPro ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                'Membership',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isPro ? Colors.white : AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro
                      ? AppColors.warning
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPro ? '⭐ Pro' : 'Free',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPro
                          ? Colors.white
                          : AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPro) ...[
            Text(
              'You have access to all Pro features. Thank you for supporting FocusFlow!',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: Colors.white38),
                foregroundColor: Colors.white,
              ),
              child: const Text('Manage subscription'),
            ),
          ] else ...[
            const Text(
              'Upgrade to unlock unlimited habits, AI scheduling, full analytics and more.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.push('/upgrade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
              ),
              child: const Text('Upgrade to Pro',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
