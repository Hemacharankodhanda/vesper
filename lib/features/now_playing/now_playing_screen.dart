import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/queue_state.dart';
import '../../domain/models/track.dart';
import '../../shared/widgets/art_tile.dart';
import '../../shared/widgets/icon_btn.dart';
import '../../shared/widgets/play_button.dart';
import '../../shared/widgets/seek_bar.dart';
import '../queue/queue_sheet.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  final _pageController = PageController(viewportFraction: 0.8);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPager(int targetIndex) {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return;
    }
    final current = _pageController.page?.round() ?? 0;
    if (current == targetIndex) {
      return;
    }

    if ((current - targetIndex).abs() == 1) {
      _pageController.animateToPage(
        targetIndex,
        duration: AppMotion.slow,
        curve: AppMotion.defaultCurve,
      );
    } else {
      _pageController.jumpToPage(targetIndex);
    }
  }

  void _openQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueStateProvider).value ?? QueueState.empty;
    final palette = ref.watch(currentPaletteProvider);
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final likedTracks = ref.watch(likedTracksProvider);
    final audioService = ref.read(audioServiceProvider);

    final track =
        queue.currentTrack ??
        (queue.tracks.isNotEmpty ? queue.tracks[0] : null);

    // Sync pager when queue index changes externally
    ref.listen<AsyncValue<QueueState>>(queueStateProvider, (prev, next) {
      final nextIndex = next.value?.currentIndex;
      if (nextIndex != null) {
        _syncPager(nextIndex);
      }
    });

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text('No track loaded', style: AppTypography.bodySecondary),
        ),
      );
    }

    final isLiked = likedTracks.contains(track.id);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): audioService.toggle,
        const SingleActivator(LogicalKeyboardKey.arrowRight): audioService.next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            audioService.previous,
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            ref.read(likedTracksProvider.notifier).toggle(track.id),
        const SingleActivator(LogicalKeyboardKey.keyQ): () =>
            _openQueue(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AnimatedContainer(
            duration: AppMotion.paletteCrossfade,
            curve: Curves.easeOut,
            decoration: BoxDecoration(gradient: palette.backgroundGradient),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth >= AppBreakpoints.compact
                      ? _buildWide(
                          context,
                          track,
                          palette,
                          queue,
                          isPlaying,
                          isLiked,
                        )
                      : _buildNarrow(
                          context,
                          track,
                          palette,
                          queue,
                          isPlaying,
                          isLiked,
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow(
    BuildContext context,
    Track track,
    VesperPalette palette,
    QueueState queue,
    bool isPlaying,
    bool isLiked,
  ) {
    return Column(
      children: [
        _buildTopBar(track, horizontalPadding: AppSpacing.screenPaddingMobile),
        Expanded(child: _buildPager(queue, isPlaying)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfo(track, palette, isLiked),
              const SizedBox(height: AppSpacing.s16),
              const ConnectedSeekBar(),
              const SizedBox(height: AppSpacing.s12),
              _buildControls(palette, queue, isPlaying),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWide(
    BuildContext context,
    Track track,
    VesperPalette palette,
    QueueState queue,
    bool isPlaying,
    bool isLiked,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingDesktop),
            child: _buildPager(queue, isPlaying),
          ),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.screenPaddingDesktop,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopBar(track, horizontalPadding: 0),
                    const SizedBox(height: AppSpacing.s24),
                    _buildInfo(track, palette, isLiked),
                    const SizedBox(height: AppSpacing.s24),
                    const ConnectedSeekBar(),
                    const SizedBox(height: AppSpacing.s16),
                    _buildControls(palette, queue, isPlaying),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Track track, {required double horizontalPadding}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.s8,
        horizontalPadding == 0 ? 0 : AppSpacing.s12,
        0,
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            IconBtn(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: 'Collapse',
              onTap: () => Navigator.of(context).pop(),
              active: true,
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          Expanded(
            child: Text(
              track.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          IconBtn(
            icon: Icons.queue_music_rounded,
            tooltip: 'Queue',
            onTap: () => _openQueue(context),
            active: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPager(QueueState queue, bool isPlaying) {
    final tracks = queue.tracks;
    final audioService = ref.read(audioServiceProvider);

    return PageView.builder(
      controller: _pageController,
      itemCount: tracks.length,
      onPageChanged: (i) {
        if (i != queue.currentIndex) {
          audioService.jumpTo(i);
        }
      },
      itemBuilder: (context, i) => AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          final page =
              _pageController.hasClients &&
                  _pageController.position.haveDimensions
              ? (_pageController.page ?? i.toDouble())
              : queue.currentIndex.toDouble();
          final distance = (page - i).abs().clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1.0 - (0.14 * distance),
            child: Opacity(
              opacity: (1.0 - (0.55 * distance)).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AnimatedScale(
                scale: isPlaying ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 400),
                curve: AppMotion.popCurve,
                child: i == queue.currentIndex
                    ? Hero(
                        tag: 'now_playing_art',
                        child: ArtTile(
                          track: tracks[i],
                          radius: AppRadii.hero,
                          shadow: true,
                        ),
                      )
                    : ArtTile(
                        track: tracks[i],
                        radius: AppRadii.hero,
                        shadow: true,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(Track track, VesperPalette palette, bool isLiked) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  track.title,
                  key: ValueKey(track.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(fontSize: 30),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySecondary.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isLiked ? 'Remove from liked' : 'Like',
          onPressed: () {
            ref.read(likedTracksProvider.notifier).toggle(track.id);
            ref.read(libraryRepositoryProvider).toggleLike(track.id);
          },
          icon: AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isLiked),
              size: 28.0,
              color: isLiked ? palette.light : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    VesperPalette palette,
    QueueState queue,
    bool isPlaying,
  ) {
    final audioService = ref.read(audioServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconBtn(
          icon: Icons.shuffle_rounded,
          tooltip: 'Shuffle',
          active: queue.shuffle,
          onTap: () => audioService.setShuffle(!queue.shuffle),
        ),
        IconBtn(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous',
          size: 40.0,
          onTap: audioService.previous,
        ),
        PlayButton(
          playing: isPlaying,
          color: palette.deep,
          onTap: audioService.toggle,
        ),
        IconBtn(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next',
          size: 40.0,
          onTap: audioService.next,
        ),
        IconBtn(
          icon: queue.repeat == AudioRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          tooltip: 'Repeat',
          active: queue.repeat != AudioRepeatMode.off,
          onTap: () {
            final nextMode = switch (queue.repeat) {
              AudioRepeatMode.off => AudioRepeatMode.all,
              AudioRepeatMode.all => AudioRepeatMode.one,
              AudioRepeatMode.one => AudioRepeatMode.off,
            };
            audioService.setRepeat(nextMode);
          },
        ),
      ],
    );
  }
}
