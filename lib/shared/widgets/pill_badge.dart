import 'package:flutter/material.dart';
import '../../app/theme.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isLocked;

  const PillBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLocked
        ? AppColors.bgSurface
        : (color ?? AppColors.primaryLight);
    final fg = isLocked
        ? AppColors.textMuted
        : (textColor ?? AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isLocked ? AppColors.border : fg.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            Icon(Icons.lock_outline, size: 12, color: fg),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
