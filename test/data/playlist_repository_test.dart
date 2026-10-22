import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/data/db/database.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/data/repositories/playlist_repository.dart';
import 'package:vesper/domain/models/track.dart';

void main() {
  late AppDatabase db;
  late PlaylistRepository playlistRepo;
  late LibraryRepository libraryRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    playlistRepo = PlaylistRepository(database: db);
    libraryRepo = LibraryRepository(database: db);

    // Insert fake tracks
    for (final t in fakeTracks) {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              id: t.id,
              path: '/music/${t.id}.mp3',
              title: t.title,
              durationMs: t.duration.inMilliseconds,
              addedAt: DateTime.now(),
              mtime: DateTime.now(),
              sizeBytes: 1024,
            ),
          );
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('Playlist & Like & History Tests', () {
    test('creates, renames, and deletes playlist with tracks', () async {
      // 1. Create
      final playlist = await playlistRepo.createPlaylist('Night Vibes');
      expect(playlist.name, 'Night Vibes');

      // 2. Add tracks
      await playlistRepo.addTrackToPlaylist(playlist.id, 'track_1');
      await playlistRepo.addTrackToPlaylist(playlist.id, 'track_2');

      final tracks = await playlistRepo.getPlaylistTracks(playlist.id);
      expect(tracks.length, 2);
      expect(tracks[0].id, 'track_1');
      expect(tracks[1].id, 'track_2');

      // 3. Rename
      await playlistRepo.renamePlaylist(playlist.id, 'Chill Frequencies');
      final playlists = await playlistRepo.watchPlaylists().first;
      expect(playlists.first.name, 'Chill Frequencies');

      // 4. Delete
      await playlistRepo.deletePlaylist(playlist.id);
      final remaining = await playlistRepo.watchPlaylists().first;
      expect(remaining.isEmpty, isTrue);

      final tracksAfter = await playlistRepo.getPlaylistTracks(playlist.id);
      expect(tracksAfter.isEmpty, isTrue);
    });

    test('toggleLike persists liked boolean on track', () async {
      final initialTrack = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals('track_1'))).getSingle();
      expect(initialTrack.liked, isFalse);

      await libraryRepo.toggleLike('track_1');
      final likedTrack = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals('track_1'))).getSingle();
      expect(likedTrack.liked, isTrue);

      await libraryRepo.toggleLike('track_1');
      final unlikedTrack = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals('track_1'))).getSingle();
      expect(unlikedTrack.liked, isFalse);
    });

    test('recordTrackPlayed updates playCount and lastPlayedAt', () async {
      await libraryRepo.recordTrackPlayed('track_1');
      final track1 = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals('track_1'))).getSingle();
      expect(track1.playCount, 1);
      expect(track1.lastPlayedAt, isNotNull);

      await libraryRepo.recordTrackPlayed('track_1');
      final track2 = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals('track_1'))).getSingle();
      expect(track2.playCount, 2);
    });
  });
}
