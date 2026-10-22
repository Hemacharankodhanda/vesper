import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../audio/audio_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/lrc_parser.dart';
import '../../domain/models/track.dart';
import 'glass_panel.dart';

class LyricsSheet extends ConsumerStatefulWidget {
  const LyricsSheet({super.key, required this.track});

  final Track track;

  static void show(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => LyricsSheet(track: track),
    );
  }

  @override
  ConsumerState<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<LyricsSheet> {
  final ScrollController _scrollController = ScrollController();
  List<LrcLine> _lines = [];
  int _activeLineIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    // 1. Try reading .lrc file next to track path
    if (widget.track.path != null) {
      final lrcPath = p.setExtension(widget.track.path!, '.lrc');
      final file = File(lrcPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() => _lines = LrcParser.parse(content));
        return;
      }
    }

    // 2. Demo fallback lyrics for prototype / development
    const demoLrc = '''
[00:00.00] (Instrumental intro)
[00:08.50] Watch the tide recede slowly
[00:16.00] Under paper skies and static dreams
[00:24.20] Everything we left behind remains
[00:32.80] Caught between the light and shadows
[00:41.00] Slow horizon calling softly
[00:49.50] Echoes in the quiet garden
[00:58.00] Concrete flowers bloom at dusk
[01:06.50] Frequencies align in silence
[01:15.00] (Instrumental bridge)
[01:30.00] Into the glasshouse we wander
[01:45.00] Waiting for the dawn to break
''';
    setState(() => _lines = LrcParser.parse(demoLrc));
  }

  void _syncPosition(Duration position) {
    if (_lines.isEmpty) return;

    var newIndex = -1;
    for (var i = 0; i < _lines.length; i++) {
      if (position >= _lines[i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeLineIndex && newIndex != -1) {
      _activeLineIndex = newIndex;
      if (_scrollController.hasClients) {
        final targetOffset = (_activeLineIndex * 48.0) - 120.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: AppMotion.base,
          curve: AppMotion.defaultCurve,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final audio = ref.watch(audioServiceProvider);

    ref.listen<AsyncValue<Duration>>(positionProvider, (_, next) {
      final pos = next.value;
      if (pos != null) {
        _syncPosition(pos);
      }
    });

    final currentPosition = ref.watch(positionProvider).value ?? Duration.zero;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, _) => GlassPanel(
        backgroundColor: palette.deep.withValues(alpha: 0.90),
        borderRadius: AppRadii.brSheet,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s12),
            // Drag handle
            Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                borderRadius: AppRadii.brFull,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Text(
                    'Lyrics',
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(widget.track.title, style: AppTypography.captionMuted),
                ],
              ),
            ),
            const Divider(height: 1.0, color: Color(0x1AFFFFFF)),
            Expanded(
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        'No lyrics found for this track',
                        style: AppTypography.captionMuted,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s24,
                        vertical: AppSpacing.s24,
                      ),
                      itemCount: _lines.length,
                      itemBuilder: (context, i) {
                        final line = _lines[i];
                        final isNext = i < _lines.length - 1;
                        final nextTimestamp = isNext
                            ? _lines[i + 1].timestamp
                            : const Duration(hours: 1);
                        final isActive =
                            currentPosition >= line.timestamp &&
                            currentPosition < nextTimestamp;

                        return InkWell(
                          borderRadius: AppRadii.brSmall,
                          onTap: () => audio.seek(line.timestamp),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s12,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              style: AppTypography.title.copyWith(
                                fontSize: isActive ? 22.0 : 17.0,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? palette.light
                                    : AppColors.textMuted,
                              ),
                              child: Text(line.text),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
