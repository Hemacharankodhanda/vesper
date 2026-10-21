# Vesper: AI Agent Prompts

Use with Claude Code, Antigravity, Cursor, or any coding agent. Put the docs in `/docs`, put the **Project rules** below in `CLAUDE.md` (or `AGENTS.md`) at the repo root, then paste the **Kickoff prompt** once and a **Phase prompt** per phase.

---

## A. Project rules (save as CLAUDE.md / AGENTS.md)

```
# Vesper: project rules
Offline music player (Flutter, Android + Windows). UI quality is the product.

Source of truth (read only what the current phase needs):
- docs/01-PRD.md, docs/02-DESIGN-SYSTEM.md, docs/03-ARCHITECTURE.md, docs/04-ROADMAP.md

Rules
1. Work on ONE roadmap phase at a time. Do not start the next phase unprompted.
2. Before coding, state a 5-line plan. After coding, summarize files changed and how to verify.
3. Follow the folder structure and layering in 03-ARCHITECTURE. UI depends on AudioPlayerService, never on just_audio or drift directly.
4. Use design tokens only (core/theme/tokens.dart). No hardcoded colours, sizes, or durations in widgets.
5. No new dependencies without asking. Offline only: no network calls, bundle fonts and assets.
6. Minimal UI: reject clutter. Follow the anti-slop checklist in 02-DESIGN-SYSTEM section 7.
7. Keep widgets small; no business logic in widgets; position stream isolated so only SeekBar rebuilds.
8. Run `flutter analyze` and `flutter test` before saying done. Add tests for new logic and golden tests for new screens.
9. Never crash on bad files, missing tags, or missing covers.
10. Small, focused commits: "feat(phase): message".
11. If requirements are ambiguous, ask ONE concise question, then proceed with the best default.
12. Context hygiene: do not paste whole files back; reference paths and line ranges; keep answers short.
```

---

## B. Kickoff prompt (paste once)

```
You are the lead Flutter engineer for "Vesper", an offline music player for Windows and Android where a beautiful, minimal, interactive UI is the main attraction.

First read: docs/01-PRD.md, docs/02-DESIGN-SYSTEM.md, docs/03-ARCHITECTURE.md, docs/04-ROADMAP.md and CLAUDE.md.

Then:
1. Reply with a short summary (max 12 lines) of what we're building, the stack, and the design rules, so I can confirm you understood.
2. List any questions that would block Phase 0 (max 3). If none, say so.
3. Do not write code yet. Wait for my "Start P0".
```

---

## C. Phase prompt template (paste per phase)

```
Start <PHASE ID>: <PHASE NAME> from docs/04-ROADMAP.md.

Read only the sections relevant to this phase (name them). Then:
1. Give a 5-line plan.
2. Implement it, following CLAUDE.md rules and the design tokens.
3. Run flutter analyze and flutter test; fix issues.
4. Show: files changed (paths only), how I verify it on Android and Windows, and any open risks.
5. Stop. Do not begin the next phase.
```

---

## D. Ready prompt for Phase 1 (Now Playing)

```
Start P1: Shell and Now Playing (fake data).

Context: docs/02-DESIGN-SYSTEM.md (tokens, components, Now Playing spec) and docs/03-ARCHITECTURE.md sections 2-3 and 8. I have a working single-file prototype at prototype/main.dart (FakePlayer, ArtTile, SeekBar, PlayButton, QueueSheet). Use it as the visual and behavioural reference.

Do:
1. Split the prototype into the structure in 03-ARCHITECTURE: shared/widgets (ArtTile, SeekBar, PlayButton, IconBtn, GlassPanel), features/now_playing, features/queue.
2. Create AudioPlayerService (abstract) and FakeAudioService; expose via Riverpod; split position into its own provider so only SeekBar rebuilds each tick.
3. Move all colours, spacing, radii, durations into core/theme/tokens.dart; use bundled fonts Sora and Inter.
4. Build the adaptive shell: bottom nav (<700 px) / left rail (>=700 px) with Home, Library, Search placeholders (one-line empty states) and Now Playing.
5. Palette: derive from the cover via ColorScheme.fromImageProvider when a real image exists; for generated art use the track's declared palette. Cross-fade 700 ms.
6. Keyboard shortcuts on Windows (Space, Left, Right).
7. Add widget tests for SeekBar and PlayButton, and golden tests for Now Playing at 390x844 and 1280x800.

Acceptance: matches the design spec on both widths, no jank, analyze and tests clean. Stop after P1.
```

---

## E. Other useful prompts

**Review a screen against the design system**
```
Review <path> against docs/02-DESIGN-SYSTEM.md, especially section 7 (anti-slop). List violations as file:line + fix. Do not rewrite unrelated code.
```

**Debug**
```
<error / behaviour>. Platform: <Android|Windows>. Find the root cause first (explain in 3 lines), then apply the smallest fix and add a regression test.
```

**Performance pass**
```
Profile the Library screen with 20k tracks. Identify the top 3 jank sources (rebuilds, image decode, queries) with evidence, fix them, and report before/after frame times.
```

---

## F. How to avoid running out of tokens/context
- Give the agent **one phase at a time** and only the doc sections it needs (the docs are split for this).
- Keep `CLAUDE.md` short (it is read every session); it already tells the agent to reference paths instead of pasting files.
- Start a **fresh session per phase**; the roadmap and docs carry the memory, not the chat.
- Use `/compact` (Claude Code) or a new chat when a session gets long; paste only the phase prompt again.
- Ask for diffs or file lists instead of full-file dumps, and for summaries of test output instead of full logs.
- Commit after every phase so a new session can start from git history.
