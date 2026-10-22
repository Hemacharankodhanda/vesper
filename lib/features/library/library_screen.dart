import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/platform/folder_picker.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../domain/models/album.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/track.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/detail_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/playlist_detail_sheet.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/track_row.dart';
import '../settings/settings_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0; // 0: Songs, 1: Albums, 2: Artists, 3: Playlists
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter, List<Track> tracks) {
    final index = tracks.indexWhere(
      (t) => t.title.toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      final offset = (index * 72.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: AppMotion.fast,
        curve: AppMotion.defaultCurve,
      );
    }
  }

  Future<void> _pickAndScanFolder() async {
    final path = await FolderPickerService.pickFolder();
    if (path != null && mounted) {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.addFolder(path);
      // Scan folder
      repo.scanAllFolders().listen((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(libraryTracksProvider);
    final albumsAsync = ref.watch(libraryAlbumsProvider);
    final artistsAsync = ref.watch(libraryArtistsProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSegmentedControl(),
            const SizedBox(height: AppSpacing.s12),
            Expanded(
              child: switch (_selectedTab) {
                0 => _buildSongsView(
                  tracksAsync,
                  currentTrack,
                  isPlaying,
                  palette.light,
                ),
                1 => _buildAlbumsView(albumsAsync),
                2 => _buildArtistsView(artistsAsync),
                _ => _buildPlaylistsView(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingMobile,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          Text('Library', style: AppTypography.display.copyWith(fontSize: 28)),
          const Spacer(),
          IconButton(
            tooltip: 'Add Music Folder',
            onPressed: _pickAndScanFolder,
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final tabs = ['Songs', 'Albums', 'Artists', 'Playlists'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingMobile,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: ChoiceChip(
              label: Text(tabs[i]),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedTab = i),
              selectedColor: AppColors.surfaceHigh,
              backgroundColor: AppColors.surface,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.brCard),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSongsView(
    AsyncValue<List<Track>> tracksAsync,
    Track? currentTrack,
    bool isPlaying,
    Color accentColor,
  ) {
    return tracksAsync.when(
      loading: () => ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => const ShimmerSkeletonRow(),
      ),
      error: (_, _) =>
          const EmptyState(message: 'Could not load library songs'),
      data: (dbTracks) {
        // Fall back to fakeTracks if local library has no folders scanned yet
        final tracks = dbTracks.isNotEmpty ? dbTracks : fakeTracks;

        if (tracks.isEmpty) {
          return EmptyState(
            message: 'No songs found in your library folders',
            actionLabel: 'Add Music Folder',
            onAction: _pickAndScanFolder,
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 96.0, right: 28.0),
              itemCount: tracks.length,
              itemExtent: 72.0,
              itemBuilder: (context, i) {
                final track = tracks[i];
                final isCurrent = currentTrack?.id == track.id;

                return TrackRow(
                  track: track,
                  isCurrent: isCurrent,
                  isPlaying: isPlaying,
                  accentColor: accentColor,
                  onTap: () {
                    ref.read(audioServiceProvider).setQueue(tracks, index: i);
                  },
                  onLongPress: () => TrackContextMenu.show(context, track),
                );
              },
            ),
            // Alphabet Scrubber
            Positioned(
              right: 4.0,
              top: 0,
              bottom: 96.0,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((
                      letter,
                    ) {
                      return GestureDetector(
                        onTap: () => _scrollToLetter(letter, tracks),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            letter,
                            style: AppTypography.captionMuted.copyWith(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsView(AsyncValue<List<Album>> albumsAsync) {
    return albumsAsync.when(
      loading: () => const Center(child: ShimmerSkeletonRow()),
      error: (_, _) => const EmptyState(message: 'Could not load albums'),
      data: (dbAlbums) {
        final albums = dbAlbums.isNotEmpty
            ? dbAlbums
            : fakeTracks
                  .map(
                    (t) => Album(
                      id: t.album,
                      title: t.album,
                      albumArtist: t.artist,
                    ),
                  )
                  .toSet()
                  .toList();

        if (albums.isEmpty) {
          return EmptyState(
            message: 'No albums found',
            actionLabel: 'Add Folder',
            onAction: _pickAndScanFolder,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 160.0).floor().clamp(
              2,
              6,
            );
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingMobile,
                AppSpacing.s8,
                AppSpacing.screenPaddingMobile,
                96.0,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.s16,
                mainAxisSpacing: AppSpacing.s16,
                childAspectRatio: 0.75,
              ),
              itemCount: albums.length,
              itemBuilder: (context, i) {
                final album = albums[i];
                return AlbumCard(
                  album: album,
                  onTap: () => AlbumDetailSheet.show(context, album),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsView(AsyncValue<List<Artist>> artistsAsync) {
    return artistsAsync.when(
      loading: () => const Center(child: ShimmerSkeletonRow()),
      error: (_, _) => const EmptyState(message: 'Could not load artists'),
      data: (dbArtists) {
        final artists = dbArtists.isNotEmpty
            ? dbArtists
            : fakeTracks
                  .map((t) => Artist(id: t.artist, name: t.artist))
                  .toSet()
                  .toList();

        if (artists.isEmpty) {
          return EmptyState(
            message: 'No artists found',
            actionLabel: 'Add Folder',
            onAction: _pickAndScanFolder,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final artist = artists[i];
            return ListTile(
              onTap: () => ArtistDetailSheet.show(context, artist),
              leading: Container(
                width: 44.0,
                height: 44.0,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              title: Text(artist.name, style: AppTypography.body),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
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
                await playlistRepo.createPlaylist(name);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(
              'Create',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsView() {
    final playlistsAsync = ref.watch(playlistsProvider);

    return playlistsAsync.when(
      loading: () => const Center(child: ShimmerSkeletonRow()),
      error: (_, _) => const EmptyState(message: 'Could not load playlists'),
      data: (playlists) {
        if (playlists.isEmpty) {
          return EmptyState(
            message: 'No playlists created yet',
            actionLabel: 'Create Playlist',
            onAction: _showCreatePlaylistDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96.0),
          itemCount: playlists.length,
          itemBuilder: (context, i) {
            final playlist = playlists[i];
            return ListTile(
              leading: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadii.brSmall,
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.accentFallback,
                ),
              ),
              title: Text(playlist.name, style: AppTypography.body),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () => PlaylistDetailSheet.show(context, playlist),
            );
          },
        );
      },
    );
  }
}
