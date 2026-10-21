# Vesper: Roadmap and Task Plan

Work **one phase at a time**. Each phase ends with: `flutter analyze` clean, tests pass, app runs on Android and Windows, short commit message. Do not start the next phase until the current one's "Done when" is true.

## P0: Project setup
- `flutter create vesper --platforms=android,windows`; add dependencies from 03-ARCHITECTURE; `flutter_lints`.
- Folder structure, `core/theme/tokens.dart` from 02-DESIGN-SYSTEM, bundle Sora and Inter fonts.
- GitHub repo, CI that runs analyze and test.
- **Done when:** blank themed app runs on both platforms; CI green.

## P1: Shell and Now Playing (fake data)
- Split the prototype `main.dart` into `shared/widgets` (ArtTile, SeekBar, PlayButton) and `features/now_playing`.
- Implement `AudioPlayerService` interface plus `FakeAudioService`; wire via Riverpod.
- Adaptive nav shell: bottom bar (phone) / rail (desktop); routes for Home, Library, Search, Now Playing.
- **Done when:** Now Playing matches design spec on phone and desktop widths; golden tests added.

## P2: Real playback
- `JustAudioService` implementing the interface; Windows via media_kit init in `main()`.
- `audio_service` background handler, Android notification, audio focus, headset buttons.
- Test with 3 hardcoded local files per platform.
- **Done when:** gapless-ish playback, seek, next/prev work; plays with screen off on Android; media keys work on Windows.

## P3: Library scan and database
- Drift schema and DAOs; permission flow (Android) and folder picker (both).
- Scanner isolate with progress stream, incremental rescan, cover extraction and thumbnail cache.
- **Done when:** 10k-track test folder scans without UI jank; rescan only touches changed files; corrupt files skipped.

## P4: Library, Home, Search
- Songs (alphabet scrubber), Albums grid, Artists, Album detail, Artist detail.
- Home sections per design; instant local search with grouped results.
- **Done when:** all screens render real data smoothly at 20k tracks; empty and scanning states use skeletons.

## P5: Mini player, queue, persistence
- MiniPlayer with Hero transition to Now Playing; QueueSheet (reorder, remove, play next, add to end).
- Persist queue, position, shuffle, repeat; restore on launch.
- **Done when:** kill app mid-song, reopen, it resumes at the same position (paused).

## P6: Playlists, likes, history
- Create, rename, delete playlists; add via long-press menu; like button; recently played; play counts.
- **Done when:** all persisted; Home reflects history.

## P7: Platform polish
- Windows: SMTC, keyboard shortcuts, min window size, tray and optional mini mode, Mica/acrylic.
- Android: notification artwork and actions, edge-to-edge, predictive back, haptics.
- **Done when:** manual checklist in 03-ARCHITECTURE section 9 passes.

## P8: v1 features
- `.lrc` synced lyrics sheet; sleep timer; crossfade and gapless; light theme; accent mode (art vs fixed).
- **Done when:** each feature toggles in Settings and persists.

## P9: Performance, QA, release
- Profile with 20k tracks (DevTools); fix jank, memory.
- Accessibility pass (labels, contrast, reduce motion).
- Build signed APK/AAB and Windows installer; GitHub Release; README with screenshots and a demo video.
- **Done when:** success criteria in 01-PRD section 7 are met.

## Backlog (v2)
Equalizer, ReplayGain, tag editor, listening stats, LAN sharing, M3U import/export.
