# Vesper: Design System

## 1. Look and feel
Dark-first, quiet, editorial. Big type, generous space, art-driven colour. Frosted glass only on the mini player and sheets.

## 2. Tokens
**Colour (dark)**
| Token | Value | Use |
|---|---|---|
| bg | #0E0F12 | app background (when no art gradient) |
| surface | #16181D | cards, rows |
| surfaceHigh | #1E2128 | sheets, pressed |
| textPrimary | #F5F5F7 | titles |
| textSecondary | white @ 64% | artist, metadata |
| textMuted | white @ 40% | hints, disabled |
| accentFallback | #E8C26A | when no art palette |
| danger | #FF6B6B | destructive only |

**Dynamic palette:** derive from the current cover with Flutter's built-in `ColorScheme.fromImageProvider` (no extra package). Use: `deep` (darkest) as base, `mid` for the gradient top, `light` as accent. Gradient = lerp(mid, deep, .35) to deep, vertical. Cross-fade 700 ms easeOut. Force minimum contrast so white text stays AA.

**Light theme (v1):** bg #F6F5F2, surface #FFFFFF, text #14151A. Same dynamic-accent logic with lightened palette.

**Spacing:** 4-pt scale: 4, 8, 12, 16, 24, 32, 48. Screen side padding 28 (mobile), 32 (desktop).

**Radius:** 8 (small), 16 (cards, rows), 28 (hero art, sheets), full (play button).

**Typography (bundle fonts in assets; offline app must not fetch fonts)**
- Display font: Sora (or Outfit). Body: Inter.
| Style | Size / weight / tracking |
|---|---|
| display | 30-32 / 700 / -0.8, height 1.1 |
| title | 20 / 600 / -0.2 |
| body | 15 / 400 |
| caption | 12 / 500 / +0.2, tabular figures for time |
Two weights per screen max.

**Elevation:** shadows only under hero art (colour = palette.deep @ 55%, blur 40, y 20). Everything else flat.

**Motion**
| Token | Value |
|---|---|
| fast | 120 ms |
| base | 240 ms |
| slow | 450 ms |
| curves | easeOutCubic (default), easeOutBack (pops), spring for sheets/drag |
Respect `MediaQuery.disableAnimations` by shortening to 0-80 ms.

## 3. Components
- **ArtTile(track, radius, shadow):** cover with fallback generated art (deterministic from track id: rings, bars, grid, waves in palette). Always cached thumbnail; never decode full-size in lists.
- **SeekBar:** 4 px line; thickens to 10 px while dragging; tap-to-jump; elapsed left, remaining right (tabular figures); no thumb.
- **PlayButton:** 76 px white circle, icon colour = palette.deep, icon cross-scales on state change.
- **IconBtn:** 26 px, white at 100% active / 38% inactive. Tooltip + semantics label required.
- **MiniPlayer:** floating pill above nav (mobile) / persistent bar (desktop). 64 px, blur glass, art + title + play. Tap or swipe up expands to Now Playing via shared-element (Hero) transition.
- **TrackRow:** 56 px thumb, title, artist, duration. Current track: title in accent, semibold.
- **AlbumCard:** square art, title, artist. No borders.
- **QueueSheet / LyricsSheet:** draggable bottom sheet, blur, drag handle, 28 radius top.
- **Navigation:** Android bottom bar with 4 icons (labels only on selected). Windows left rail 72 px, icons plus tooltips.
- **EmptyState:** one line + one action. No illustrations.
- **Skeleton:** shimmer rows during scan, never spinners.

## 4. Screens
1. **Home:** "Continue listening" (one large card), Recently added (horizontal albums), Recently played (max 6 rows). Nothing else.
2. **Library:** segmented control Songs | Albums | Artists | Playlists. Alphabet scrubber on Songs.
3. **Search:** single field autofocused; grouped results; recent searches (max 5).
4. **Now Playing:** top bar (album name left, queue icon right), swipeable art with peeking neighbours, title/artist/like, seek, controls. Desktop: art left (flex 6), controls right (flex 5, max 440).
5. **Settings:** folders, theme, accent mode, equalizer (v2), about. Short list.

## 5. Breakpoints
< 700 phone, 700-1100 tablet/small window (rail + single pane), > 1100 desktop (rail + content + optional right queue panel).

## 6. Interaction rules
- Swipe art left/right = skip. Swipe down on Now Playing = collapse. Long-press track = menu (play next, add to playlist, like).
- Haptics (Android): skip, like, queue add, seek end.
- Keyboard (Windows): Space play/pause, Left/Right prev/next, Up/Down volume, M mute, L like, Q queue, / focus search.

## 7. Anti-slop checklist (reject a PR if any is true)
- More than one accent colour on screen.
- Gradients that are not derived from the album art.
- Icons without consistent stroke weight, or mixed icon sets.
- Text smaller than 12 px, or more than 2 text colours per row.
- A spinner where a skeleton works; an animation > 450 ms (except palette cross-fade).
- Any section that exists only to fill space.
