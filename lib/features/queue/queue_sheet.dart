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
      initialChildSize: 0.62,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => GlassPanel(
        backgroundColor: palette.deep.withValues(alpha: 0.85),
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
                borderRadius: BorderRadius.circular(2.0),
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
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s12,
                  AppSpacing.s4,
                  AppSpacing.s12,
                  AppSpacing.s24,
                ),
                itemCount: tracks.length,
                itemBuilder: (context, i) {
                  final track = tracks[i];
                  final isCurrent = i == currentIndex;

                  return InkWell(
                    borderRadius: AppRadii.brCard,
                    onTap: () {
                      audioService.jumpTo(i);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52.0,
                            height: 52.0,
                            child: ArtTile(
                              track: track,
                              radius: AppRadii.small,
                              shadow: false,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s16),
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
                        ],
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
