import 'track.dart';

enum AudioRepeatMode { off, all, one }

class QueueState {
  const QueueState({
    required this.tracks,
    required this.currentIndex,
    this.shuffle = false,
    this.repeat = AudioRepeatMode.off,
  });

  final List<Track> tracks;
  final int currentIndex;
  final bool shuffle;
  final AudioRepeatMode repeat;

  Track? get currentTrack {
    if (tracks.isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  bool get hasNext =>
      tracks.isNotEmpty &&
      (currentIndex < tracks.length - 1 || repeat != AudioRepeatMode.off);
  bool get hasPrevious =>
      tracks.isNotEmpty && (currentIndex > 0 || repeat != AudioRepeatMode.off);

  QueueState copyWith({
    List<Track>? tracks,
    int? currentIndex,
    bool? shuffle,
    AudioRepeatMode? repeat,
  }) {
    return QueueState(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
    );
  }

  static const QueueState empty = QueueState(
    tracks: [],
    currentIndex: 0,
    shuffle: false,
    repeat: AudioRepeatMode.off,
  );
}
