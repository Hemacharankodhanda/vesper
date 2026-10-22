import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/audio/audio_providers.dart';
import 'package:vesper/audio/fake_audio_service.dart';
import 'package:vesper/data/db/database.dart';
import 'package:vesper/data/repositories/settings_repository.dart';
import 'package:vesper/domain/models/queue_state.dart';
import 'package:vesper/domain/models/track.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settingsRepo;
  late FakeAudioService fakeAudio;
  late QueuePersistenceManager manager;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsRepo = SettingsRepository(database: db);
    fakeAudio = FakeAudioService();
    manager = QueuePersistenceManager(audio: fakeAudio, settings: settingsRepo);

    // Insert fake tracks into DB
    for (final t in fakeTracks) {
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: t.id,
              path: '/music/${t.id}.mp3',
              title: t.title,
              albumArtist: drift.Value(t.artist),
              albumId: drift.Value(t.album),
              durationMs: t.duration.inMilliseconds,
              addedAt: DateTime.now(),
              mtime: DateTime.now(),
              sizeBytes: 1024,
            ),
          );
    }
  });

  tearDown(() async {
    await fakeAudio.dispose();
    await db.close();
  });

  group('Queue Persistence Tests', () {
    test('saveQueueState and loadQueueState round-trips correctly', () async {
      const state = PersistedQueueState(
        trackIds: ['track_1', 'track_2'],
        currentIndex: 1,
        positionMs: 45000,
        shuffle: true,
        repeat: AudioRepeatMode.all,
      );

      await settingsRepo.saveQueueState(state);
      final loaded = await settingsRepo.loadQueueState();

      expect(loaded, isNotNull);
      expect(loaded!.trackIds, ['track_1', 'track_2']);
      expect(loaded.currentIndex, 1);
      expect(loaded.positionMs, 45000);
      expect(loaded.shuffle, isTrue);
      expect(loaded.repeat, AudioRepeatMode.all);
    });

    test('QueuePersistenceManager saves and restores queue paused at position', () async {
      await fakeAudio.setQueue(fakeTracks, index: 2, play: true);
      await fakeAudio.seek(const Duration(seconds: 42));

      await manager.saveCurrentState(currentPosition: const Duration(seconds: 42));

      // Reset fake audio to fresh state
      await fakeAudio.setQueue([], index: 0, play: false);

      // Restore
      await manager.restoreState();

      final queue = await fakeAudio.queue.first;
      expect(queue.tracks.length, fakeTracks.length);
      expect(queue.currentIndex, 2);

      final isPlaying = await fakeAudio.playing.first;
      expect(isPlaying, isFalse); // Must restore paused mid-song per roadmap

      final position = await fakeAudio.position.first;
      expect(position.inSeconds, 42);
    });
  });
}
