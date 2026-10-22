import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vesper/data/db/database.dart';
import 'package:vesper/data/repositories/library_repository.dart';
import 'package:vesper/data/scanner/library_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late Directory musicDir;
  late Directory cacheDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('vesper_test_');
    musicDir = Directory(p.join(tempDir.path, 'Music'))
      ..createSync(recursive: true);
    cacheDir = Directory(p.join(tempDir.path, 'Cache'))
      ..createSync(recursive: true);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Library Scanner and Database Tests', () {
    test('scans audio files and extracts metadata fallbacks', () async {
      // Create mock audio files with "Artist - Title.mp3" format
      final file1 = File(
        p.join(musicDir.path, 'Marlowe Reyes - Low Tide Hours.mp3'),
      )..writeAsStringSync('dummy audio content 1');
      final file2 = File(
        p.join(musicDir.path, 'The Quiet Hours - Concrete Garden.flac'),
      )..writeAsStringSync('dummy audio content 2');

      final scanner = LibraryScanner(db: db, cacheDir: cacheDir);
      final progressEvents = await scanner.scanFolder(musicDir.path).toList();

      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.isComplete, isTrue);

      final tracks = await db.select(db.tracks).get();
      expect(tracks.length, 2);

      final track1 = tracks.firstWhere((t) => t.path == file1.path);
      expect(track1.title, 'Low Tide Hours');
      expect(track1.albumArtist, 'Marlowe Reyes');

      final track2 = tracks.firstWhere((t) => t.path == file2.path);
      expect(track2.title, 'Concrete Garden');
      expect(track2.albumArtist, 'The Quiet Hours');
    });

    test(
      'incremental scan skips unchanged files based on mtime and size',
      () async {
        final file = File(p.join(musicDir.path, 'Test Artist - Song.mp3'))
          ..writeAsStringSync('audio data');

        final scanner = LibraryScanner(db: db, cacheDir: cacheDir);
        await scanner.scanFolder(musicDir.path).drain();

        final firstTrack = await db.select(db.tracks).getSingle();
        final initialAddedAt = firstTrack.addedAt;

        // Rescan without modifying file
        await scanner.scanFolder(musicDir.path).drain();

        final rescanTrack = await db.select(db.tracks).getSingle();
        expect(rescanTrack.addedAt, initialAddedAt);
        expect(rescanTrack.path, file.path);
      },
    );

    test('removed files are pruned from the database on rescan', () async {
      final file = File(p.join(musicDir.path, 'Ephemeral - Gone.mp3'))
        ..writeAsStringSync('temp data');

      final scanner = LibraryScanner(db: db, cacheDir: cacheDir);
      await scanner.scanFolder(musicDir.path).drain();

      var tracks = await db.select(db.tracks).get();
      expect(tracks.length, 1);

      // Delete file from disk
      file.deleteSync();

      // Rescan folder
      await scanner.scanFolder(musicDir.path).drain();

      tracks = await db.select(db.tracks).get();
      expect(tracks, isEmpty);
    });

    test(
      'LibraryRepository search queries titles and artists correctly',
      () async {
        final repo = LibraryRepository(database: db, cacheDir: cacheDir);

        File(
          p.join(musicDir.path, 'Aarav Menon - Slow Horizon.mp3'),
        ).writeAsStringSync('content');

        final scanner = LibraryScanner(db: db, cacheDir: cacheDir);
        await scanner.scanFolder(musicDir.path).drain();

        final titleResults = await repo.search('Horizon');
        expect(titleResults.length, 1);
        expect(titleResults.first.title, 'Slow Horizon');

        final artistResults = await repo.search('Aarav');
        expect(artistResults.length, 1);
        expect(artistResults.first.artist, 'Aarav Menon');

        final noResults = await repo.search('Nonexistent');
        expect(noResults, isEmpty);
      },
    );
  });
}
