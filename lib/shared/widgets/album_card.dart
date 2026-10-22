import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../domain/models/album.dart';
import '../../domain/models/track.dart';
import 'art_tile.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.size = 140.0,
    this.onTap,
  });

  final Album album;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Generate a fallback preview track for procedural art
    final previewTrack = Track(
      id: album.id,
      title: album.title,
      artist: album.albumArtist ?? 'Unknown Artist',
      album: album.title,
      duration: Duration.zero,
      style: album.title.hashCode.abs() % 4,
      artHash: album.artHash,
      artPath: album.artPath,
    );

    return InkWell(
      borderRadius: AppRadii.brCard,
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ArtTile(
                track: previewTrack,
                radius: AppRadii.card,
                shadow: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2.0),
            Text(
              album.albumArtist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
