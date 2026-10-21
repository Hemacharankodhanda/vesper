# Vesper docs: start here

Offline music player for Windows and Android. UI-first, minimal.

| File | Purpose | Give to the agent |
|---|---|---|
| 01-PRD.md | What and why, scope, requirements | once, at kickoff |
| 02-DESIGN-SYSTEM.md | Tokens, components, screens, anti-slop rules | UI phases |
| 03-ARCHITECTURE.md | Stack, folders, data model, audio contract, platform notes | code phases |
| 04-ROADMAP.md | Phases P0-P9 with "done when" | one phase at a time |
| 05-AGENT-PROMPT.md | CLAUDE.md rules, kickoff prompt, phase prompts | copy-paste |

## Setup (10 minutes)
1. `flutter create vesper --platforms=android,windows` and `cd vesper`
2. Copy this folder to `vesper/docs/`
3. Copy the "Project rules" block from 05-AGENT-PROMPT.md into `vesper/CLAUDE.md`
4. Put the prototype `main.dart` at `vesper/prototype/main.dart`
5. Open your agent in the repo, paste the Kickoff prompt, then say "Start P0"
6. After each phase: review, commit, start a fresh session, paste the next Phase prompt
