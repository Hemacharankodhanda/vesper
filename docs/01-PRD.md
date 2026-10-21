# Vesper: Product Requirements (PRD)


## 1. Vision
An offline music player for **Windows and Android** whose main attraction is a beautiful, minimal, interactive UI. It plays the user's own audio files with no internet, no account, no ads. Design quality is the product.

## 2. Principles (apply to every decision)
1. **Art first.** Album art and typography are the hero. Chrome stays quiet.
2. **Four destinations only:** Home, Library, Search, Now Playing. Settings sits behind one icon.
3. **One primary action per screen.** If it needs a tooltip or explanation, cut or redesign it.
4. **Motion has a job** (continuity, feedback). No decorative animation.
5. **No clutter / no slop:** no ads, accounts, social, recommendations, banners, badges, upsells, or empty filler sections.
6. **Offline always.** Zero network calls. Fonts and assets are bundled.

## 3. Users
Students and music lovers with local libraries (MP3, FLAC, M4A, OGG, WAV, OPUS) who want a calm, good-looking player on phone and laptop.

## 4. Scope
**MVP:** folder selection and scan; tag and cover reading; play, pause, seek, next, previous, shuffle, repeat; background playback + media controls on both platforms; Songs, Albums, Artists browsing; queue (reorder, play next); Now Playing with adaptive colour; resume exactly where you left off.

**v1:** playlists, likes, recently played, instant local search, `.lrc` synced lyrics, sleep timer, gapless + crossfade, mini player hero transition, light theme, accent customization.

**v2:** equalizer, ReplayGain, tag editor, listening stats, LAN sharing, M3U import/export, Windows mini mode and tray.

**Non-goals:** cloud sync, accounts, social, podcasts, radio, online streaming, downloaders for third-party services, recommendation engine, ads.

## 5. Functional requirements
- FR-1 User picks one or more library folders; app scans recursively in the background and shows progress without blocking the UI.
- FR-2 Rescan is incremental (changed or new files only, by mtime and size). Removed files disappear from the library.
- FR-3 Metadata (title, artist, album, album artist, track/disc no, year, genre, duration, embedded cover) is read from tags, with filename/folder fallback.
- FR-4 Playback continues with the screen off or app backgrounded. Notification (Android) and SMTC/media keys (Windows) show metadata and controls.
- FR-5 Queue is editable (reorder, remove, play next, add to end) and persisted across restarts, including position.
- FR-6 Library views: Songs (A–Z with scrubber), Albums (grid), Artists, Playlists.
- FR-7 Search is local, instant (<100 ms for 10k tracks), grouped by Songs/Albums/Artists, tolerant of case and diacritics.
- FR-8 Now Playing: swipe art to skip, drag seek bar, like, shuffle, repeat, queue sheet, lyrics sheet.
- FR-9 Adaptive colour: screen palette is derived from current cover and cross-fades on track change.
- FR-10 Windows: Space, arrows, and media keys work. Layout adapts at width >= 800 px.
- FR-11 Handles missing tags, missing covers (generated placeholder art), unsupported or corrupt files (skip and log, never crash).

## 6. Non-functional requirements
- 60 fps on mid-range Android and integrated-GPU Windows. No jank during scan.
- Cold start to interactive <= 2 s with 10k tracks.
- Library of 20k tracks scrolls smoothly (lazy lists, thumbnail cache, paginated queries).
- Memory: never decode full-size cover inside a list; use 300 px thumbs.
- Accessibility: touch targets >= 48 dp, contrast AA on text, semantic labels on icon buttons, respects "reduce motion".
- Privacy: no analytics, no network permission on Android (no INTERNET in release manifest).

## 7. Success criteria
- Now Playing screen is "screenshot-worthy" on both platforms.
- A user can go from install to playing a song in under 60 seconds.
- Zero crashes across a 10k-track mixed-format test library.

## 8. Legal
Plays user-owned files only. No DRM bypass, no downloaders for third-party services.
