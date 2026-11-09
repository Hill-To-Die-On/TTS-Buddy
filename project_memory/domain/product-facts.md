# Product Facts

> Maintained page for product behaviour, limits, defaults and decisions.

## What It Does

TTS Buddy is a local AI co-player prototype for Tabletop Simulator. Its Signal Run implementation connects to a local table, presents seat-specific legal moves, plays Buddy turns and records public turn history. A disposable live bridge spike, deterministic match and model-driven matches passed on the local Windows table. Five consecutive final-save matches used scripted human-seat moves; independent player feedback and pilot acceptance remain open.

## Planned MVP Limits

One human and one AI opponent, one supported two-player game save and one local Windows TTS session. The selected original game is Signal Run. The locally imported Qwen3 4B model was exercised on the target PC; the official Ollama tag is documented for fresh setups but has not itself been benchmarked here.

## Decisions

- 2026-11-09 · The feasibility plan calls for testing subscription-based desktop control where available and using a direct scripting bridge for structured interaction. The first test uses the existing TTS session.
- 2026-11-09 · TTS 14.2.2 silently dropped external-editor callbacks containing nested Lua tables in a live test. Signal Run encodes its inspection snapshot as a JSON string in the callback and the Node bridge decodes it.
- 2026-11-09 · Long-term targets include voice interaction, persistent campaign memory, several AI players and game-specific adapters. The [MVP plan and roadmap](../roadmap/improvement-plan.md) records proposed sequencing, pilot targets and open implementation decisions.
