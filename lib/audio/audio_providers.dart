import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/palette.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models/queue_state.dart';
import '../domain/models/track.dart';
import 'audio_player_service.dart';
import 'fake_audio_service.dart';

import 'just_audio_service.dart';

/// Service provider. Uses real JustAudioService with graceful fallback to FakeAudioService in tests.
final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  try {
    final service = JustAudioService();
    ref.onDispose(() => service.dispose());
    return service;
  } catch (_) {
    final service = FakeAudioService();
    ref.onDispose(() => service.dispose());
    return service;
  }
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

final currentPaletteProvider = Provider<VesperPalette>((ref) {
  final accentMode = ref.watch(accentModeProvider);
  if (accentMode == 'fixed') {
    return VesperPalette.fallback;
  }
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

class SleepTimerNotifier extends Notifier<Duration?> {
  @override
  Duration? build() => null;

  void setTimer(Duration? duration) {
    state = duration;
    ref.read(audioServiceProvider).setSleepTimer(duration);
  }

  void cancel() {
    setTimer(null);
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, Duration?>(
  SleepTimerNotifier.new,
);

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

final queuePersistenceManagerProvider = Provider<QueuePersistenceManager>((
  ref,
) {
  final audio = ref.watch(audioServiceProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return QueuePersistenceManager(audio: audio, settings: settings);
});

class QueuePersistenceManager {
  QueuePersistenceManager({required this.audio, required this.settings});

  final AudioPlayerService audio;
  final SettingsRepository settings;

  Future<void> saveCurrentState({Duration? currentPosition}) async {
    try {
      final queue = await audio.queue.first;
      if (queue.tracks.isEmpty) return;
      final pos = currentPosition ?? await audio.position.first;

      await settings.saveQueueState(
        PersistedQueueState(
          trackIds: queue.tracks.map((t) => t.id).toList(),
          currentIndex: queue.currentIndex,
          positionMs: pos.inMilliseconds,
          shuffle: queue.shuffle,
          repeat: queue.repeat,
        ),
      );
    } catch (_) {}
  }

  Future<void> restoreState() async {
    try {
      final saved = await settings.loadQueueState();
      if (saved == null || saved.trackIds.isEmpty) return;

      final tracks = await settings.resolveTracks(saved.trackIds, fakeTracks);
      if (tracks.isEmpty) return;

      final index = saved.currentIndex.clamp(0, tracks.length - 1);
      await audio.setQueue(tracks, index: index, play: false);
      if (saved.positionMs > 0) {
        await audio.seek(Duration(milliseconds: saved.positionMs));
      }
      await audio.setShuffle(saved.shuffle);
      await audio.setRepeat(saved.repeat);
    } catch (_) {}
  }
}
