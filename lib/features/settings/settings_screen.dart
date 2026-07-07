import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/services/storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _reminder;
  late String _reminderTime;
  late bool _haptic;
  late bool _sound;
  late bool _focusAlerts;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _reminder = StorageService.reminderEnabled;
    _reminderTime = StorageService.reminderTime;
    _haptic = StorageService.hapticEnabled;
    _sound = StorageService.soundEnabled;
    _focusAlerts = StorageService.focusAlerts;
    _darkMode = StorageService.darkMode;
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final init = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null && mounted) {
      final str =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = str);
      await StorageService.setReminderTime(str);
    }
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all data?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will delete all habits, tasks, focus history and your profile. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await StorageService.clearAllData();
      if (!mounted) return;
      ref.read(onboardingCompleteProvider.notifier).state = false;
      context.go('/onboarding');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

    final scaffoldBg = isDark ? AppDarkColors.bg : AppColors.bgSurface;
    final cardBg = isDark ? AppDarkColors.surface : Colors.white;
    final cardBorder = isDark ? AppDarkColors.border : AppColors.border;
    final titleColor = isDark ? AppDarkColors.text : AppColors.textPrimary;
    final subtitleColor = isDark ? AppDarkColors.textSecondary : AppColors.textMuted;
    final appBarBg = isDark ? AppDarkColors.surface : Colors.white;
    final backBtnBg = isDark ? AppDarkColors.surfaceHigh : AppColors.bgSurface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backBtnBg,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder),
            ),
            child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 20),
          ),
        ),
        title: Text('Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader('Appearance', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF7B68EE),
              title: 'Dark mode',
              subtitle: 'Switch to dark theme',
              value: _darkMode,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onChanged: (v) async {
                setState(() => _darkMode = v);
                await StorageService.setDarkMode(v);
                ref.read(themeModeProvider.notifier).state =
                    v ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ]),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionHeader('Notifications', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _SwitchTile(
              icon: Icons.notifications_rounded,
              iconColor: AppColors.primary,
              title: 'Daily reminder',
              subtitle: 'Get a reminder to plan your day',
              value: _reminder,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onChanged: (v) async {
                setState(() => _reminder = v);
                await StorageService.setReminderEnabled(v);
              },
            ),
            if (_reminder) ...[
              Divider(height: 1, indent: 56, color: cardBorder),
              _TapTile(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.warning,
                title: 'Reminder time',
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                trailing: Text(_reminderTime,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                onTap: _pickReminderTime,
              ),
            ],
          ]),

          // ── Focus ─────────────────────────────────────────────────────────
          _SectionHeader('Focus', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _SwitchTile(
              icon: Icons.vibration_rounded,
              iconColor: AppColors.accent,
              title: 'Haptic feedback',
              subtitle: 'Vibrate on actions',
              value: _haptic,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onChanged: (v) async {
                setState(() => _haptic = v);
                await StorageService.setHapticEnabled(v);
              },
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _SwitchTile(
              icon: Icons.music_note_rounded,
              iconColor: AppColors.accent,
              title: 'Focus sounds',
              subtitle: 'Play ambient audio during sessions',
              value: _sound,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onChanged: (v) async {
                setState(() => _sound = v);
                await StorageService.setSoundEnabled(v);
              },
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _SwitchTile(
              icon: Icons.shield_rounded,
              iconColor: AppColors.danger,
              title: 'Distraction alerts',
              subtitle: 'Alert when distracting apps are opened',
              value: _focusAlerts,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onChanged: (v) async {
                setState(() => _focusAlerts = v);
                await StorageService.setFocusAlerts(v);
              },
            ),
          ]),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader('Account', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _TapTile(
              icon: Icons.person_rounded,
              iconColor: AppColors.primary,
              title: 'Profile',
              subtitle: user?.name ?? '',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => context.push('/profile'),
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _TapTile(
              icon: Icons.star_rounded,
              iconColor: AppColors.warning,
              title: 'Membership',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (user?.isPro ?? false)
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : (isDark ? AppDarkColors.surfaceHigh : AppColors.bgSurface),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (user?.isPro ?? false) ? '⭐ Pro' : 'Free',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (user?.isPro ?? false)
                        ? AppColors.warning
                        : subtitleColor,
                  ),
                ),
              ),
              onTap: () => context.push('/upgrade'),
            ),
          ]),

          // ── Permissions ───────────────────────────────────────────────────
          _SectionHeader('Permissions', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _TapTile(
              icon: Icons.notifications_active_rounded,
              iconColor: AppColors.primary,
              title: 'Notifications',
              subtitle: 'Required for reminders & alerts',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              trailing: const _PermBadge(granted: true),
              onTap: () => openAppSettings(),
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _TapTile(
              icon: Icons.phone_android_rounded,
              iconColor: AppColors.accent,
              title: 'Usage access',
              subtitle: 'Required for app usage tracking',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              trailing: const _PermBadge(granted: false),
              onTap: () => openAppSettings(),
            ),
          ]),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader('About', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _TapTile(
              icon: Icons.star_border_rounded,
              iconColor: AppColors.warning,
              title: 'Rate FocusFlow',
              subtitle: 'Love the app? Leave a review',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.focusflow.focus_flow'),
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _TapTile(
              icon: Icons.privacy_tip_rounded,
              iconColor: subtitleColor,
              title: 'Privacy policy',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => _showInfoDialog(
                'Privacy Policy',
                'FocusFlow collects only the data needed to provide productivity features. '
                    'We never sell your data. All habit and focus data is stored locally on your device. '
                    '\n\nFor questions: support@focusflow.app',
              ),
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _TapTile(
              icon: Icons.description_rounded,
              iconColor: subtitleColor,
              title: 'Terms of service',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => _showInfoDialog(
                'Terms of Service',
                'By using FocusFlow you agree to use the app for personal productivity purposes only. '
                    'The app is provided "as is" without warranties. '
                    '\n\nFocusFlow Pro subscriptions auto-renew unless cancelled 24 hours before renewal.',
              ),
            ),
            Divider(height: 1, indent: 56, color: cardBorder),
            _TapTile(
              icon: Icons.info_outline_rounded,
              iconColor: subtitleColor,
              title: 'App version',
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              trailing: Text('1.0.0',
                  style: TextStyle(fontSize: 13, color: subtitleColor)),
              onTap: () {},
            ),
          ]),

          // ── Data ──────────────────────────────────────────────────────────
          _SectionHeader('Data', isDark),
          _SettingsCard(cardBg: cardBg, border: cardBorder, children: [
            _TapTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.danger,
              title: 'Clear all data',
              titleColor: AppColors.danger,
              subtitleColor: subtitleColor,
              subtitle: 'Deletes everything and resets app',
              onTap: _confirmClearData,
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader(this.title, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textMuted,
              letterSpacing: 0.8)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color cardBg;
  final Color border;
  const _SettingsCard({required this.children, required this.cardBg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color titleColor;
  final Color subtitleColor;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.titleColor,
    required this.subtitleColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color subtitleColor;

  const _TapTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.subtitleColor,
    this.titleColor,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ??
                              Theme.of(context).colorScheme.onSurface)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PermBadge extends StatelessWidget {
  final bool granted;
  const _PermBadge({required this.granted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        granted ? 'Allowed' : 'Denied',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: granted ? AppColors.accent : AppColors.danger),
      ),
    );
  }
}
