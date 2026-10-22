import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../domain/models/track.dart';

/// Album artwork tile with fallback procedural generative art.
class ArtTile extends StatelessWidget {
  const ArtTile({
    super.key,
    required this.track,
    this.radius = AppRadii.hero,
    this.shadow = true,
  });

  final Track track;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final deep = track.palette.isNotEmpty ? track.palette[0] : AppColors.bg;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: deep.withValues(alpha: 0.55),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _buildArtwork(context),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context) {
    if (track.artPath != null && track.artPath!.isNotEmpty) {
      return Image.file(
        File(track.artPath!),
        fit: BoxFit.cover,
        cacheWidth: 300,
        cacheHeight: 300,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          painter: ArtPainter(track),
          child: const SizedBox.expand(),
        ),
      );
    }
    return CustomPaint(
      painter: ArtPainter(track),
      child: const SizedBox.expand(),
    );
  }
}

class ArtPainter extends CustomPainter {
  const ArtPainter(this.t);
  final Track t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final deep = t.palette.isNotEmpty ? t.palette[0] : AppColors.bg;
    final mid = t.palette.length > 1 ? t.palette[1] : AppColors.surface;
    final light = t.palette.length > 2
        ? t.palette[2]
        : AppColors.accentFallback;

    canvas.drawRect(Offset.zero & size, Paint()..color = deep);

    switch (t.style % 4) {
      case 0: // concentric rings
        for (var i = 5; i >= 0; i--) {
          canvas.drawCircle(
            Offset(w * 0.36, h * 0.62),
            w * (0.12 + i * 0.13),
            Paint()..color = i.isEven ? mid : Color.lerp(mid, deep, 0.5)!,
          );
        }
        canvas.drawCircle(
          Offset(w * 0.36, h * 0.62),
          w * 0.1,
          Paint()..color = light,
        );
      case 1: // staggered bars
        final colors = [mid, light, Color.lerp(mid, deep, 0.5)!];
        for (var i = 0; i < 8; i++) {
          final bw = w * (0.35 + 0.65 * (((i * 37) % 10) / 10));
          canvas.drawRRect(
            RRect.fromLTRBR(
              w - bw,
              h * i / 8 + 3,
              w,
              h * (i + 1) / 8 - 3,
              const Radius.circular(AppRadii.small / 2),
            ),
            Paint()..color = colors[i % 3],
          );
        }
      case 2: // quarter-circle grid
        const n = 3;
        final cw = w / n;
        final ch = h / n;
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < n; c++) {
            final rect = Rect.fromLTWH(c * cw, r * ch, cw, ch);
            final flip = (r + c) % 2 == 0;
            final center = Offset(
              rect.left + (flip ? 0 : cw),
              rect.top + (flip ? 0 : ch),
            );
            canvas.save();
            canvas.clipRect(rect);
            canvas.drawCircle(
              center,
              cw * 0.95,
              Paint()..color = (r + c) % 3 == 0 ? light : mid,
            );
            canvas.drawCircle(center, cw * 0.45, Paint()..color = deep);
            canvas.restore();
          }
        }
      case 3: // sun over waves
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.42),
          w * 0.22,
          Paint()..color = light,
        );
        for (var i = 0; i < 5; i++) {
          final base = h * (0.58 + i * 0.09);
          final path = Path()
            ..moveTo(0, h)
            ..lineTo(0, base);
          for (double x = 0; x <= w; x += 4) {
            path.lineTo(
              x,
              base + math.sin(x / w * math.pi * 2 + i) * h * 0.018,
            );
          }
          path
            ..lineTo(w, h)
            ..close();
          canvas.drawPath(
            path,
            Paint()..color = Color.lerp(mid, deep, i / 4.0)!,
          );
        }
    }
  }

  @override
  bool shouldRepaint(ArtPainter old) => old.t != t;
}
