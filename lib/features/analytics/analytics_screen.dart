import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/services/usage_service.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/stat_card.dart';
import 'bar_chart.dart';
import 'usage_breakdown.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

// 'all' | 'wasted' | 'productive'
class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _view = 'week';
  String _filter = 'all';

  List<AppEntry> _applyFilter(List<AppEntry> entries) {
    switch (_filter) {
      case 'wasted':
        return entries.where((e) => e.isDistracting).toList();
      case 'productive':
        return entries.where((e) => !e.isDistracting).toList();
      default:
        return entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekData = ref.watch(weeklyFocusProvider);
    final insights = ref.watch(aiInsightsProvider);
    final isMonthly = _view == 'month';
    final appUsageAsync = ref.watch(appUsageProvider(isMonthly));

    final todayFocus = StorageService.getTodayFocusHours();
    final totalFocus = weekData.fold(0.0, (a, b) => a + b);

    // Compute wasted + productive % from real data when available
    final (wastedHours, pct) = appUsageAsync.whenOrNull(
          data: (entries) {
            final wasted = entries
                .where((e) => e.isDistracting)
                .fold(0.0, (s, e) => s + e.hours);
            final productive = totalFocus;
            final total = productive + wasted;
            final p = total > 0 ? ((productive / total) * 100).round() : 0;
            return (wasted, p);
          },
        ) ??
        (0.0, totalFocus > 0 ? 100 : 0);

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
                    Text(
                      _view == 'week' ? 'This week' : 'This month',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _ViewToggle(
                      selected: _view,
                      onChanged: (v) => setState(() => _view = v),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Focus today',
                        value: '${todayFocus.toStringAsFixed(1)}h',
                        icon: Icons.timer_rounded,
                        color: AppColors.primary,
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ).animate().fadeIn(duration: 350.ms),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Wasted time',
                        value: '${wastedHours.toStringAsFixed(1)}h',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.warning,
                        selected: _filter == 'wasted',
                        onTap: () => setState(() => _filter = 'wasted'),
                      ).animate().fadeIn(delay: 60.ms, duration: 350.ms),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Productive',
                        value: '$pct%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.accent,
                        selected: _filter == 'productive',
                        onTap: () => setState(() => _filter = 'productive'),
                      ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bar chart ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border:
                        Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Focus hours',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${totalFocus.toStringAsFixed(1)}h total',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FocusBarChart(data: weekData),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
              ),
            ),

            // ── App usage header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'App usage breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _view == 'week' ? 'Last 7 days' : 'Last 30 days',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── App usage breakdown (real data) ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: appUsageAsync.when(
                  loading: () => const _UsageLoadingCard(),
                  error: (e, _) => e.toString() == 'no_permission'
                      ? const _PermissionCard()
                      : _ErrorCard(message: e.toString()),
                  data: (entries) => UsageBreakdown(entries: _applyFilter(entries))
                      .animate()
                      .fadeIn(delay: 220.ms, duration: 350.ms),
                ),
              ),
            ),

            // ── AI Insights ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'AI insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Claude',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, i < insights.length - 1 ? 8 : 0),
                  child: _InsightCard(text: insights[i])
                      .animate()
                      .fadeIn(delay: (260 + i * 60).ms, duration: 350.ms),
                ),
                childCount: insights.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

// ── Permission card ───────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: AppColors.warning, size: 22),
              SizedBox(width: 10),
              Text(
                'Usage access needed',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'To show real app usage data, FocusFlow needs access to your phone\'s usage statistics.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => UsageService.openSettings(),
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Enable usage access'),
          ),
        ],
      ),
    );
  }
}

// ── Loading card ──────────────────────────────────────────────────────────────

class _UsageLoadingCard extends StatelessWidget {
  const _UsageLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading app usage...',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text('Could not load usage data',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 13)),
    );
  }
}

// ── View toggle ───────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ViewToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: ['Week', 'Month'].map((label) {
          final active = selected == label.toLowerCase();
          return GestureDetector(
            onTap: () => onChanged(label.toLowerCase()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Insight card ──────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
