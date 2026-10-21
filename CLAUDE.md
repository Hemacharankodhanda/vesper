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
