import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';
import 'track_context_menu.dart';
import 'track_row.dart';

class PlaylistDetailSheet extends ConsumerWidget {
  const PlaylistDetailSheet({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  static void show(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaylistDetailSheet(playlist: playlist),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: playlist.name);
    final playlistRepo = ref.read(playlistRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brSheet),
        title: Text('Rename Playlist', style: AppTypography.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.captionMuted),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await playlistRepo.renamePlaylist(playlist.id, newName);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text('Rename', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final playlistRepo = ref.read(playlistRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brSheet),
        title: Text('Delete Playlist', style: AppTypography.title),
        content: Text('Are you sure you want to delete "${playlist.name}"?', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.captionMuted),
          ),
          TextButton(
            onPressed: () async {
              await playlistRepo.deletePlaylist(playlist.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text('Delete', style: AppTypography.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final audio = ref.watch(audioServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.s12, bottom: AppSpacing.s8),
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadii.brFull,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
            child: Row(
              children: [
                Container(
                  width: 52.0,
                  height: 52.0,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.brCard,
                  ),
                  child: const Icon(Icons.queue_music_rounded, color: AppColors.accentFallback, size: 28.0),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.name, style: AppTypography.title),
                      const SizedBox(height: 2.0),
                      Text('Playlist', style: AppTypography.captionMuted),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rename',
                  icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20.0),
                  onPressed: () => _showRenameDialog(context, ref),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20.0),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: playlistRepo.getPlaylistTracks(playlist.id),
              builder: (context, snapshot) {
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) {
                  return Center(
                    child: Text('No tracks in this playlist yet', style: AppTypography.captionMuted),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  itemCount: tracks.length,
                  itemBuilder: (context, i) {
                    final t = tracks[i];
                    final isCurrent = currentTrack?.id == t.id;

                    return TrackRow(
                      track: t,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying,
                      accentColor: palette.light,
                      onTap: () {
                        audio.setQueue(tracks, index: i);
                        Navigator.of(context).pop();
                      },
                      onLongPress: () => TrackContextMenu.show(context, t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
