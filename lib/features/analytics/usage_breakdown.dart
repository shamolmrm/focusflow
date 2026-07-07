import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/services/usage_service.dart';

// ── App brand registry ───────────────────────────────────────────────────────

class _Brand {
  final List<Color> colors;
  final String label; // short 1-2 char label shown in avatar
  const _Brand(this.colors, this.label);
}

const _brands = <String, _Brand>{
  'com.instagram.android':
      _Brand([Color(0xFF833AB4), Color(0xFFF77737)], 'IG'),
  'com.google.android.youtube':
      _Brand([Color(0xFFFF0000), Color(0xFFCC0000)], '▶'),
  'com.whatsapp':
      _Brand([Color(0xFF25D366), Color(0xFF075E54)], 'WA'),
  'com.facebook.katana':
      _Brand([Color(0xFF1877F2), Color(0xFF0860D9)], 'f'),
  'com.facebook.orca':
      _Brand([Color(0xFF0099FF), Color(0xFF0044CC)], 'm'),
  'com.twitter.android':
      _Brand([Color(0xFF1A1A2E), Color(0xFF16213E)], 'X'),
  'com.zhiliaoapp.musically':
      _Brand([Color(0xFF010101), Color(0xFFEE1D52)], 'TT'),
  'com.ss.android.ugc.trill':
      _Brand([Color(0xFF010101), Color(0xFFEE1D52)], 'TT'),
  'com.snapchat.android':
      _Brand([Color(0xFFFFD700), Color(0xFFFFA500)], 'SC'),
  'com.reddit.frontpage':
      _Brand([Color(0xFFFF4500), Color(0xFFCC3700)], 'Re'),
  'com.pinterest':
      _Brand([Color(0xFFE60023), Color(0xFFAD081B)], 'Pi'),
  'org.telegram.messenger':
      _Brand([Color(0xFF2AABEE), Color(0xFF229ED9)], 'Tg'),
  'com.spotify.music':
      _Brand([Color(0xFF1DB954), Color(0xFF0D7A3A)], '♪'),
  'com.netflix.mediaclient':
      _Brand([Color(0xFFE50914), Color(0xFF831010)], 'N'),
  'com.android.chrome':
      _Brand([Color(0xFF4285F4), Color(0xFF34A853)], 'Cr'),
  'com.google.android.gm':
      _Brand([Color(0xFFEA4335), Color(0xFF4285F4)], 'Gm'),
  'com.linkedin.android':
      _Brand([Color(0xFF0A66C2), Color(0xFF004182)], 'in'),
  'com.google.android.apps.maps':
      _Brand([Color(0xFF34A853), Color(0xFF4285F4)], '📍'),
  'com.microsoft.teams':
      _Brand([Color(0xFF6264A7), Color(0xFF33344A)], 'Te'),
  'com.slack':
      _Brand([Color(0xFF4A154B), Color(0xFF611f69)], 'Sl'),
};

// Fallback gradient palette (consistent per app name)
const _fallbackPalettes = [
  [Color(0xFF6C63FF), Color(0xFF3F3D56)],
  [Color(0xFF00C6FB), Color(0xFF005BEA)],
  [Color(0xFFf093fb), Color(0xFFf5576c)],
  [Color(0xFF4facfe), Color(0xFF00f2fe)],
  [Color(0xFF43e97b), Color(0xFF38f9d7)],
  [Color(0xFFfa709a), Color(0xFFfee140)],
  [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  [Color(0xFFfd7043), Color(0xFFff8a65)],
];

List<Color> _paletteFor(String name) {
  final idx =
      name.codeUnits.fold(0, (s, c) => s + c) % _fallbackPalettes.length;
  return _fallbackPalettes[idx];
}

// ── UsageBreakdown ────────────────────────────────────────────────────────────

class UsageBreakdown extends StatelessWidget {
  final List<AppEntry> entries;
  const UsageBreakdown({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: const Center(
          child: Text('No usage data for this period',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ),
      );
    }

    final maxMs = entries.first.usage.inMilliseconds.toDouble();
    final totalHours = entries.fold(0.0, (s, e) => s + e.hours);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          // Legend + total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                _LegendDot(color: AppColors.danger, label: 'Distracting'),
                const SizedBox(width: 14),
                _LegendDot(color: AppColors.primary, label: 'Productive'),
                const Spacer(),
                Text(
                  '${totalHours.toStringAsFixed(1)}h total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          ...entries.asMap().entries.map((map) {
            final i = map.key;
            final entry = map.value;
            final barColor =
                entry.isDistracting ? AppColors.danger : AppColors.primary;
            final frac = maxMs > 0
                ? entry.usage.inMilliseconds / maxMs
                : 0.0;
            final isLast = i == entries.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _AppIconWidget(entry: entry),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 82,
                        child: Text(
                          entry.appName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: frac),
                            duration:
                                Duration(milliseconds: 500 + i * 60),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              backgroundColor: AppColors.bgSurface,
                              valueColor:
                                  AlwaysStoppedAnimation(barColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: Text(
                          entry.timeDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── App icon ──────────────────────────────────────────────────────────────────

class _AppIconWidget extends StatelessWidget {
  final AppEntry entry;
  const _AppIconWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          entry.icon!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, s) => _GradientAvatar(entry: entry),
        ),
      );
    }
    return _GradientAvatar(entry: entry);
  }
}

class _GradientAvatar extends StatelessWidget {
  final AppEntry entry;
  const _GradientAvatar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final brand = _brands[entry.packageName];
    final colors = brand?.colors ?? _paletteFor(entry.appName);
    final label = brand?.label ??
        (entry.appName.isNotEmpty ? entry.appName[0].toUpperCase() : '?');

    // Snapchat label is dark text on yellow
    final textColor =
        entry.packageName == 'com.snapchat.android' ? Colors.black87 : Colors.white;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length == 1 ? 17 : 12,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
