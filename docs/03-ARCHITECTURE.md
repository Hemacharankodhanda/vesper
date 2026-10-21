# Vesper: Architecture

## 1. Stack
| Concern | Choice |
|---|---|
| Framework | Flutter (stable), Dart 3, targets: android, windows |
| State | flutter_riverpod |
| Audio | just_audio, audio_service, audio_session; Windows backend: just_audio_media_kit + media_kit_libs_windows_audio |
| DB | drift + sqlite3_flutter_libs (+ drift_dev, build_runner) |
| Tags and covers | audiotags (fallback: metadata_god) |
| Files and perms | file_picker, permission_handler, path_provider, path |
| Windows | window_manager, smtc_windows, flutter_acrylic (optional) |
| Navigation | go_router |
| Lints and tests | flutter_lints, flutter_test, mocktail |
Run `flutter pub add <pkg>` to get latest compatible versions. Do not add other dependencies without asking.

## 2. Folder structure
```
lib/
  main.dart
  app.dart                  MaterialApp, theme, router
  core/
    theme/                  tokens.dart, app_theme.dart, palette.dart
    utils/                  formatters, debouncer, isolates helpers
    platform/               platform checks, window/SMTC setup
  data/
    db/                     drift tables, database.dart, daos
    scanner/                folder walker, tag reader, art extractor (runs in isolate)
    repositories/           library_repo, playlist_repo, settings_repo
  domain/
    models/                 Track, Album, Artist, Playlist, QueueState
  audio/
    audio_player_service.dart   (abstract)
    just_audio_service.dart     (impl)
    fake_audio_service.dart     (for UI dev and tests)
    queue_manager.dart
  features/
    home/ library/ search/ now_playing/ queue/ playlists/ settings/
  shared/widgets/           ArtTile, SeekBar, PlayButton, MiniPlayer, GlassPanel...
assets/fonts/               Sora, Inter (bundled)
docs/                       these documents
test/
```
Rule: `features/*` may depend on `domain`, `audio` (interface only), `data/repositories`, `shared`. Never on drift tables or just_audio directly.

## 3. Audio service contract
```dart
abstract class AudioPlayerService {
  Stream<bool> get playing;
  Stream<Duration> get position;      // throttled to ~4 Hz for UI
  Stream<Duration?> get duration;
  Stream<Track?> get currentTrack;
  Stream<QueueState> get queue;       // list, index, shuffle, repeat
  Future<void> setQueue(List<Track> tracks, {int index = 0, bool play = true});
  Future<void> play(); Future<void> pause(); Future<void> toggle();
  Future<void> seek(Duration p);
  Future<void> next(); Future<void> previous(); Future<void> jumpTo(int index);
  Future<void> setShuffle(bool on); Future<void> setRepeat(RepeatMode m);
  Future<void> playNext(Track t); Future<void> addToEnd(Track t);
  Future<void> removeAt(int i); Future<void> move(int from, int to);
  Future<void> setSleepTimer(Duration? after);
  Future<void> dispose();
}
```
UI talks only to this interface through a Riverpod provider. `FakeAudioService` (timer-based) powers UI development and widget tests. The prototype `main.dart` `FakePlayer` maps directly onto this.

## 4. Data model (drift)
- **tracks:** id, path (unique), title, artistId, albumId, albumArtist, trackNo, discNo, year, genre, durationMs, bitrate, format, artHash, addedAt, mtime, sizeBytes, playCount, lastPlayedAt, liked
- **albums:** id, title, albumArtist, year, artHash (unique on title + albumArtist)
- **artists:** id, name
- **playlists:** id, name, createdAt
- **playlist_tracks:** playlistId, trackId, position
- **library_folders:** id, path
- **queue_state:** single row (trackIds JSON, index, positionMs, shuffle, repeat)
- **settings:** key, value
Indexes: tracks(title), tracks(artistId), tracks(albumId), tracks(addedAt), tracks(lastPlayedAt). Search: normalized lowercase and diacritic-stripped columns, or FTS5 in v1.

## 5. Library scanning pipeline
1. Walk folders in a background isolate; collect audio files (mp3, flac, m4a, aac, ogg, opus, wav, wma).
2. Compare (path, mtime, size) with DB; process only new or changed; delete rows for missing files.
3. Read tags with audiotags; fallback: parse "Artist - Title" from filename, album from folder.
4. Extract embedded cover, hash it (artHash), save two sizes (300 px, 800 px) as WebP/JPEG in app cache dir; dedupe by hash.
5. Batch inserts in transactions (500 rows); emit progress stream to UI.
6. Never throw on a bad file: log and continue.

## 6. Cover and palette pipeline
- Lists use 300 px thumb via `ResizeImage`/cached file. Now Playing uses 800 px.
- Palette computed once per artHash with `ColorScheme.fromImageProvider`, cached in memory and in DB/settings; computed off the first frame to avoid jank.

## 7. Platform specifics
**Android**
- Permissions: `READ_MEDIA_AUDIO` (API 33+), `READ_EXTERNAL_STORAGE` (<= API 32), `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `POST_NOTIFICATIONS`. No INTERNET in release.
- `audio_service` foreground service + media notification, headset buttons, audio focus (pause on call, duck on notification) via audio_session.
- If direct file paths are blocked by scoped storage on some devices, fall back to MediaStore-based enumeration.
**Windows**
- `just_audio_media_kit` initialized in `main()` before runApp.
- `smtc_windows` for system media overlay and keys; `window_manager` for min size (420x700), title, and optional mini mode.
- Installer: MSIX or Inno Setup.

## 8. State management conventions
- Providers: `audioServiceProvider`, `currentTrackProvider`, `positionProvider` (separate so only SeekBar rebuilds), `libraryProvider` (paged), `searchProvider(query)`, `paletteProvider(artHash)`, `settingsProvider`.
- Immutable models, `AsyncValue` for loading states, no business logic in widgets.

## 9. Testing
- Unit: scanner (tag parsing, fallbacks), repositories, queue manager, formatters.
- Widget: SeekBar, PlayButton, NowPlaying with FakeAudioService, QueueSheet.
- Golden tests for Now Playing (phone + desktop) in 2 palettes.
- Manual matrix: MP3/FLAC/M4A/OGG, no tags, huge cover, 10k tracks, screen off, headset disconnect, call interruption.

## 10. CI/CD (GitHub Actions, free)
On tag `v*`: `flutter analyze` + `flutter test`, build APK (and AAB), build Windows release, zip/installer, attach to GitHub Release.
