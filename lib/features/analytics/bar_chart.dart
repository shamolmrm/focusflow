import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';

class FocusBarChart extends StatelessWidget {
  final List<double> data;
  const FocusBarChart({super.key, required this.data});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1; // 0=Mon
    final maxY = data.isEmpty
        ? 8.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble().clamp(4.0, 12.0);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 4,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}h',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _days.length) {
                    return const SizedBox.shrink();
                  }
                  final isToday = i == today;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(data.length, (i) {
            final isToday = i == today;
            final isPast = i < today;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i],
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7)),
                  color: isToday
                      ? AppColors.primary
                      : isPast
                          ? AppColors.primary.withValues(alpha: 0.28)
                          : AppColors.border.withValues(alpha: 0.5),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryDark,
              tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}h',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
