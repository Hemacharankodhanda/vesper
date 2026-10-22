import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../core/platform/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';

/// Connected seek bar that listens exclusively to [positionProvider] so parent screens do not rebuild.
class ConnectedSeekBar extends ConsumerWidget {
  const ConnectedSeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration =
        ref.watch(durationProvider).value ?? const Duration(seconds: 1);

    return SeekBar(
      position: position,
      length: duration == Duration.zero ? const Duration(seconds: 1) : duration,
      onSeek: (fraction) {
        final targetMs = (duration.inMilliseconds * fraction).round();
        ref.read(audioServiceProvider).seek(Duration(milliseconds: targetMs));
      },
    );
  }
}

/// Thin 4 px line that thickens to 10 px while dragging. Tap anywhere to jump.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.length,
    required this.onSeek,
  });

  final Duration position;
  final Duration length;
  final ValueChanged<double> onSeek;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  double _fraction(double dx, double width) {
    if (width <= 0) return 0.0;
    return (dx / width).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.length.inMilliseconds;
    final live = totalMs > 0 ? widget.position.inMilliseconds / totalMs : 0.0;
    final v = (_drag ?? live).clamp(0.0, 1.0);
    final shown = Duration(milliseconds: (totalMs * v).round());
    final remaining = widget.length - shown;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            key: const Key('seek_bar_gesture_detector'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              AppHaptics.selection();
              widget.onSeek(
                _fraction(details.localPosition.dx, constraints.maxWidth),
              );
            },
            onHorizontalDragStart: (details) => setState(
              () => _drag = _fraction(
                details.localPosition.dx,
                constraints.maxWidth,
              ),
            ),
            onHorizontalDragUpdate: (details) => setState(
              () => _drag = _fraction(
                details.localPosition.dx,
                constraints.maxWidth,
              ),
            ),
            onHorizontalDragEnd: (_) {
              AppHaptics.selection();
              final end = _drag;
              setState(() => _drag = null);
              if (end != null) widget.onSeek(end);
            },
            onHorizontalDragCancel: () => setState(() => _drag = null),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _drag == null ? 4.0 : 10.0),
              duration: const Duration(milliseconds: 180),
              curve: AppMotion.defaultCurve,
              builder: (context, height, _) => SizedBox(
                height: 32.0,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SeekPainter(v: v, height: height),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.formatDuration(shown),
              style: AppTypography.caption,
            ),
            Text(
              '-${Formatters.formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}

class _SeekPainter extends CustomPainter {
  const _SeekPainter({required this.v, required this.height});

  final double v;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final radius = Radius.circular(height / 2);

    // Track background
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - height / 2, size.width, y + height / 2, radius),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );

    // Elapsed progress
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        y - height / 2,
        size.width * v,
        y + height / 2,
        radius,
      ),
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_SeekPainter old) => old.v != v || old.height != height;
}
