import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/album.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/track.dart';
import 'art_tile.dart';
import 'track_row.dart';

class AlbumDetailSheet extends ConsumerWidget {
  const AlbumDetailSheet({
    super.key,
    required this.album,
  });

  final Album album;

  static void show(BuildContext context, Album album) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlbumDetailSheet(album: album),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(libraryRepositoryProvider);
    final audio = ref.watch(audioServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);

    final previewTrack = Track(
      id: album.id,
      title: album.title,
      artist: album.albumArtist ?? 'Unknown Artist',
      album: album.title,
      duration: Duration.zero,
      artHash: album.artHash,
    );

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
          // Album header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                SizedBox(
                  width: 80.0,
                  height: 80.0,
                  child: ArtTile(
                    track: previewTrack,
                    radius: AppRadii.card,
                    shadow: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        album.albumArtist ?? 'Unknown Artist',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
          // Track list
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: repo.getTracksForAlbum(album.id),
              builder: (context, snapshot) {
                final dbTracks = snapshot.data ?? [];
                // Fallback to fakeTracks matching album or fakeTracks subset if DB is empty
                final tracks = dbTracks.isNotEmpty
                    ? dbTracks
                    : fakeTracks.where((t) => t.album == album.title).toList();
                final displayTracks = tracks.isNotEmpty ? tracks : fakeTracks;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  itemCount: displayTracks.length,
                  itemBuilder: (context, i) {
                    final t = displayTracks[i];
                    final isCurrent = currentTrack?.id == t.id;
                    return TrackRow(
                      track: t,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying,
                      accentColor: palette.light,
                      onTap: () {
                        audio.setQueue(displayTracks, index: i);
                        Navigator.of(context).pop();
                      },
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

class ArtistDetailSheet extends ConsumerWidget {
  const ArtistDetailSheet({
    super.key,
    required this.artist,
  });

  final Artist artist;

  static void show(BuildContext context, Artist artist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArtistDetailSheet(artist: artist),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(libraryRepositoryProvider);
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
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, size: 32.0, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: repo.getTracksForArtist(artist.name),
              builder: (context, snapshot) {
                final dbTracks = snapshot.data ?? [];
                final tracks = dbTracks.isNotEmpty
                    ? dbTracks
                    : fakeTracks.where((t) => t.artist == artist.name).toList();
                final displayTracks = tracks.isNotEmpty ? tracks : fakeTracks;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  itemCount: displayTracks.length,
                  itemBuilder: (context, i) {
                    final t = displayTracks[i];
                    final isCurrent = currentTrack?.id == t.id;
                    return TrackRow(
                      track: t,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying,
                      accentColor: palette.light,
                      onTap: () {
                        audio.setQueue(displayTracks, index: i);
                        Navigator.of(context).pop();
                      },
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
