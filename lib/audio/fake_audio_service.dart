import 'dart:async';
import 'dart:math' as math;
import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';
import 'audio_player_service.dart';

class FakeAudioService implements AudioPlayerService {
  FakeAudioService({List<Track>? initialTracks, int initialIndex = 0}) {
    final list = initialTracks ?? fakeTracks;
    _queueState = QueueState(
      tracks: list,
      currentIndex: list.isEmpty ? 0 : initialIndex.clamp(0, list.length - 1),
    );
    _emitState();
  }

  late QueueState _queueState;
  bool _playing = false;
  Duration _position = Duration.zero;
  Timer? _ticker;
  Timer? _sleepTimer;
  final _rng = math.Random();

  final _playingCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration?>.broadcast();
  final _currentTrackCtrl = StreamController<Track?>.broadcast();
  final _queueCtrl = StreamController<QueueState>.broadcast();

  @override
  Stream<bool> get playing async* {
    yield _playing;
    yield* _playingCtrl.stream;
  }

  @override
  Stream<Duration> get position async* {
    yield _position;
    yield* _positionCtrl.stream;
  }

  @override
  Stream<Duration?> get duration async* {
    yield _queueState.currentTrack?.duration;
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

  void _emitState() {
    _currentTrackCtrl.add(_queueState.currentTrack);
    _durationCtrl.add(_queueState.currentTrack?.duration);
    _queueCtrl.add(_queueState);
  }

  void _tick() {
    final track = _queueState.currentTrack;
    if (track == null) return;

    _position += const Duration(milliseconds: 250);
    if (_position >= track.duration) {
      next(auto: true);
    } else {
      _positionCtrl.add(_position);
    }
  }

  @override
  Future<void> setQueue(
    List<Track> tracks, {
    int index = 0,
    bool play = true,
  }) async {
    _queueState = _queueState.copyWith(
      tracks: tracks,
      currentIndex: tracks.isEmpty ? 0 : index.clamp(0, tracks.length - 1),
    );
    _position = Duration.zero;
    _positionCtrl.add(_position);
    _emitState();
    if (play) {
      await this.play();
    } else {
      await pause();
    }
  }

  @override
  Future<void> play() async {
    if (_playing) return;
    _playing = true;
    _playingCtrl.add(true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  Future<void> pause() async {
    if (!_playing) return;
    _playing = false;
    _playingCtrl.add(false);
    _ticker?.cancel();
  }

  @override
  Future<void> toggle() async {
    if (_playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> seek(Duration p) async {
    final curTrack = _queueState.currentTrack;
    if (curTrack == null) return;
    final maxMs = curTrack.duration.inMilliseconds;
    final clampedMs = p.inMilliseconds.clamp(0, maxMs);
    _position = Duration(milliseconds: clampedMs);
    _positionCtrl.add(_position);
  }

  @override
  Future<void> next({bool auto = false}) async {
    final tracks = _queueState.tracks;
    if (tracks.isEmpty) return;

    if (auto && _queueState.repeat == AudioRepeatMode.one) {
      _position = Duration.zero;
      _positionCtrl.add(_position);
      return;
    }

    if (auto &&
        _queueState.repeat == AudioRepeatMode.off &&
        !_queueState.shuffle &&
        _queueState.currentIndex == tracks.length - 1) {
      _position = Duration.zero;
      _positionCtrl.add(_position);
      await pause();
      return;
    }

    int nextIndex;
    if (_queueState.shuffle && tracks.length > 1) {
      do {
        nextIndex = _rng.nextInt(tracks.length);
      } while (nextIndex == _queueState.currentIndex);
    } else {
      nextIndex = (_queueState.currentIndex + 1) % tracks.length;
    }

    _queueState = _queueState.copyWith(currentIndex: nextIndex);
    _position = Duration.zero;
    _positionCtrl.add(_position);
    _emitState();
  }

  @override
  Future<void> previous() async {
    final tracks = _queueState.tracks;
    if (tracks.isEmpty) return;

    if (_position.inSeconds < 3 && tracks.length > 1) {
      final prevIndex =
          (_queueState.currentIndex - 1 + tracks.length) % tracks.length;
      _queueState = _queueState.copyWith(currentIndex: prevIndex);
    }
    _position = Duration.zero;
    _positionCtrl.add(_position);
    _emitState();
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queueState.tracks.length) return;
    _queueState = _queueState.copyWith(currentIndex: index);
    _position = Duration.zero;
    _positionCtrl.add(_position);
    _emitState();
  }

  @override
  Future<void> setShuffle(bool on) async {
    _queueState = _queueState.copyWith(shuffle: on);
    _queueCtrl.add(_queueState);
  }

  @override
  Future<void> setRepeat(AudioRepeatMode m) async {
    _queueState = _queueState.copyWith(repeat: m);
    _queueCtrl.add(_queueState);
  }

  @override
  Future<void> playNext(Track t) async {
    final newTracks = List<Track>.from(_queueState.tracks);
    final insertIndex = (_queueState.currentIndex + 1).clamp(
      0,
      newTracks.length,
    );
    newTracks.insert(insertIndex, t);
    _queueState = _queueState.copyWith(tracks: newTracks);
    _queueCtrl.add(_queueState);
  }

  @override
  Future<void> addToEnd(Track t) async {
    final newTracks = List<Track>.from(_queueState.tracks)..add(t);
    _queueState = _queueState.copyWith(tracks: newTracks);
    _queueCtrl.add(_queueState);
  }

  @override
  Future<void> removeAt(int i) async {
    if (i < 0 || i >= _queueState.tracks.length) return;
    final newTracks = List<Track>.from(_queueState.tracks)..removeAt(i);
    int newIndex = _queueState.currentIndex;
    if (i < newIndex) {
      newIndex--;
    } else if (newIndex >= newTracks.length) {
      newIndex = math.max(0, newTracks.length - 1);
    }
    _queueState = _queueState.copyWith(
      tracks: newTracks,
      currentIndex: newIndex,
    );
    _emitState();
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
    } else if (from < _queueState.currentIndex &&
        to >= _queueState.currentIndex) {
      newIndex--;
    } else if (from > _queueState.currentIndex &&
        to <= _queueState.currentIndex) {
      newIndex++;
    }
    _queueState = _queueState.copyWith(
      tracks: newTracks,
      currentIndex: newIndex,
    );
    _emitState();
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
    _ticker?.cancel();
    _sleepTimer?.cancel();
    await _playingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _currentTrackCtrl.close();
    await _queueCtrl.close();
  }
}
