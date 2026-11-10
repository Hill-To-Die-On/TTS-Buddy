# Changelog

All the notable changes to TTS Buddy end up here. The format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/). Everything before 1.0 is a personal-use prototype, so expect things to move about a little.

There aren't any Git tags yet, so each version links to the commit that set its version number.

## [Unreleased]

### Added

- GitHub docs: this changelog, a contributing guide, a security policy, and issue and pull request templates.
- A README for the repository.
- Notes from the first personal Signal Run playtest in [validation](docs/validation.md).
- A [plan for Flamme Rouge](docs/flamme-rouge.md) as the next head-to-head game.

## [0.1.2] - 2026-11-09

### Added

- Buddy finds a local model by itself when it starts. It tries `qwen3:4b-instruct-2507-q4_K_M` in Ollama first, then other suitable models in Ollama or LM Studio, and the active text model in Unsloth Studio.
- Every candidate model has to find the winning move on a sample Signal Run turn before it's allowed to play a match.
- If nothing passes and Ollama is running, Buddy can offer to download a suggested model. It only does that after you type an explicit yes in an interactive window.
- `TTS_BUDDY_LM_STUDIO_API_KEY` and `TTS_BUDDY_UNSLOTH_API_KEY` for local servers that need a key.

### Changed

- Buddy asks for a 2,048-token context for the Ollama models it picks and the LM Studio models it loads.
- Setting `TTS_BUDDY_MODEL` or `TTS_BUDDY_OLLAMA_URL` pins that setup and skips the automatic search.

## [0.1.1] - 2026-11-09

### Added

- A loading bar in the launcher window while the model warms up.

### Changed

- Startup errors stay on screen until you press Enter, rather than the window vanishing. With redirected output, the launcher keeps the error and exit code and doesn't wait.
- Plain messages when Node.js is missing or only `start-buddy.cmd` was pulled out of the ZIP.

## [0.1.0] - 2026-11-09

The first playable version.

### Added

- **Signal Run**, an original two-player card game, as a Tabletop Simulator save built from source with `npm run build`. It has an on-screen hand for White, score previews and physical markers for the deck count and last card played.
- A local bridge to Tabletop Simulator's External Editor API on 127.0.0.1. Every request carries an ID and a table revision, so a late reply or a reconnect can't play the same move twice.
- Fair seats. Buddy only gets the public state, its own hand and the legal moves, and the table's Lua rules check each move before applying it.
- A local model player through Ollama, plus a deterministic baseline opponent (`start-buddy.cmd --baseline`).
- **Pause**, **Resume**, **Take over** and **Release Buddy** on the table, with pause, resume and stop in the Buddy window.
- Public-only turn history in `tts-buddy-history.jsonl`.
- Node and Lua test suites. The Lua runs in Fengari during development.
- A reproducible table build. LF and CRLF checkouts produce the same save, which `.gitattributes` keeps that way.
- The launcher loads the model before Buddy's first look at the table.

[Unreleased]: https://github.com/Hill-To-Die-On/TTS-Buddy/compare/843fdb9...HEAD
[0.1.2]: https://github.com/Hill-To-Die-On/TTS-Buddy/commit/843fdb9
[0.1.1]: https://github.com/Hill-To-Die-On/TTS-Buddy/commit/80e8921
[0.1.0]: https://github.com/Hill-To-Die-On/TTS-Buddy/commit/c0f2eae
