// Vesper: Now Playing screen prototype (fake data, no packages needed).
// Works on Android and Windows. Replace lib/main.dart in a fresh `flutter create` project.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const VesperApp());

class VesperApp extends StatelessWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Vesper',
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    home: const NowPlayingScreen(),
  );
}

// ───────────────────────── Fake data ─────────────────────────

class Track {
  const Track(
    this.title,
    this.artist,
    this.album,
    this.seconds,
    this.style,
    this.palette,
  );
  final String title, artist, album;
  final int seconds, style;
  final List<Color> palette; // [deep, mid, light]
  Duration get length => Duration(seconds: seconds);
}

const tracks = <Track>[
  Track('Low Tide Hours', 'Marlowe Reyes', 'Salt & Static', 214, 0, [
    Color(0xFF0B2A3A),
    Color(0xFF1F6F8B),
    Color(0xFFF2C14E),
  ]),
  Track('Paper Lanterns', 'Ione Vask', 'Small Weather', 187, 1, [
    Color(0xFF3A1230),
    Color(0xFFB8336A),
    Color(0xFFFFC8A2),
  ]),
  Track('Concrete Garden', 'The Quiet Hours', 'Field Notes', 241, 2, [
    Color(0xFF14301F),
    Color(0xFF3E8E5A),
    Color(0xFFE9E4B0),
  ]),
  Track('Slow Horizon', 'Aarav Menon', 'Dusk Frequencies', 203, 3, [
    Color(0xFF241B4B),
    Color(0xFF6C4CD1),
    Color(0xFFFF9A6B),
  ]),
  Track('Glasshouse', 'Nell & Orrin', 'Pale Fire', 176, 0, [
    Color(0xFF2B2B2B),
    Color(0xFF8A8D91),
    Color(0xFFE8E2D4),
  ]),
];

String _fmt(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

// ───────────────────────── Fake player ─────────────────────────
// Later this gets replaced by the real audio service (just_audio / media_kit).
// The UI only reads state and calls these methods, so the swap is easy.

class FakePlayer extends ChangeNotifier {
  int index = 0;
  bool playing = false;
  bool shuffle = false;
  int repeat = 0; // 0 off, 1 all, 2 one
  final Set<int> liked = {};
  Duration position = Duration.zero;
  Timer? _timer;
  final _rng = math.Random();

  Track get track => tracks[index];

  void toggle() {
    playing = !playing;
    _timer?.cancel();
    if (playing) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _tick(),
      );
    }
    notifyListeners();
  }

  void _tick() {
    position += const Duration(milliseconds: 250);
    if (position >= track.length) {
      next(auto: true);
    } else {
      notifyListeners();
    }
  }

  void seek(double fraction) {
    position = Duration(
      milliseconds: (track.length.inMilliseconds * fraction.clamp(0.0, 1.0))
          .round(),
    );
    notifyListeners();
  }

  void next({bool auto = false}) {
    if (auto && repeat == 2) {
      position = Duration.zero;
      notifyListeners();
      return;
    }
    if (auto && repeat == 0 && !shuffle && index == tracks.length - 1) {
      position = Duration.zero;
      playing = false;
      _timer?.cancel();
      notifyListeners();
      return;
    }
    if (shuffle && tracks.length > 1) {
      int n;
      do {
        n = _rng.nextInt(tracks.length);
      } while (n == index);
      index = n;
    } else {
      index = (index + 1) % tracks.length;
    }
    position = Duration.zero;
    notifyListeners();
  }

  void previous() {
    if (position.inSeconds < 3) {
      index = (index - 1 + tracks.length) % tracks.length;
    }
    position = Duration.zero;
    notifyListeners();
  }

  void jump(int i) {
    index = i;
    position = Duration.zero;
    notifyListeners();
  }

  void toggleLike() {
    liked.contains(index) ? liked.remove(index) : liked.add(index);
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = (repeat + 1) % 3;
    notifyListeners();
  }
}

final player = FakePlayer();

// ───────────────────────── Now Playing screen ─────────────────────────

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final _pc = PageController(viewportFraction: 0.8);

  @override
  void initState() {
    super.initState();
    player.addListener(_syncPager);
  }

  @override
  void dispose() {
    player.removeListener(_syncPager);
    _pc.dispose();
    super.dispose();
  }

  // Keeps the swipeable art in sync when the track changes via buttons/queue.
  void _syncPager() {
    if (!_pc.hasClients || !_pc.position.haveDimensions) return;
    final cur = _pc.page?.round() ?? 0;
    if (cur == player.index) return;
    if ((cur - player.index).abs() == 1) {
      _pc.animateToPage(
        player.index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pc.jumpToPage(player.index);
    }
  }

  void _openQueue() {
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
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): player.toggle,
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            player.next(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): player.previous,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) {
            final t = player.track;
            return Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(t.palette[1], t.palette[0], .35)!,
                      t.palette[0],
                    ],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) =>
                        c.maxWidth >= 800 ? _wide(t) : _narrow(t),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Phone: art on top, controls below.
  Widget _narrow(Track t) => Column(
    children: [
      _topBar(t),
      Expanded(child: _pager()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            _info(t),
            const SizedBox(height: 20),
            _seek(t),
            const SizedBox(height: 12),
            _controls(t),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ],
  );

  // Windows / tablet: art left, controls right.
  Widget _wide(Track t) => Row(
    children: [
      Expanded(
        flex: 6,
        child: Padding(padding: const EdgeInsets.all(32), child: _pager()),
      ),
      Expanded(
        flex: 5,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 32, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topBar(t, pad: 0),
                  const SizedBox(height: 24),
                  _info(t),
                  const SizedBox(height: 28),
                  _seek(t),
                  const SizedBox(height: 16),
                  _controls(t),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _topBar(Track t, {double pad = 28}) => Padding(
    padding: EdgeInsets.fromLTRB(pad, 8, pad == 0 ? 0 : 12, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            t.album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              letterSpacing: .2,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Queue',
          onPressed: _openQueue,
          icon: const Icon(Icons.queue_music_rounded, color: Colors.white70),
        ),
      ],
    ),
  );

  // Swipeable album art with neighbours peeking in.
  Widget _pager() => PageView.builder(
    controller: _pc,
    itemCount: tracks.length,
    onPageChanged: (i) {
      if (i != player.index) player.jump(i);
    },
    itemBuilder: (context, i) => AnimatedBuilder(
      animation: _pc,
      builder: (context, child) {
        final p = _pc.hasClients && _pc.position.haveDimensions
            ? (_pc.page ?? i.toDouble())
            : player.index.toDouble();
        final d = (p - i).abs().clamp(0.0, 1.0).toDouble();
        return Transform.scale(
          scale: 1 - 0.14 * d,
          child: Opacity(opacity: 1 - 0.55 * d, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedScale(
              scale: player.playing ? 1 : 0.92,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              child: ArtTile(track: tracks[i], radius: 28),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _info(Track t) {
    final liked = player.liked.contains(player.index);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (cur, prev) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...prev, if (cur != null) cur],
                ),
                child: Text(
                  t.title,
                  key: ValueKey(t.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: liked ? 'Remove from liked' : 'Like',
          onPressed: player.toggleLike,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(liked),
              size: 28,
              color: liked ? t.palette[2] : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _seek(Track t) =>
      SeekBar(position: player.position, length: t.length, onSeek: player.seek);

  Widget _controls(Track t) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _IconBtn(
        Icons.shuffle_rounded,
        tooltip: 'Shuffle',
        active: player.shuffle,
        onTap: player.toggleShuffle,
      ),
      _IconBtn(
        Icons.skip_previous_rounded,
        tooltip: 'Previous',
        size: 40,
        onTap: player.previous,
      ),
      _PlayButton(
        playing: player.playing,
        color: t.palette[0],
        onTap: player.toggle,
      ),
      _IconBtn(
        Icons.skip_next_rounded,
        tooltip: 'Next',
        size: 40,
        onTap: () => player.next(),
      ),
      _IconBtn(
        player.repeat == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
        tooltip: 'Repeat',
        active: player.repeat != 0,
        onTap: player.cycleRepeat,
      ),
    ],
  );
}

// ───────────────────────── Small widgets ─────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn(
    this.icon, {
    required this.onTap,
    required this.tooltip,
    this.size = 26,
    this.active = true,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    iconSize: size,
    icon: Icon(icon, color: active ? Colors.white : Colors.white38),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.color,
    required this.onTap,
  });
  final bool playing;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: playing ? 'Pause' : 'Play',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            size: 42,
            color: color,
          ),
        ),
      ),
    ),
  );
}

/// Thin line that thickens while you drag. Tap anywhere to jump.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.length,
    required this.onSeek,
  });
  final Duration position, length;
  final ValueChanged<double> onSeek;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  double _frac(double dx, double w) => (dx / w).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final live = widget.position.inMilliseconds / widget.length.inMilliseconds;
    final v = _drag ?? live.clamp(0.0, 1.0).toDouble();
    final shown = Duration(
      milliseconds: (widget.length.inMilliseconds * v).round(),
    );
    const timeStyle = TextStyle(
      fontSize: 12,
      color: Colors.white60,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) =>
                widget.onSeek(_frac(d.localPosition.dx, c.maxWidth)),
            onHorizontalDragStart: (d) =>
                setState(() => _drag = _frac(d.localPosition.dx, c.maxWidth)),
            onHorizontalDragUpdate: (d) =>
                setState(() => _drag = _frac(d.localPosition.dx, c.maxWidth)),
            onHorizontalDragEnd: (_) {
              final end = _drag;
              setState(() => _drag = null);
              if (end != null) widget.onSeek(end);
            },
            onHorizontalDragCancel: () => setState(() => _drag = null),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _drag == null ? 4.0 : 10.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, h, _) => SizedBox(
                height: 32,
                width: double.infinity,
                child: CustomPaint(painter: _SeekPainter(v, h)),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(shown), style: timeStyle),
            Text('-${_fmt(widget.length - shown)}', style: timeStyle),
          ],
        ),
      ],
    );
  }
}

class _SeekPainter extends CustomPainter {
  _SeekPainter(this.v, this.h);
  final double v, h;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final r = Radius.circular(h / 2);
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - h / 2, size.width, y + h / 2, r),
      Paint()..color = Colors.white24,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - h / 2, size.width * v, y + h / 2, r),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SeekPainter old) => old.v != v || old.h != h;
}

// ───────────────────────── Generated album art ─────────────────────────
// Placeholder art drawn in code so the prototype needs no image assets.
// In the real app this becomes the embedded cover from the audio file.

class ArtTile extends StatelessWidget {
  const ArtTile({
    super.key,
    required this.track,
    this.radius = 20,
    this.shadow = true,
  });
  final Track track;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: track.palette[0].withValues(alpha: .55),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ]
          : null,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: ArtPainter(track),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class ArtPainter extends CustomPainter {
  ArtPainter(this.t);
  final Track t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final deep = t.palette[0], mid = t.palette[1], light = t.palette[2];
    canvas.drawRect(Offset.zero & size, Paint()..color = deep);

    switch (t.style) {
      case 0: // concentric rings
        for (var i = 5; i >= 0; i--) {
          canvas.drawCircle(
            Offset(w * .36, h * .62),
            w * (.12 + i * .13),
            Paint()..color = i.isEven ? mid : Color.lerp(mid, deep, .5)!,
          );
        }
        canvas.drawCircle(
          Offset(w * .36, h * .62),
          w * .1,
          Paint()..color = light,
        );
      case 1: // staggered bars
        final colors = [mid, light, Color.lerp(mid, deep, .5)!];
        for (var i = 0; i < 8; i++) {
          final bw = w * (.35 + .65 * (((i * 37) % 10) / 10));
          canvas.drawRRect(
            RRect.fromLTRBR(
              w - bw,
              h * i / 8 + 3,
              w,
              h * (i + 1) / 8 - 3,
              const Radius.circular(4),
            ),
            Paint()..color = colors[i % 3],
          );
        }
      case 2: // quarter-circle grid
        const n = 3;
        final cw = w / n, ch = h / n;
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
              cw * .95,
              Paint()..color = (r + c) % 3 == 0 ? light : mid,
            );
            canvas.drawCircle(center, cw * .45, Paint()..color = deep);
            canvas.restore();
          }
        }
      case 3: // sun over waves
        canvas.drawCircle(
          Offset(w * .5, h * .42),
          w * .22,
          Paint()..color = light,
        );
        for (var i = 0; i < 5; i++) {
          final base = h * (.58 + i * .09);
          final path = Path()
            ..moveTo(0, h)
            ..lineTo(0, base);
          for (double x = 0; x <= w; x += 4) {
            path.lineTo(x, base + math.sin(x / w * math.pi * 2 + i) * h * .018);
          }
          path
            ..lineTo(w, h)
            ..close();
          canvas.drawPath(path, Paint()..color = Color.lerp(mid, deep, i / 4)!);
        }
    }
  }

  @override
  bool shouldRepaint(ArtPainter old) => old.t != t;
}

// ───────────────────────── Queue sheet ─────────────────────────

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .62,
    minChildSize: .4,
    maxChildSize: .92,
    expand: false,
    builder: (context, scroll) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) {
            final t = player.track;
            return ColoredBox(
              color: t.palette[0].withValues(alpha: .8),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: tracks.length,
                      itemBuilder: (context, i) {
                        final tr = tracks[i];
                        final current = i == player.index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => player.jump(i),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: ArtTile(
                                    track: tr,
                                    radius: 12,
                                    shadow: false,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: current
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: current
                                              ? t.palette[2]
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tr.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmt(tr.length),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
