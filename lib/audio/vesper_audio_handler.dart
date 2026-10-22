import 'package:audio_service/audio_service.dart';
import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';

/// Background audio handler that bridges Vesper to Android system notifications,
/// lock screen media controls, headset events, and desktop SMTC.
class VesperAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  VesperAudioHandler();

  Function()? onPlay;
  Function()? onPause;
  Function(Duration position)? onSeek;
  Function()? onSkipToNext;
  Function()? onSkipToPrevious;
  Function(int index)? onSkipToQueueItem;
  Function(bool enabled)? onSetShuffle;
  Function(AudioRepeatMode mode)? onSetRepeat;

  void updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration? duration,
    required bool hasPrevious,
    required bool hasNext,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (hasPrevious) MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          if (hasNext) MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: duration ?? position,
        speed: 1.0,
      ),
    );
  }

  void updateCurrentTrack(Track? track) {
    if (track == null) {
      mediaItem.add(null);
      return;
    }

    mediaItem.add(
      MediaItem(
        id: track.id,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: track.artPath != null ? Uri.file(track.artPath!) : null,
      ),
    );
  }

  void syncTracks(List<Track> tracks) {
    queue.add(
      tracks.map((t) => MediaItem(
        id: t.id,
        album: t.album,
        title: t.title,
        artist: t.artist,
        duration: t.duration,
        artUri: t.artPath != null ? Uri.file(t.artPath!) : null,
      )).toList(),
    );
  }

  @override
  Future<void> play() async => onPlay?.call();

  @override
  Future<void> pause() async => onPause?.call();

  @override
  Future<void> stop() async => onPause?.call();

  @override
  Future<void> seek(Duration position) async => onSeek?.call(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> skipToQueueItem(int index) async => onSkipToQueueItem?.call(index);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final isEnabled = shuffleMode != AudioServiceShuffleMode.none;
    onSetShuffle?.call(isEnabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final mode = switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioRepeatMode.off,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => AudioRepeatMode.all,
      AudioServiceRepeatMode.one => AudioRepeatMode.one,
    };
    onSetRepeat?.call(mode);
  }
}
