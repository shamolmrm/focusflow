import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/models/planner_task.dart';

class DailyPlannerCard extends ConsumerStatefulWidget {
  const DailyPlannerCard({super.key});

  @override
  ConsumerState<DailyPlannerCard> createState() => _DailyPlannerCardState();
}

class _DailyPlannerCardState extends ConsumerState<DailyPlannerCard> {
  final _textCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showForm = false;
  PlannerTask? _editingTask;
  final Set<String> _deletingIds = {};

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _buildWithAI() async {
    final input = _textCtrl.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final tasks = await ref.read(apiServiceProvider).generateSchedule(
          input: input,
          wakeTime: ref.read(userProvider)?.wakeTime ?? '07:00',
          sleepTime: '22:00',
        );

    if (!mounted) return;
    ref.read(plannerTasksProvider.notifier).setFromAI(tasks);
    _textCtrl.clear();
    setState(() {
      _isLoading = false;
      _showForm = false;
      _editingTask = null;
    });
  }

  void _openForm({PlannerTask? task}) {
    setState(() {
      _editingTask = task;
      _showForm = true;
    });
  }

  void _handleFormSubmit(PlannerTask task) {
    if (_editingTask != null) {
      ref.read(plannerTasksProvider.notifier).editTask(task.id, task);
    } else {
      ref.read(plannerTasksProvider.notifier).addTask(task);
    }
    setState(() {
      _showForm = false;
      _editingTask = null;
    });
  }

  Future<void> _deleteTask(String id) async {
    setState(() => _deletingIds.add(id));
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    ref.read(plannerTasksProvider.notifier).deleteTask(id);
    setState(() => _deletingIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(plannerTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Planner card ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Daily planner',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppRadius.element),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tell me your plan for today...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Divider label
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'choose how to build',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const _LoadingState()
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _buildWithAI,
                        icon: const Icon(Icons.auto_awesome_rounded,
                            size: 16),
                        label: const Text('Build with AI',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.element)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add manually',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.element)),
                          side: const BorderSide(
                              color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ── Inline form ─────────────────────────────────────────────────────
        if (_showForm) ...[
          const SizedBox(height: 10),
          _InlineForm(
            key: ValueKey(_editingTask?.id ?? 'new'),
            initialTask: _editingTask,
            onSubmit: _handleFormSubmit,
            onCancel: () => setState(() {
              _showForm = false;
              _editingTask = null;
            }),
          ),
        ],

        // ── Task list ───────────────────────────────────────────────────────
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                "Today's schedule",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(plannerTasksProvider.notifier).clearAll();
                  setState(() {
                    _showForm = false;
                    _editingTask = null;
                  });
                },
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.asMap().entries.map((e) {
            final task = e.value;
            final i = e.key;
            return _TaskItem(
              task: task,
              deleting: _deletingIds.contains(task.id),
              onEdit: () => _openForm(task: task),
              onDelete: () => _deleteTask(task.id),
              onToggle: () => ref
                  .read(plannerTasksProvider.notifier)
                  .toggleComplete(task.id),
            )
                .animate()
                .fadeIn(delay: (i * 80).ms, duration: 300.ms)
                .slideX(begin: 0.04);
          }),
          const SizedBox(height: 8),

          // Add another task (dashed border)
          GestureDetector(
            onTap: () => _openForm(),
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Add another task',
                        style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Text(
            'Building your schedule...',
            style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(AppRadius.element),
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Inline task form ──────────────────────────────────────────────────────────

const _kCategories = ['work', 'health', 'learning', 'personal', 'break'];

class _InlineForm extends StatefulWidget {
  final PlannerTask? initialTask;
  final ValueChanged<PlannerTask> onSubmit;
  final VoidCallback onCancel;

  const _InlineForm({
    super.key,
    this.initialTask,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_InlineForm> createState() => _InlineFormState();
}

class _InlineFormState extends State<_InlineForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _durCtrl;
  late TimeOfDay _time;
  late String _cat;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _nameCtrl = TextEditingController(text: t?.task ?? '');
    _durCtrl =
        TextEditingController(text: '${t?.durationMinutes ?? 30}');
    _cat = t?.category ?? 'work';
    if (t != null) {
      final parts = t.time.split(':');
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
        minute: int.tryParse(
                parts.length > 1 ? parts[1] : '0') ??
            0,
      );
    } else {
      _time = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  String get _timeStr =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final dur = (int.tryParse(_durCtrl.text.trim()) ?? 30).clamp(1, 480);
    widget.onSubmit(PlannerTask(
      id: widget.initialTask?.id,
      time: _timeStr,
      task: name,
      durationMinutes: dur,
      category: _cat,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEditing ? 'Edit task' : 'New task',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onCancel,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Task name
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Task name',
              hintStyle:
                  const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppRadius.element),
                borderSide:
                    const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppRadius.element),
                borderSide:
                    const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppRadius.element),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          // Time + Duration
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context,
                        initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(
                          AppRadius.element),
                      border:
                          Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          _timeStr,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _durCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '30',
                    suffixText: 'min',
                    suffixStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.element),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.element),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.element),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kCategories.map((cat) {
                final active = _cat == cat;
                final color = PlannerTask.dotColor(cat);
                final bg = PlannerTask.badgeBg(cat);
                final label =
                    cat[0].toUpperCase() + cat.substring(1);
                return GestureDetector(
                  onTap: () => setState(() => _cat = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          active ? bg : AppColors.bgSurface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: active
                              ? color
                              : AppColors.border,
                          width: active ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: active
                                ? color
                                : AppColors.textMuted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppRadius.element)),
                  ),
                  child: Text(
                    isEditing ? 'Update task' : 'Add task',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppRadius.element)),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.04);
  }
}

// ── Task list item ────────────────────────────────────────────────────────────

class _TaskItem extends StatelessWidget {
  final PlannerTask task;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TaskItem({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    this.deleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = PlannerTask.dotColor(task.category);
    final badge = PlannerTask.badgeBg(task.category);

    return AnimatedOpacity(
      opacity: deleting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color:
              task.isCompleted ? AppColors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.element),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                task.time,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppColors.accent : dot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.task,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: task.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badge,
                borderRadius:
                    BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${task.durationMinutes}m',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dot),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit_rounded,
                    size: 15, color: AppColors.textMuted),
                onPressed: onEdit,
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_rounded,
                    size: 15, color: AppColors.danger),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
