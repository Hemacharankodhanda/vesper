import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/platform/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../features/now_playing/now_playing_screen.dart';
import 'art_tile.dart';
import 'glass_panel.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.isDesktop = false});

  final bool isDesktop;

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: AppMotion.defaultCurve,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: child,
          );
        },
        transitionDuration: AppMotion.slow,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final palette = ref.watch(currentPaletteProvider);
    final audio = ref.watch(audioServiceProvider);

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openNowPlaying(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -150) {
          _openNowPlaying(context);
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 250) {
            audio.previous();
          } else if (details.primaryVelocity! < -250) {
            audio.next();
          }
        }
      },
      child: Container(
        height: 64.0,
        margin: isDesktop
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4,
              ),
        child: ClipRRect(
          borderRadius: isDesktop ? BorderRadius.zero : AppRadii.brCard,
          child: GlassPanel(
            backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.90),
            borderRadius: isDesktop ? BorderRadius.zero : AppRadii.brCard,
            child: Stack(
              children: [
                // 2 px seek progress bar isolated to position stream
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _MiniProgressBar(
                    duration: currentTrack.duration,
                    accentColor: palette.light,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'now_playing_art',
                        child: SizedBox(
                          width: 46.0,
                          height: 46.0,
                          child: ArtTile(
                            track: currentTrack,
                            radius: AppRadii.small,
                            shadow: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              currentTrack.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      // Skip Prev on desktop
                      if (isDesktop)
                        IconButton(
                          iconSize: 22.0,
                          tooltip: 'Previous',
                          onPressed: () {
                            AppHaptics.light();
                            audio.previous();
                          },
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      // Play / Pause button
                      Semantics(
                        button: true,
                        label: isPlaying ? 'Pause' : 'Play',
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            audio.toggle();
                          },
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.bg,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      // Skip Next button
                      IconButton(
                        iconSize: 22.0,
                        tooltip: 'Next',
                        onPressed: () {
                          AppHaptics.light();
                          audio.next();
                        },
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar({required this.duration, required this.accentColor});

  final Duration duration;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final totalMs = duration.inMilliseconds;
    final progress = totalMs > 0
        ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    return LinearProgressIndicator(
      value: progress,
      minHeight: 2.0,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
    );
  }
}
