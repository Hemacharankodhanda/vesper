import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/album.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/track.dart';
import '../db/database.dart' as app_db;
import '../scanner/library_scanner.dart';

final appDatabaseProvider = Provider<app_db.AppDatabase>((ref) {
  final database = app_db.AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return LibraryRepository(database: database);
});

final libraryTracksProvider = StreamProvider<List<Track>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.watchTracks();
});

final libraryAlbumsProvider = StreamProvider<List<Album>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.watchAlbums();
});

final libraryArtistsProvider = StreamProvider<List<Artist>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.watchArtists();
});

final libraryFoldersProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.watchFolders();
});

class LibraryRepository {
  LibraryRepository({required this.database, this.cacheDir});

  final app_db.AppDatabase database;
  Directory? cacheDir;

  Future<Directory> _getCacheDir() async {
    if (cacheDir != null) return cacheDir!;
    cacheDir = await getApplicationSupportDirectory();
    return cacheDir!;
  }

  Stream<List<Track>> watchTracks() {
    return (database.select(database.tracks)
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch()
        .map((rows) => rows.map(_mapTrackRow).toList());
  }

  Stream<List<Album>> watchAlbums() {
    return (database.select(database.albums)
          ..orderBy([(a) => OrderingTerm.asc(a.title)]))
        .watch()
        .map((rows) => rows.map(_mapAlbumRow).toList());
  }

  Stream<List<Artist>> watchArtists() {
    return (database.select(database.artists)
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch()
        .map((rows) => rows.map(_mapArtistRow).toList());
  }

  Stream<List<String>> watchFolders() {
    return (database.select(database.libraryFolders)
          ..orderBy([(f) => OrderingTerm.asc(f.path)]))
        .watch()
        .map((rows) => rows.map((r) => r.path).toList());
  }

  Future<void> addFolder(String path) async {
    await database
        .into(database.libraryFolders)
        .insertOnConflictUpdate(
          app_db.LibraryFoldersCompanion.insert(id: path, path: path),
        );
  }

  Future<void> removeFolder(String path) async {
    await (database.delete(
      database.libraryFolders,
    )..where((f) => f.path.equals(path))).go();
    await (database.delete(
      database.tracks,
    )..where((t) => t.path.like('$path%'))).go();
  }

  Future<void> toggleLike(String trackId) async {
    final track = await (database.select(
      database.tracks,
    )..where((t) => t.id.equals(trackId))).getSingleOrNull();
    if (track != null) {
      await (database.update(database.tracks)
            ..where((t) => t.id.equals(trackId)))
          .write(app_db.TracksCompanion(liked: Value(!track.liked)));
    }
  }

  Future<List<Track>> search(String query) async {
    final normalized = '%${query.toLowerCase()}%';
    final rows =
        await (database.select(database.tracks)..where(
              (t) =>
                  t.title.lower().like(normalized) |
                  (t.albumArtist.isNotNull() &
                      t.albumArtist.lower().like(normalized)),
            ))
            .get();
    return rows.map(_mapTrackRow).toList();
  }

  Stream<ScanProgress> scanAllFolders() async* {
    final folders = await (database.select(database.libraryFolders)).get();
    final cache = await _getCacheDir();
    final scanner = LibraryScanner(db: database, cacheDir: cache);

    for (final folder in folders) {
      yield* scanner.scanFolder(folder.path);
    }
  }

  Track _mapTrackRow(app_db.Track row) {
    String? artPath;
    if (row.artHash != null && cacheDir != null) {
      artPath = p.join(cacheDir!.path, 'covers', '${row.artHash}.jpg');
    }

    return Track(
      id: row.id,
      title: row.title,
      artist: row.albumArtist ?? 'Unknown Artist',
      album: row.albumId ?? 'Unknown Album',
      duration: Duration(milliseconds: row.durationMs),
      path: row.path,
      artPath: artPath,
      artHash: row.artHash,
    );
  }

  Album _mapAlbumRow(app_db.Album row) {
    return Album(
      id: row.id,
      title: row.title,
      albumArtist: row.albumArtist,
      year: row.year,
      artHash: row.artHash,
    );
  }

  Artist _mapArtistRow(app_db.Artist row) {
    return Artist(id: row.id, name: row.name);
  }
}
