import 'package:drift/drift.dart';

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();
  TextColumn get title => text()();
  TextColumn get artistId => text().nullable()();
  TextColumn get albumId => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNo => integer().nullable()();
  IntColumn get discNo => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get durationMs => integer()();
  IntColumn get bitrate => integer().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get artHash => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get mtime => dateTime()();
  IntColumn get sizeBytes => integer()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get liked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Albums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get artHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Artists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlaylistTracks extends Table {
  TextColumn get playlistId => text()();
  TextColumn get trackId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

class LibraryFolders extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
