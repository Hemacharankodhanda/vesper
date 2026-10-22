import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../domain/models/track.dart';
import 'art_tile.dart';

class TrackContextMenu extends ConsumerWidget {
  const TrackContextMenu({
    super.key,
    required this.track,
  });

  final Track track;

  static void show(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackContextMenu(track: track),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.read(playlistsProvider);
    final playlistRepo = ref.read(playlistRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brSheet),
        title: Text('Add to Playlist', style: AppTypography.title),
        content: SizedBox(
          width: 320.0,
          child: playlistsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentFallback),
              ),
            ),
            error: (_, _) => const Text('Could not load playlists'),
            data: (playlists) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_rounded, color: AppColors.accentFallback),
                    title: Text('New playlist', style: AppTypography.body),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      _showCreatePlaylistDialog(context, ref, initialTrackId: track.id);
                    },
                  ),
                  const Divider(color: Color(0x1AFFFFFF)),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, i) {
                        final pl = playlists[i];
                        return ListTile(
                          leading: const Icon(Icons.queue_music_rounded, color: AppColors.textSecondary),
                          title: Text(pl.name, style: AppTypography.body),
                          onTap: () async {
                            await playlistRepo.addTrackToPlaylist(pl.id, track.id);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to ${pl.name}')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref, {String? initialTrackId}) {
    final controller = TextEditingController();
    final playlistRepo = ref.read(playlistRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brSheet),
        title: Text('New Playlist', style: AppTypography.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: AppTypography.captionMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.captionMuted),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final created = await playlistRepo.createPlaylist(name);
                if (initialTrackId != null) {
                  await playlistRepo.addTrackToPlaylist(created.id, initialTrackId);
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              }
            },
            child: Text('Create', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final libraryRepo = ref.watch(libraryRepositoryProvider);
    final likedNotifier = ref.watch(likedTracksProvider.notifier);
    final isLiked = ref.watch(likedTracksProvider).contains(track.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
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
                        style: AppTypography.title.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
          // Options
          ListTile(
            leading: const Icon(Icons.playlist_play_rounded, color: AppColors.textPrimary),
            title: Text('Play next', style: AppTypography.body),
            onTap: () {
              audio.playNext(track);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded, color: AppColors.textPrimary),
            title: Text('Add to end of queue', style: AppTypography.body),
            onTap: () {
              audio.addToEnd(track);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded, color: AppColors.textPrimary),
            title: Text('Add to playlist', style: AppTypography.body),
            onTap: () {
              Navigator.of(context).pop();
              _showAddToPlaylistDialog(context, ref);
            },
          ),
          ListTile(
            leading: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? AppColors.accentFallback : AppColors.textPrimary,
            ),
            title: Text(isLiked ? 'Remove from liked' : 'Like song', style: AppTypography.body),
            onTap: () async {
              likedNotifier.toggle(track.id);
              await libraryRepo.toggleLike(track.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
