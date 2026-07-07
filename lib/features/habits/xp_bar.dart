import 'package:flutter/material.dart';
import '../../app/theme.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int targetXp;

  const XpBar({super.key, required this.currentXp, required this.targetXp});

  @override
  Widget build(BuildContext context) {
    final progress =
        targetXp > 0 ? (currentXp / targetXp).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${_fmt(currentXp)} / ${_fmt(targetXp)} XP',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$pct% to next level',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, val, _) => LinearProgressIndicator(
              value: val,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int xp) =>
      xp >= 1000 ? '${(xp / 1000).toStringAsFixed(1)}k' : '$xp';
}
