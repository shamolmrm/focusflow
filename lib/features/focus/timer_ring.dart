import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class TimerRing extends StatelessWidget {
  final double progress;
  final String timeDisplay;
  final String taskName;
  final bool isBreak;
  final VoidCallback? onTap;

  const TimerRing({
    super.key,
    required this.progress,
    required this.timeDisplay,
    required this.taskName,
    this.isBreak = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isBreak ? AppColors.accent : AppColors.primary;
    const size = 240.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ring
            CustomPaint(
              size: const Size(size, size),
              painter: _RingPainter(
                progress: progress,
                ringColor: ringColor,
                trackColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D2D50)
                    : AppColors.bgSurface,
              ),
            ),

            // Inner content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBreak)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Break time',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                if (isBreak) const SizedBox(height: 6),

                // Time text — shows pencil icon when tappable
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: ringColor,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    if (onTap != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Icon(Icons.edit_rounded,
                            size: 14,
                            color: ringColor.withValues(alpha: 0.6)),
                      ),
                  ],
                ),

                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: ringColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isBreak ? 'Relax & recharge' : taskName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ringColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

                // Tap hint
                if (onTap != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'tap to change',
                    style: TextStyle(
                      fontSize: 10,
                      color: ringColor.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 20) / 2;
    const stroke = 14.0;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
