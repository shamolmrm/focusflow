import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/session.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'timer_ring.dart';
import 'music_player.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  late ConfettiController _confetti;
  bool _showComplete = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    ref.read(sessionProvider.notifier).start();
  }

  void _pause() {
    HapticFeedback.lightImpact();
    ref.read(sessionProvider.notifier).pause();
  }

  void _reset() {
    ref.read(sessionProvider.notifier).reset();
    setState(() => _showComplete = false);
  }

  void _startBreak() {
    setState(() => _showComplete = false);
    ref.read(sessionProvider.notifier).startBreak();
  }

  void _showDurationSheet() {
    final session = ref.read(sessionProvider);
    showDialog<int>(
      context: context,
      builder: (_) => _DurationDialog(initialMinutes: session.workMinutes),
    ).then((v) {
      if (v != null && mounted) {
        ref.read(sessionProvider.notifier)
            .setDuration(v, session.breakMinutes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // React to session completion without a Timer in the screen
    ref.listen<FocusSession>(sessionProvider, (prev, next) {
      if (next.isCompleted && !(prev?.isCompleted ?? false)) {
        HapticFeedback.heavyImpact();
        ref.read(userProvider.notifier).addXp(next.xpEarned);
        _confetti.play();
        if (mounted) setState(() => _showComplete = true);
      }
      if (!next.isOnBreak && (prev?.isOnBreak ?? false)) {
        // Break ended automatically — restart if needed
      }
    });

    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main content ─────────────────────────────────────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Focus session',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (session.completedPomodoros > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_rounded,
                                    color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.completedPomodoros} sessions',
                                  style: const TextStyle(
                                    fontSize: 12,
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

                // Duration picker
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _DurationPicker(
                      selectedMinutes: session.workMinutes,
                      onChanged: (m) => ref
                          .read(sessionProvider.notifier)
                          .setDuration(m, session.breakMinutes),
                      enabled: session.isIdle,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                ),

                // Timer ring
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: TimerRing(
                        progress: session.progress,
                        timeDisplay: session.timeDisplay,
                        taskName: session.taskName,
                        isBreak: session.isOnBreak,
                        onTap: session.isIdle ? _showDurationSheet : null,
                      ),
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                ),

                // Task name input (only when idle or paused)
                if (session.isIdle || session.isPaused)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: _TaskInput(
                        initialValue: session.taskName,
                        onChanged: (v) =>
                            ref.read(sessionProvider.notifier).updateTaskName(v),
                      ),
                    ).animate().fadeIn(delay: 120.ms),
                  ),

                // Music selector
                SliverToBoxAdapter(
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: MusicPlayer(),
                  ).animate().fadeIn(delay: 160.ms),
                ),

                // Controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        if (!session.isIdle)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reset,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset', maxLines: 1),
                            ),
                          ),
                        if (!session.isIdle) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: session.isRunning ? _pause : _start,
                            icon: Icon(
                              session.isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                            ),
                            label: Text(
                              session.isRunning
                                  ? 'Pause'
                                  : session.isPaused
                                      ? 'Resume'
                                      : session.isOnBreak
                                          ? 'Break...'
                                          : 'Start session',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),

                // Distraction alerts
                if (session.distractionAlerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _DistractionCard(
                        appName: session.distractionAlerts.last,
                        count: session.distractionAlerts.length,
                        onDismiss: _reset,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),

            // ── Confetti ─────────────────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                colors: const [
                  AppColors.primary,
                  AppColors.accent,
                  AppColors.warning,
                  AppColors.danger,
                ],
              ),
            ),

            // ── Session complete overlay ──────────────────────────────────────
            if (_showComplete)
              _CompleteOverlay(
                xpEarned: ref.read(sessionProvider).xpEarned,
                onBreak: _startBreak,
                onSkip: _reset,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

// ── Duration picker ──────────────────────────────────────────────────────────

class _DurationPicker extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const _DurationPicker({
    required this.selectedMinutes,
    required this.onChanged,
    required this.enabled,
  });

  static const _presets = [15, 25, 45, 60, 90];

  void _showCustomDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom duration',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Minutes (5–300)',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 5 && v <= 300) Navigator.pop(ctx, v);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    ).then((v) {
      ctrl.dispose();
      if (v != null) onChanged(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = !_presets.contains(selectedMinutes);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xFF2D2D50) : AppColors.border;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._presets.map((m) {
            final active = m == selectedMinutes;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: enabled ? () => onChanged(m) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : inactiveBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active ? AppColors.primary : inactiveBorder,
                    ),
                  ),
                  child: Text(
                    '${m}min',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom chip
          GestureDetector(
            onTap: enabled ? () => _showCustomDialog(context) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isCustom ? AppColors.primary : inactiveBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isCustom ? AppColors.primary : inactiveBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded,
                      size: 13,
                      color: isCustom
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    isCustom ? '${selectedMinutes}min' : 'Custom',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isCustom ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task name input ──────────────────────────────────────────────────────────

class _TaskInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TaskInput({required this.initialValue, required this.onChanged});

  @override
  State<_TaskInput> createState() => _TaskInputState();
}

class _TaskInputState extends State<_TaskInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        hintText: 'What are you working on?',
        prefixIcon:
            Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}

// ── Distraction card ─────────────────────────────────────────────────────────

class _DistractionCard extends StatelessWidget {
  final String appName;
  final int count;
  final VoidCallback onDismiss;

  const _DistractionCard({
    required this.appName,
    required this.count,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You opened $appName — $count distraction${count > 1 ? 's' : ''} this session',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Session complete overlay ─────────────────────────────────────────────────

class _CompleteOverlay extends StatelessWidget {
  final int xpEarned;
  final VoidCallback onBreak;
  final VoidCallback onSkip;

  const _CompleteOverlay({
    required this.xpEarned,
    required this.onBreak,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                const Text(
                  'Session complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$xpEarned XP earned!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onBreak,
                  icon: const Icon(Icons.coffee_rounded, size: 18),
                  label: const Text('Take a 5-min break'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onSkip,
                  child: const Text(
                    'Skip break',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ).animate().scale(
              begin: const Offset(0.85, 0.85),
              duration: 300.ms,
              curve: Curves.easeOutBack),
        ),
      ),
    );
  }
}

// ── Duration dialog ──────────────────────────────────────────────────────────

class _DurationDialog extends StatefulWidget {
  final int initialMinutes;
  const _DurationDialog({required this.initialMinutes});

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialMinutes.toString());
    _ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(_ctrl.text.trim());
    if (v != null && v >= 1) Navigator.pop(context, v.clamp(1, 300));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      title: const Text('Set duration',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 25, 45, 60, 90].map((m) {
              return GestureDetector(
                onTap: () {
                  _ctrl.text = m.toString();
                  _ctrl.selection = TextSelection(
                      baseOffset: 0, extentOffset: _ctrl.text.length);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text('${m}min',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
            decoration: const InputDecoration(
              hintText: '25',
              suffixText: 'min',
              suffixStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 4),
          const Text('1 – 300 minutes',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12)),
          onPressed: _submit,
          child: const Text('Set'),
        ),
      ],
    );
  }
}
