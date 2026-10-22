import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/palette.dart';
import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';
import 'audio_player_service.dart';
import 'fake_audio_service.dart';

/// Service provider. Can be overridden in tests or for real playback in P2.
final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = FakeAudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playing;
});

/// Isolated position stream throttled to ~4 Hz.
/// ONLY the SeekBar listens to this provider.
final positionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.position;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.duration;
});

final currentTrackProvider = StreamProvider<Track?>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.currentTrack;
});

final queueStateProvider = StreamProvider<QueueState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.queue;
});

/// Computes palette from current track. If the track declares a palette, use it;
/// otherwise use fallback. (ImageProvider derivation handles real artwork in P3).
final currentPaletteProvider = Provider<VesperPalette>((ref) {
  final trackAsync = ref.watch(currentTrackProvider);
  final track = trackAsync.value;
  if (track == null || track.palette.length < 3) {
    return VesperPalette.fallback;
  }
  return VesperPalette(
    deep: track.palette[0],
    mid: track.palette[1],
    light: track.palette[2],
  );
});

class LikedTracksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String trackId) {
    if (state.contains(trackId)) {
      state = {...state}..remove(trackId);
    } else {
      state = {...state, trackId};
    }
  }

  bool isLiked(String trackId) => state.contains(trackId);
}

final likedTracksProvider = NotifierProvider<LikedTracksNotifier, Set<String>>(
  LikedTracksNotifier.new,
);
