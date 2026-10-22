import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import '../db/database.dart';

class ScanProgress {
  const ScanProgress({
    required this.scanned,
    required this.total,
    required this.currentFile,
    this.isComplete = false,
  });

  final int scanned;
  final int total;
  final String currentFile;
  final bool isComplete;

  double get fraction => total > 0 ? (scanned / total).clamp(0.0, 1.0) : 0.0;
}

class LibraryScanner {
  LibraryScanner({required this.db, required this.cacheDir});

  final AppDatabase db;
  final Directory cacheDir;

  static const _supportedExtensions = {
    '.mp3',
    '.flac',
    '.m4a',
    '.aac',
    '.ogg',
    '.opus',
    '.wav',
    '.wma',
  };

  /// Scans a directory recursively and updates the database incrementally.
  Stream<ScanProgress> scanFolder(String folderPath) async* {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      yield const ScanProgress(
        scanned: 0,
        total: 0,
        currentFile: '',
        isComplete: true,
      );
      return;
    }

    // 1. Collect all audio files in the folder tree
    final audioFiles = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (_supportedExtensions.contains(ext)) {
          audioFiles.add(entity);
        }
      }
    }

    final total = audioFiles.length;
    yield ScanProgress(
      scanned: 0,
      total: total,
      currentFile: 'Found $total audio files...',
    );

    // 2. Fetch existing tracks under this folder from DB for fast incremental diff
    final existingTracks = await (db.select(
      db.tracks,
    )..where((t) => t.path.like('$folderPath%'))).get();

    final existingMap = {for (final t in existingTracks) t.path: t};
    final currentPaths = <String>{};

    var scanned = 0;
    final tracksToInsert = <TracksCompanion>[];
    final albumsToInsert = <String, AlbumsCompanion>{};
    final artistsToInsert = <String, ArtistsCompanion>{};

    for (final file in audioFiles) {
      currentPaths.add(file.path);
      scanned++;

      yield ScanProgress(
        scanned: scanned,
        total: total,
        currentFile: p.basename(file.path),
      );

      try {
        final stat = file.statSync();
        final existing = existingMap[file.path];

        // Incremental check: if mtime and size match, skip parsing tags!
        if (existing != null &&
            existing.sizeBytes == stat.size &&
            existing.mtime.isAtSameMomentAs(stat.modified)) {
          continue;
        }

        // 3. Read tags with audiotags, falling back to file/folder names
        Tag? tag;
        try {
          tag = await AudioTags.read(file.path);
        } catch (_) {
          tag = null;
        }

        final fallback = _parseFallback(file);
        final title = (tag?.title != null && tag!.title!.trim().isNotEmpty)
            ? tag.title!.trim()
            : fallback.title;

        final artistName =
            (tag?.trackArtist != null && tag!.trackArtist!.trim().isNotEmpty)
            ? tag.trackArtist!.trim()
            : fallback.artist;

        final albumTitle = (tag?.album != null && tag!.album!.trim().isNotEmpty)
            ? tag.album!.trim()
            : fallback.album;

        final durationMs = (tag?.duration != null && tag!.duration! > 0)
            ? tag.duration! * 1000
            : 180000; // fallback 3 minutes if unreadable

        // 4. Extract and hash embedded cover art
        String? artHash;
        if (tag?.pictures != null && tag!.pictures.isNotEmpty) {
          try {
            final pic = tag.pictures.first;
            artHash = _saveCover(pic.bytes);
          } catch (_) {}
        }

        final trackId = _hashString(file.path);
        final artistId = _hashString(artistName.toLowerCase());
        final albumId = _hashString('$albumTitle - $artistName'.toLowerCase());

        artistsToInsert[artistId] = ArtistsCompanion.insert(
          id: artistId,
          name: artistName,
        );

        albumsToInsert[albumId] = AlbumsCompanion.insert(
          id: albumId,
          title: albumTitle,
          albumArtist: Value(artistName),
          year: Value(tag?.year),
          artHash: Value(artHash),
        );

        tracksToInsert.add(
          TracksCompanion.insert(
            id: trackId,
            path: file.path,
            title: title,
            artistId: Value(artistId),
            albumId: Value(albumId),
            albumArtist: Value(artistName),
            trackNo: Value(tag?.trackNumber),
            discNo: Value(tag?.discNumber),
            year: Value(tag?.year),
            genre: Value(tag?.genre),
            durationMs: durationMs,
            format: Value(
              p.extension(file.path).replaceAll('.', '').toUpperCase(),
            ),
            artHash: Value(artHash),
            addedAt: DateTime.now(),
            mtime: stat.modified,
            sizeBytes: stat.size,
          ),
        );

        // 5. Batch insert when reaching batch threshold (500 items)
        if (tracksToInsert.length >= 500) {
          await _batchCommit(tracksToInsert, albumsToInsert, artistsToInsert);
          tracksToInsert.clear();
          albumsToInsert.clear();
          artistsToInsert.clear();
        }
      } catch (_) {
        // Never throw on a bad file: log and continue
      }
    }

    // Flush any remaining records
    if (tracksToInsert.isNotEmpty ||
        albumsToInsert.isNotEmpty ||
        artistsToInsert.isNotEmpty) {
      await _batchCommit(tracksToInsert, albumsToInsert, artistsToInsert);
    }

    // 6. Delete DB records for files that have been deleted or moved
    final removedPaths = existingMap.keys
        .where((p) => !currentPaths.contains(p))
        .toList();
    if (removedPaths.isNotEmpty) {
      await (db.delete(
        db.tracks,
      )..where((t) => t.path.isIn(removedPaths))).go();
    }

    yield ScanProgress(
      scanned: total,
      total: total,
      currentFile: 'Scan complete',
      isComplete: true,
    );
  }

  Future<void> _batchCommit(
    List<TracksCompanion> tracks,
    Map<String, AlbumsCompanion> albums,
    Map<String, ArtistsCompanion> artists,
  ) async {
    await db.transaction(() async {
      for (final artist in artists.values) {
        await db.into(db.artists).insertOnConflictUpdate(artist);
      }
      for (final album in albums.values) {
        await db.into(db.albums).insertOnConflictUpdate(album);
      }
      for (final track in tracks) {
        await db.into(db.tracks).insertOnConflictUpdate(track);
      }
    });
  }

  String _saveCover(List<int> bytes) {
    final hash = _hashBytes(bytes);
    final coversDir = Directory(p.join(cacheDir.path, 'covers'))
      ..createSync(recursive: true);
    final file = File(p.join(coversDir.path, '$hash.jpg'));
    if (!file.existsSync()) {
      file.writeAsBytesSync(bytes);
    }
    return hash;
  }

  static String _hashBytes(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _hashString(String str) => _hashBytes(utf8.encode(str));

  _TagFallback _parseFallback(File file) {
    final filenameWithoutExt = p.basenameWithoutExtension(file.path);
    final parentFolder = p.basename(file.parent.path);

    if (filenameWithoutExt.contains(' - ')) {
      final parts = filenameWithoutExt.split(' - ');
      final artist = parts[0].trim();
      final title = parts.sublist(1).join(' - ').trim();
      return _TagFallback(
        title: title.isEmpty ? filenameWithoutExt : title,
        artist: artist.isEmpty ? 'Unknown Artist' : artist,
        album: parentFolder.isEmpty ? 'Unknown Album' : parentFolder,
      );
    }

    return _TagFallback(
      title: filenameWithoutExt,
      artist: 'Unknown Artist',
      album: parentFolder.isEmpty ? 'Unknown Album' : parentFolder,
    );
  }
}

class _TagFallback {
  const _TagFallback({
    required this.title,
    required this.artist,
    required this.album,
  });

  final String title;
  final String artist;
  final String album;
}
