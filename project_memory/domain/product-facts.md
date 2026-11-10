# Product Facts

> Maintained page for product behaviour, limits, defaults and decisions.

## What It Does

TTS Buddy 0.1.2 is a personal-use Windows MVP for Tabletop Simulator. Its Signal Run implementation connects to a local table, presents seat-specific legal moves, plays Buddy turns and records public turn history. The private ZIP includes the Windows launcher, prebuilt save and first-run guide. The 0.1.0 live evidence covers five consecutive model matches using scripted White-seat moves. Version 0.1.2 adds automatic local model selection and an optional download. The personal playtest confirmed the visible controls and reported responsive Buddy turns after loading a fresh save. A complete personal match result, independent feedback and external pilot acceptance remain open.

## Planned MVP Limits

One human and one AI opponent, one supported two-player game save and one local Windows TTS session. The selected original game is Signal Run. Live tests used a locally imported Qwen3 4B model on the development PC and the official Ollama tag on CPU in the Windows test VM. The VM runs Tabletop Simulator with software rendering. The [validation record](../../docs/validation.md) tracks the guest results and remaining pilot checks.

The Windows launcher checks running local model servers. It tries `qwen3:4b-instruct-2507-q4_K_M` in Ollama first if installed, then considers suitable local models from Ollama and LM Studio and an active text model from Unsloth Studio. Each candidate must make the winning move on a sample Signal Run turn before it can play a match. Buddy requests a 2,048-token context for automatically selected Ollama models and for LM Studio models it loads. If the local Ollama server is available and no candidate succeeds, Buddy can offer to download a suggested missing model. It requires an explicit yes in an interactive console. The launcher shows progress during checks and keeps startup errors visible. An explicit Ollama model or server setting pins that configuration. Baseline mode uses the deterministic player and skips model setup.

## Decisions

- 2026-11-10 · Choose Flamme Rouge as the next head-to-head adapter. Start with one base-game race on Avenue Corso Paseo in local Singleplayer. [Scope and acceptance](../../docs/flamme-rouge.md)

- 2026-11-09 · The feasibility plan calls for testing subscription-based desktop control where available and using a direct scripting bridge for structured interaction. The first test uses the existing TTS session.
- 2026-11-09 · TTS 14.2.2 silently dropped external-editor callbacks containing nested Lua tables in a live test. Signal Run encodes its inspection snapshot as a JSON string in the callback and the Node bridge decodes it.
- 2026-11-09 · Long-term targets include voice interaction, persistent campaign memory, several AI players and game-specific adapters. The [MVP plan and roadmap](../roadmap/improvement-plan.md) records proposed sequencing, pilot targets and open implementation decisions.
- 2026-11-09 · Continue personal, non-commercial development and Singleplayer testing while external sharing is deferred. Record personal play separately from independent pilot feedback.
