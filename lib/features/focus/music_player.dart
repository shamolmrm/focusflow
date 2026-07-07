import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';

const _builtInTracks = <(String, IconData)>[
  ('Lo-fi beats', Icons.music_note_rounded),
  ('Binaural alpha', Icons.graphic_eq_rounded),
  ('White noise', Icons.waves_rounded),
  ('Rain sounds', Icons.water_drop_rounded),
  ('Forest', Icons.forest_rounded),
  ('Ocean waves', Icons.beach_access_rounded),
  ('Cafe vibes', Icons.coffee_rounded),
  ('Fireplace', Icons.local_fire_department_rounded),
  ('Silent', Icons.volume_off_rounded),
];

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key});

  void _showAddTrackDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add custom sound',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give your custom sound a name:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. My playlist',
                prefixIcon: Icon(Icons.headphones_rounded, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(customTracksProvider.notifier).update(
                      (list) => [...list, name],
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => nameCtrl.dispose());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTrackProvider);
    final customTracks = ref.watch(customTracksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xFF2D2D50) : AppColors.border;
    final titleColor = isDark ? AppDarkColors.text : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus sounds',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Built-in tracks
              ..._builtInTracks.asMap().entries.map((e) {
                final i = e.key;
                final (label, icon) = e.value;
                final active = i == selected;
                return _TrackChip(
                  label: label,
                  icon: icon,
                  active: active,
                  inactiveBg: inactiveBg,
                  inactiveBorder: inactiveBorder,
                  onTap: () =>
                      ref.read(selectedTrackProvider.notifier).state = i,
                );
              }),

              // Custom tracks
              ...customTracks.asMap().entries.map((e) {
                final i = _builtInTracks.length + e.key;
                final label = e.value;
                final active = i == selected;
                return _TrackChip(
                  label: label,
                  icon: Icons.headphones_rounded,
                  active: active,
                  inactiveBg: inactiveBg,
                  inactiveBorder: inactiveBorder,
                  onTap: () =>
                      ref.read(selectedTrackProvider.notifier).state = i,
                );
              }),

              // Add custom "+" button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _showAddTrackDialog(context, ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: inactiveBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 15, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Add sound',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color inactiveBg;
  final Color inactiveBorder;
  final VoidCallback onTap;

  const _TrackChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.inactiveBg,
    required this.inactiveBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : inactiveBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active ? AppColors.primary : inactiveBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      active ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
