import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/platform/folder_picker.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/album.dart';
import '../../domain/models/track.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/art_tile.dart';
import '../../shared/widgets/detail_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/track_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickFolder(WidgetRef ref) async {
    final path = await FolderPickerService.pickFolder();
    if (path != null) {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.addFolder(path);
      repo.scanAllFolders().listen((_) {});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(libraryTracksProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: tracksAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.s16,
            ),
            children: const [
              ShimmerSkeletonRow(),
              SizedBox(height: AppSpacing.s16),
              ShimmerSkeletonRow(),
              SizedBox(height: AppSpacing.s16),
              ShimmerSkeletonRow(),
            ],
          ),
          error: (_, _) => const EmptyState(message: 'Could not load library'),
          data: (dbTracks) {
            final allTracks = dbTracks.isNotEmpty ? dbTracks : fakeTracks;

            if (allTracks.isEmpty) {
              return EmptyState(
                message: 'Your music will appear here',
                actionLabel: 'Add Music Folder',
                onAction: () => _pickFolder(ref),
              );
            }

            final heroTrack = currentTrack ?? allTracks.first;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s24,
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s16,
                    ),
                    child: Text('Listen Now', style: AppTypography.display),
                  ),
                ),
                // 1. Continue Listening Hero Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingMobile,
                    ),
                    child: _buildContinueListeningCard(
                      context,
                      heroTrack,
                      isPlaying: isPlaying && currentTrack?.id == heroTrack.id,
                      accentColor: palette.light,
                      onPlay: () {
                        if (currentTrack?.id == heroTrack.id) {
                          audio.toggle();
                        } else {
                          audio.setQueue(
                            allTracks,
                            index: allTracks
                                .indexOf(heroTrack)
                                .clamp(0, allTracks.length - 1),
                          );
                        }
                      },
                    ),
                  ),
                ),
                // 2. Recently Added Carousel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s32,
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s16,
                    ),
                    child: Text('Recently added', style: AppTypography.title),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildRecentlyAdded(
                    context,
                    recentlyAddedAsync,
                    allTracks,
                  ),
                ),
                // 3. Recently Played List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s32,
                      AppSpacing.screenPaddingMobile,
                      AppSpacing.s12,
                    ),
                    child: Text('Recently played', style: AppTypography.title),
                  ),
                ),
                ..._buildRecentlyPlayedSlivers(
                  context,
                  recentlyPlayedAsync,
                  allTracks,
                  currentTrack,
                  isPlaying,
                  palette.light,
                  audio,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96.0)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueListeningCard(
    BuildContext context,
    Track track, {
    required bool isPlaying,
    required Color accentColor,
    required VoidCallback onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.brHero,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          SizedBox(
            width: 88.0,
            height: 88.0,
            child: ArtTile(track: track, radius: AppRadii.card, shadow: true),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CONTINUE LISTENING',
                  style: AppTypography.captionMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(fontSize: 18),
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
          const SizedBox(width: AppSpacing.s12),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 52.0,
              height: 52.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.bg,
                size: 32.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAdded(
    BuildContext context,
    AsyncValue<List<Track>> recentlyAddedAsync,
    List<Track> allTracks,
  ) {
    return SizedBox(
      height: 196.0,
      child: recentlyAddedAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingMobile,
          ),
          itemCount: 4,
          itemBuilder: (_, _) => Container(
            width: 140.0,
            margin: const EdgeInsets.only(right: AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.brCard,
            ),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (recentTracks) {
          final tracks = recentTracks.isNotEmpty ? recentTracks : allTracks;
          // Build albums from tracks
          final albumsMap = <String, Album>{};
          for (final t in tracks) {
            albumsMap.putIfAbsent(
              t.album,
              () => Album(
                id: t.album,
                title: t.album,
                albumArtist: t.artist,
                artHash: t.artHash,
              ),
            );
          }
          final albums = albumsMap.values.toList();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
            ),
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
            itemBuilder: (context, i) {
              final album = albums[i];
              return AlbumCard(
                album: album,
                onTap: () => AlbumDetailSheet.show(context, album),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildRecentlyPlayedSlivers(
    BuildContext context,
    AsyncValue<List<Track>> recentlyPlayedAsync,
    List<Track> allTracks,
    Track? currentTrack,
    bool isPlaying,
    Color accentColor,
    dynamic audio,
  ) {
    return [
      recentlyPlayedAsync.when(
        loading: () => const SliverToBoxAdapter(child: ShimmerSkeletonRow()),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (recentPlayed) {
          final tracks = recentPlayed.isNotEmpty
              ? recentPlayed.take(6).toList()
              : allTracks.take(4).toList();

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, i) {
              final track = tracks[i];
              final isCurrent = currentTrack?.id == track.id;

              return TrackRow(
                track: track,
                isCurrent: isCurrent,
                isPlaying: isPlaying,
                accentColor: accentColor,
                onTap: () {
                  audio.setQueue(tracks, index: i);
                },
                onLongPress: () => TrackContextMenu.show(context, track),
              );
            }, childCount: tracks.length),
          );
        },
      ),
    ];
  }
}
