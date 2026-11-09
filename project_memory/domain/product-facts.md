# Product Facts

> Maintained page for product behaviour, limits, defaults and decisions.

## What It Does

TTS Buddy 0.1.0 is a personal-use Windows MVP for Tabletop Simulator. Its Signal Run implementation connects to a local table, presents seat-specific legal moves, plays Buddy turns and records public turn history. The private ZIP includes the Windows launcher, prebuilt save and first-run guide. Five consecutive final-save model matches used scripted White-seat moves, and a complete live match verified the exact runtime in the ZIP. A personal playthrough, independent feedback and external pilot acceptance remain open.

## Planned MVP Limits

One human and one AI opponent, one supported two-player game save and one local Windows TTS session. The selected original game is Signal Run. Live tests used a locally imported Qwen3 4B model on the development PC and the official Ollama tag on CPU in the Windows test VM. The VM runs Tabletop Simulator with software rendering. The [validation record](../../docs/validation.md) tracks the guest results and remaining pilot checks.

The Windows launcher defaults to `qwen3:4b-instruct-2507-q4_K_M` on the local Ollama server. It waits for a successful model preload before taking turns. The launcher honours the model and server environment settings. Baseline mode uses the deterministic player and skips Ollama.

## Decisions

- 2026-11-09 · The feasibility plan calls for testing subscription-based desktop control where available and using a direct scripting bridge for structured interaction. The first test uses the existing TTS session.
- 2026-11-09 · TTS 14.2.2 silently dropped external-editor callbacks containing nested Lua tables in a live test. Signal Run encodes its inspection snapshot as a JSON string in the callback and the Node bridge decodes it.
- 2026-11-09 · Long-term targets include voice interaction, persistent campaign memory, several AI players and game-specific adapters. The [MVP plan and roadmap](../roadmap/improvement-plan.md) records proposed sequencing, pilot targets and open implementation decisions.
- 2026-11-09 · Continue personal, non-commercial development and Singleplayer testing while external sharing is deferred. Record personal play separately from independent pilot feedback.
