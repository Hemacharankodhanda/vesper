import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/detail_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/track_row.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  final List<String> _recentSearches = ['Low Tide', 'Paper', 'Quiet Hours'];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _query = value);
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_recentSearches.contains(trimmed)) {
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }
  }

  void _applyRecentSearch(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    setState(() => _query = term);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(libraryRepositoryProvider);
    final audio = ref.watch(audioServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: _query.trim().isEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(repo, audio, currentTrack, isPlaying, palette.light),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingMobile,
        AppSpacing.s16,
        AppSpacing.screenPaddingMobile,
        AppSpacing.s12,
      ),
      child: Container(
        height: 48.0,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.brCard,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 22.0,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                style: AppTypography.body,
                cursorColor: AppColors.textPrimary,
                decoration: const InputDecoration(
                  hintText: 'Search songs, albums, artists',
                  hintStyle: AppTypography.captionMuted,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onSearch,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                iconSize: 18.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const EmptyState(message: 'Search songs, artists, and albums');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingMobile,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: AppTypography.captionMuted.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _recentSearches.clear()),
                child: Text(
                  'Clear',
                  style: AppTypography.captionMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: _recentSearches.map((term) {
              return ActionChip(
                label: Text(term),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.brCard),
                labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                onPressed: () => _applyRecentSearch(term),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    LibraryRepository repo,
    dynamic audio,
    dynamic currentTrack,
    bool isPlaying,
    Color accentColor,
  ) {
    return FutureBuilder<GroupedSearchResult>(
      future: repo.searchGrouped(_query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (_, _) => const ShimmerSkeletonRow(),
          );
        }

        final result = snapshot.data ?? const GroupedSearchResult();

        if (result.isEmpty) {
          return EmptyState(
            message: 'No results found for "$_query"',
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 96.0),
          children: [
            // Songs
            if (result.tracks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s12,
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s8,
                ),
                child: Text(
                  'Songs',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
              ...result.tracks.map((t) {
                final isCurrent = currentTrack?.id == t.id;
                return TrackRow(
                  track: t,
                  isCurrent: isCurrent,
                  isPlaying: isPlaying,
                  accentColor: accentColor,
                  onTap: () {
                    audio.setQueue(result.tracks, index: result.tracks.indexOf(t));
                  },
                );
              }),
            ],
            // Albums
            if (result.albums.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s24,
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s12,
                ),
                child: Text(
                  'Albums',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
              SizedBox(
                height: 180.0,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingMobile),
                  itemCount: result.albums.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
                  itemBuilder: (context, i) {
                    final album = result.albums[i];
                    return AlbumCard(
                      album: album,
                      onTap: () => AlbumDetailSheet.show(context, album),
                    );
                  },
                ),
              ),
            ],
            // Artists
            if (result.artists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s24,
                  AppSpacing.screenPaddingMobile,
                  AppSpacing.s8,
                ),
                child: Text(
                  'Artists',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
              ),
              ...result.artists.map((artist) {
                return ListTile(
                  onTap: () => ArtistDetailSheet.show(context, artist),
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
                  ),
                  title: Text(artist.name, style: AppTypography.body),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
