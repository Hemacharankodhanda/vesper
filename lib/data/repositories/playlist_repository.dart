import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';
import '../db/database.dart' as app_db;
import 'library_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlaylistRepository(database: db);
});

final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.watchPlaylists();
});

class PlaylistRepository {
  PlaylistRepository({required this.database});

  final app_db.AppDatabase database;

  Stream<List<Playlist>> watchPlaylists() {
    return (database.select(database.playlists)
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => Playlist(
              id: r.id,
              name: r.name,
              createdAt: r.createdAt,
            )).toList());
  }

  Future<Playlist> createPlaylist(String name) async {
    final id = 'pl_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    await database.into(database.playlists).insert(
          app_db.PlaylistsCompanion.insert(
            id: id,
            name: name,
            createdAt: now,
          ),
        );
    return Playlist(id: id, name: name, createdAt: now);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await (database.update(database.playlists)
          ..where((p) => p.id.equals(playlistId)))
        .write(app_db.PlaylistsCompanion(name: Value(newName)));
  }

  Future<void> deletePlaylist(String playlistId) async {
    await (database.delete(database.playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId)))
        .go();
    await (database.delete(database.playlists)
          ..where((p) => p.id.equals(playlistId)))
        .go();
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    // Get max position
    final existing = await (database.select(database.playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId)))
        .get();

    final nextPos = existing.isEmpty
        ? 0
        : existing.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;

    await database.into(database.playlistTracks).insertOnConflictUpdate(
          app_db.PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: trackId,
            position: nextPos,
          ),
        );
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    await (database.delete(database.playlistTracks)
          ..where((pt) =>
              pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
        .go();
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final ptRows = await (database.select(database.playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId))
          ..orderBy([(pt) => OrderingTerm.asc(pt.position)]))
        .get();

    if (ptRows.isEmpty) return [];

    final trackIds = ptRows.map((r) => r.trackId).toList();
    final trackRows = await (database.select(database.tracks)
          ..where((t) => t.id.isIn(trackIds)))
        .get();

    final trackMap = <String, app_db.Track>{
      for (final r in trackRows) r.id: r,
    };

    final result = <Track>[];
    for (final id in trackIds) {
      final r = trackMap[id];
      if (r != null) {
        result.add(Track(
          id: r.id,
          title: r.title,
          artist: r.albumArtist ?? 'Unknown Artist',
          album: r.albumId ?? 'Unknown Album',
          duration: Duration(milliseconds: r.durationMs),
          path: r.path,
          artHash: r.artHash,
        ));
      }
    }
    return result;
  }
}
