import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/services/storage_service.dart';

const _features = <(String, String)>[
  ('Unlimited habits', 'Free plan limited to 3'),
  ('AI daily scheduler', 'Claude-powered smart planning'),
  ('Full analytics & reports', 'Weekly & monthly breakdowns'),
  ('Distraction blocker', 'Real-time alerts during focus'),
  ('Premium focus sounds', 'Hi-fi audio packs for deep work'),
  ('Custom AI coach tone', 'Motivating, calm, or direct'),
  ('Priority support', 'Response within 24 hours'),
];

class PaywallWidget extends ConsumerStatefulWidget {
  const PaywallWidget({super.key});

  @override
  ConsumerState<PaywallWidget> createState() => _PaywallWidgetState();
}

class _PaywallWidgetState extends ConsumerState<PaywallWidget> {
  bool _annual = true;
  bool _loading = false;
  bool _restoring = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    // Replace with actual RevenueCat purchase call
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await StorageService.setPro(true);
    ref.read(userProvider.notifier).setPro(true);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Text('🎉 Welcome to FocusFlow Pro!'),
        ]),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No active subscription found'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          // ── Hero ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⭐ Most popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FocusFlow Pro',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Price toggle
                _PriceToggle(
                  annual: _annual,
                  onChanged: (v) => setState(() => _annual = v),
                ),

                const SizedBox(height: 12),
                Text(
                  _annual
                      ? 'That\'s just \$1.67/month, billed annually'
                      : 'Cancel anytime from your app store',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),

          const SizedBox(height: 20),

          // ── Feature list ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Everything in Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._features.asMap().entries.map((e) {
                  final (title, sub) = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: AppColors.accent, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                sub,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: (100 + e.key * 50).ms),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

          const SizedBox(height: 24),

          // ── CTAs ─────────────────────────────────────────────────────────
          ElevatedButton(
            onPressed: _loading ? null : _subscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 54),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    _annual
                        ? 'Start 7-day free trial — \$19.99/yr'
                        : 'Start 7-day free trial — \$2.99/mo',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('Continue with free plan'),
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 16),

          // Fine print + restore
          Column(
            children: [
              const Text(
                'Cancel anytime. No charge during 7-day trial.\nSubscription auto-renews unless cancelled.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _restoring ? null : _restore,
                child: Text(
                  _restoring ? 'Restoring...' : 'Restore purchases',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 280.ms),
        ],
      ),
    );
  }
}

// ── Price toggle ─────────────────────────────────────────────────────────────

class _PriceToggle extends StatelessWidget {
  final bool annual;
  final ValueChanged<bool> onChanged;

  const _PriceToggle({required this.annual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Pill(
            title: '\$2.99',
            sub: 'Monthly',
            active: !annual,
            onTap: () => onChanged(false),
          ),
          _Pill(
            title: '\$19.99',
            sub: 'Annual · Save 44%',
            active: annual,
            badge: 'Best value',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String title;
  final String sub;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _Pill({
    required this.title,
    required this.sub,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color:
                      active ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                badge != null && active ? badge! : sub,
                style: TextStyle(
                  fontSize: 11.5,
                  color: active
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
