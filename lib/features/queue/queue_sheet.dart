import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/art_tile.dart';
import '../../shared/widgets/glass_panel.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueStateProvider).value;
    final palette = ref.watch(currentPaletteProvider);
    final audioService = ref.read(audioServiceProvider);

    final tracks = queue?.tracks ?? [];
    final currentIndex = queue?.currentIndex ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => GlassPanel(
        backgroundColor: palette.deep.withValues(alpha: 0.88),
        borderRadius: AppRadii.brSheet,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s12),
            // Drag handle
            Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                borderRadius: AppRadii.brFull,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    '${tracks.length} tracks',
                    style: AppTypography.captionMuted,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s8,
                  AppSpacing.s4,
                  AppSpacing.s8,
                  AppSpacing.s24,
                ),
                itemCount: tracks.length,
                onReorderItem: (oldIndex, newIndex) {
                  audioService.move(oldIndex, newIndex);
                },
                itemBuilder: (context, i) {
                  final track = tracks[i];
                  final isCurrent = i == currentIndex;

                  return Dismissible(
                    key: ValueKey('queue_${track.id}_$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.s24),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: AppRadii.brCard,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 22.0,
                      ),
                    ),
                    onDismissed: (_) {
                      audioService.removeAt(i);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Material(
                        color: isCurrent
                            ? palette.mid.withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: AppRadii.brCard,
                        child: InkWell(
                          borderRadius: AppRadii.brCard,
                          onTap: () => audioService.jumpTo(i),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48.0,
                                  height: 48.0,
                                  child: ArtTile(
                                    track: track,
                                    radius: AppRadii.small,
                                    shadow: false,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body.copyWith(
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? palette.light
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                Text(
                                  Formatters.formatDuration(track.duration),
                                  style: AppTypography.captionMuted,
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.s4),
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      size: 20.0,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
