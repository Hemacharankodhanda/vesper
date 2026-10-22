import 'dart:async';
import 'dart:io' show File;
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';
import 'audio_player_service.dart';
import 'vesper_audio_handler.dart';

class JustAudioService implements AudioPlayerService {
  JustAudioService({
    AudioPlayer? player,
    this.handler,
    List<Track>? initialTracks,
    int initialIndex = 0,
  }) : _player = player ?? AudioPlayer() {
    final list = initialTracks ?? fakeTracks;
    _queueState = QueueState(
      tracks: list,
      currentIndex: list.isEmpty ? 0 : initialIndex.clamp(0, list.length - 1),
    );
    _init();
  }

  final AudioPlayer _player;
  final VesperAudioHandler? handler;
  late QueueState _queueState;
  Timer? _sleepTimer;
  final List<StreamSubscription> _subscriptions = [];

  final _playingCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration?>.broadcast();
  final _currentTrackCtrl = StreamController<Track?>.broadcast();
  final _queueCtrl = StreamController<QueueState>.broadcast();

  DateTime _lastPositionEmission = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _init() async {
    _wireHandler();
    await _configureAudioSession();

    // Listen to player playing state
    _subscriptions.add(
      _player.playingStream.listen((playing) {
        _playingCtrl.add(playing);
        _syncSystemMedia();
      }),
    );

    // Throttled position stream to ~4 Hz (250 ms) for smooth UI without excess rebuilds
    _subscriptions.add(
      _player.positionStream.listen((pos) {
        final now = DateTime.now();
        if (now.difference(_lastPositionEmission).inMilliseconds >= 240) {
          _lastPositionEmission = now;
          _positionCtrl.add(pos);
          _syncSystemMedia();
        }
      }),
    );

    // Duration stream
    _subscriptions.add(
      _player.durationStream.listen((dur) {
        _durationCtrl.add(dur ?? _queueState.currentTrack?.duration);
        _syncSystemMedia();
      }),
    );

    // Sequence / current index updates
    _subscriptions.add(
      _player.currentIndexStream.listen((idx) {
        if (idx != null && idx != _queueState.currentIndex && idx < _queueState.tracks.length) {
          _queueState = _queueState.copyWith(currentIndex: idx);
          _currentTrackCtrl.add(_queueState.currentTrack);
          _queueCtrl.add(_queueState);
          _syncSystemMedia();
        }
      }),
    );

    // Playback state transitions (auto-advance)
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          next(auto: true);
        }
      }),
    );

    // Prepare initial playlist
    await _loadCurrentPlaylist();
    _emitInitial();
  }

  void _wireHandler() {
    if (handler == null) return;
    handler!.onPlay = play;
    handler!.onPause = pause;
    handler!.onSeek = seek;
    handler!.onSkipToNext = next;
    handler!.onSkipToPrevious = previous;
    handler!.onSkipToQueueItem = jumpTo;
    handler!.onSetShuffle = setShuffle;
    handler!.onSetRepeat = setRepeat;
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _subscriptions.add(
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            pause();
          } else if (event.type == AudioInterruptionType.duck) {
            // Volume ducking handled by system
          }
        }),
      );

      _subscriptions.add(
        session.becomingNoisyEventStream.listen((_) {
          pause();
        }),
      );
    } catch (_) {
      // AudioSession may not be supported on all desktop test environments
    }
  }

  void _syncSystemMedia() {
    final track = _queueState.currentTrack;
    handler?.updateCurrentTrack(track);
    handler?.syncTracks(_queueState.tracks);
    handler?.updatePlaybackState(
      isPlaying: _player.playing,
      position: _player.position,
      duration: _player.duration ?? track?.duration,
      hasPrevious: _queueState.hasPrevious,
      hasNext: _queueState.hasNext,
    );
  }

  void _emitInitial() {
    _currentTrackCtrl.add(_queueState.currentTrack);
    _durationCtrl.add(_queueState.currentTrack?.duration);
    _queueCtrl.add(_queueState);
    _playingCtrl.add(_player.playing);
    _positionCtrl.add(_player.position);
    _syncSystemMedia();
  }

  Future<void> _loadCurrentPlaylist() async {
    try {
      final audioSources = <AudioSource>[];
      for (final t in _queueState.tracks) {
        if (t.path != null && File(t.path!).existsSync()) {
          audioSources.add(AudioSource.file(t.path!, tag: t));
        }
      }

      if (audioSources.isNotEmpty) {
        final playlist = ConcatenatingAudioSource(children: audioSources);
        await _player.setAudioSource(
          playlist,
          initialIndex: _queueState.currentIndex.clamp(0, audioSources.length - 1),
          initialPosition: Duration.zero,
        );
      }
    } catch (_) {
      // Never crash on unreadable files
    }
  }

  @override
  Stream<bool> get playing async* {
    yield _player.playing;
    yield* _playingCtrl.stream;
  }

  @override
  Stream<Duration> get position async* {
    yield _player.position;
    yield* _positionCtrl.stream;
  }

  @override
  Stream<Duration?> get duration async* {
    yield _player.duration ?? _queueState.currentTrack?.duration;
    yield* _durationCtrl.stream;
  }

  @override
  Stream<Track?> get currentTrack async* {
    yield _queueState.currentTrack;
    yield* _currentTrackCtrl.stream;
  }

  @override
  Stream<QueueState> get queue async* {
    yield _queueState;
    yield* _queueCtrl.stream;
  }

  @override
  Future<void> setQueue(List<Track> tracks, {int index = 0, bool play = true}) async {
    _queueState = _queueState.copyWith(
      tracks: tracks,
      currentIndex: tracks.isEmpty ? 0 : index.clamp(0, tracks.length - 1),
    );
    _emitInitial();
    await _loadCurrentPlaylist();
    if (play) {
      await this.play();
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> toggle() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> seek(Duration p) async {
    try {
      await _player.seek(p);
      _positionCtrl.add(p);
    } catch (_) {}
  }

  @override
  Future<void> next({bool auto = false}) async {
    final tracks = _queueState.tracks;
    if (tracks.isEmpty) return;

    if (auto && _queueState.repeat == AudioRepeatMode.one) {
      await seek(Duration.zero);
      await play();
      return;
    }

    if (auto &&
        _queueState.repeat == AudioRepeatMode.off &&
        !_queueState.shuffle &&
        _queueState.currentIndex == tracks.length - 1) {
      await pause();
      await seek(Duration.zero);
      return;
    }

    final nextIndex = (_queueState.currentIndex + 1) % tracks.length;
    await jumpTo(nextIndex);
  }

  @override
  Future<void> previous() async {
    if (_player.position.inSeconds < 3 && _queueState.tracks.length > 1) {
      final prevIndex = (_queueState.currentIndex - 1 + _queueState.tracks.length) % _queueState.tracks.length;
      await jumpTo(prevIndex);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queueState.tracks.length) return;
    _queueState = _queueState.copyWith(currentIndex: index);
    _currentTrackCtrl.add(_queueState.currentTrack);
    _queueCtrl.add(_queueState);

    try {
      if (_player.audioSource != null) {
        await _player.seek(Duration.zero, index: index);
      }
    } catch (_) {}

    _syncSystemMedia();
  }

  @override
  Future<void> setShuffle(bool on) async {
    _queueState = _queueState.copyWith(shuffle: on);
    _queueCtrl.add(_queueState);
    try {
      await _player.setShuffleModeEnabled(on);
    } catch (_) {}
    _syncSystemMedia();
  }

  @override
  Future<void> setRepeat(AudioRepeatMode m) async {
    _queueState = _queueState.copyWith(repeat: m);
    _queueCtrl.add(_queueState);
    try {
      final loopMode = switch (m) {
        AudioRepeatMode.off => LoopMode.off,
        AudioRepeatMode.all => LoopMode.all,
        AudioRepeatMode.one => LoopMode.one,
      };
      await _player.setLoopMode(loopMode);
    } catch (_) {}
    _syncSystemMedia();
  }

  @override
  Future<void> playNext(Track t) async {
    final newTracks = List<Track>.from(_queueState.tracks);
    final insertIndex = (_queueState.currentIndex + 1).clamp(0, newTracks.length);
    newTracks.insert(insertIndex, t);
    _queueState = _queueState.copyWith(tracks: newTracks);
    _queueCtrl.add(_queueState);
    _syncSystemMedia();
  }

  @override
  Future<void> addToEnd(Track t) async {
    final newTracks = List<Track>.from(_queueState.tracks)..add(t);
    _queueState = _queueState.copyWith(tracks: newTracks);
    _queueCtrl.add(_queueState);
    _syncSystemMedia();
  }

  @override
  Future<void> removeAt(int i) async {
    if (i < 0 || i >= _queueState.tracks.length) return;
    final newTracks = List<Track>.from(_queueState.tracks)..removeAt(i);
    int newIndex = _queueState.currentIndex;
    if (i < newIndex) {
      newIndex--;
    } else if (newIndex >= newTracks.length) {
      newIndex = newTracks.isEmpty ? 0 : newTracks.length - 1;
    }
    _queueState = _queueState.copyWith(tracks: newTracks, currentIndex: newIndex);
    _currentTrackCtrl.add(_queueState.currentTrack);
    _queueCtrl.add(_queueState);
    _syncSystemMedia();
  }

  @override
  Future<void> move(int from, int to) async {
    if (from < 0 || from >= _queueState.tracks.length) return;
    if (to < 0 || to >= _queueState.tracks.length) return;
    final newTracks = List<Track>.from(_queueState.tracks);
    final item = newTracks.removeAt(from);
    newTracks.insert(to, item);

    int newIndex = _queueState.currentIndex;
    if (_queueState.currentIndex == from) {
      newIndex = to;
    } else if (from < _queueState.currentIndex && to >= _queueState.currentIndex) {
      newIndex--;
    } else if (from > _queueState.currentIndex && to <= _queueState.currentIndex) {
      newIndex++;
    }
    _queueState = _queueState.copyWith(tracks: newTracks, currentIndex: newIndex);
    _currentTrackCtrl.add(_queueState.currentTrack);
    _queueCtrl.add(_queueState);
    _syncSystemMedia();
  }

  @override
  Future<void> setSleepTimer(Duration? after) async {
    _sleepTimer?.cancel();
    if (after != null) {
      _sleepTimer = Timer(after, () => pause());
    }
  }

  @override
  Future<void> dispose() async {
    _sleepTimer?.cancel();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
    await _playingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _currentTrackCtrl.close();
    await _queueCtrl.close();
  }
}
