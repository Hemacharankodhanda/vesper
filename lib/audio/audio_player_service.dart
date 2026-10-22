import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';

abstract class AudioPlayerService {
  Stream<bool> get playing;
  Stream<Duration> get position; // throttled to ~4 Hz for UI
  Stream<Duration?> get duration;
  Stream<Track?> get currentTrack;
  Stream<QueueState> get queue;

  Future<void> setQueue(List<Track> tracks, {int index = 0, bool play = true});
  Future<void> play();
  Future<void> pause();
  Future<void> toggle();
  Future<void> seek(Duration p);
  Future<void> next();
  Future<void> previous();
  Future<void> jumpTo(int index);
  Future<void> setShuffle(bool on);
  Future<void> setRepeat(AudioRepeatMode m);
  Future<void> playNext(Track t);
  Future<void> addToEnd(Track t);
  Future<void> removeAt(int i);
  Future<void> move(int from, int to);
  Future<void> setSleepTimer(Duration? after);
  Future<void> dispose();
}
