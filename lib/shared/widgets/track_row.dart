import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/track.dart';
import 'art_tile.dart';

/// 56 px height track row adhering to Vesper tokens.
/// Highlights currently playing track in accent color.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    this.isCurrent = false,
    this.isPlaying = false,
    this.accentColor,
    this.onTap,
    this.onLongPress,
  });

  final Track track;
  final bool isCurrent;
  final bool isPlaying;
  final Color? accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.accentFallback;

    return InkWell(
      borderRadius: AppRadii.brCard,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56.0,
              height: 56.0,
              child: ArtTile(
                track: track,
                radius: AppRadii.card,
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
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: isCurrent ? activeColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
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
            if (isCurrent && isPlaying)
              Icon(
                Icons.equalizer_rounded,
                color: activeColor,
                size: 20.0,
              )
            else
              Text(
                Formatters.formatDuration(track.duration),
                style: AppTypography.captionMuted,
              ),
          ],
        ),
      ),
    );
  }
}
