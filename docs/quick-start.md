# Signal Run — local prototype quick start

This is a local prototype for Windows and Tabletop Simulator. The bridge, packaged save and complete matches have been tested locally; remaining pilot checks are listed in the validation record. The table uses a scripted on-screen hand; built-in tabletop markers display the deck count and the last played card. Individual cards are not physical objects. The human must sit at White. Treat the Windows host and table script as trusted; this is not an anti-cheat boundary against the host.

## Prerequisites

- Node.js 24 and the installed Tabletop Simulator game.
- For the model opponent, install [Ollama for Windows](https://ollama.com/download/windows), start its local server, and install a model as described below. No API key is needed.
- Close other TTS external editors and Buddy instances: only one program can listen on port 39998.

## Install the demo table

1. Run `npm run build` in this folder. `tts/Signal Run.json` is generated from the included sanitized empty table and Global script.
2. Copy that JSON to TTS's `Saves` directory as an unused `TS_Save_<number>.json` file; do not overwrite an existing save. On this machine the directory is `X:\OneDrive\Documents\My Games\Tabletop Simulator\Saves`. Open TTS Singleplayer and find the slot number you chose under Save & Load. On first import its tile may appear as `?` without a thumbnail; load that slot and TTS should open **Signal Run**. Seat yourself at White.
3. Click **New match** in the table UI. The rules are in [Signal Run](signal-run.md). Play a card by clicking it when Human is active. The table displays scores, deck count, status and the most recent public card.

## Play on this PC

The verified Signal Run table is installed in save slot **24**. With it open, run these commands in PowerShell from the MVP folder to use the local test model. Then play a card from the White seat.

```powershell
$env:TTS_BUDDY_MODEL = 'tts-buddy-qwen3-4b:latest'
$env:TTS_BUDDY_OLLAMA_URL = 'http://127.0.0.1:11436'
node src/index.js
```

## Start Buddy

In PowerShell opened in this folder, the diagnostic baseline runs with:

```powershell
node src/index.js --baseline
```

For a fresh machine, with Ollama running on its default local address, download the official Qwen model and start Buddy:

```powershell
ollama pull qwen3:4b-instruct-2507-q4_K_M
$env:TTS_BUDDY_MODEL = 'qwen3:4b-instruct-2507-q4_K_M'
$env:TTS_BUDDY_OLLAMA_URL = 'http://127.0.0.1:11434'
node src/index.js
```

The official tag has not itself been benchmarked here. On the development PC, testing used the same Qwen variant imported locally as `tts-buddy-qwen3-4b:latest` on an isolated CPU-only server at `http://127.0.0.1:11436`. That server and imported tag are temporary test configuration, not a prerequisite on a fresh machine. To use that already-running instance, set `TTS_BUDDY_MODEL` and `TTS_BUDDY_OLLAMA_URL` to those values instead.
The normal default address is `http://127.0.0.1:11434`. Buddy stores a minimal public turn history in `tts-buddy-history.jsonl` in this folder; it excludes both hands and model prompts. Commands in the Buddy window are `pause`, `resume` and `stop`. The in-table **Pause**, **Resume**, **Take over**, and **Release Buddy** controls change table state. Takeover lets White play Buddy's cards; it exposes that hand to the host. A paused or uncertain Buddy requires you to check the table and type `resume` in the window; it reads the state again before deciding. Restarting Buddy while the same game remains open also begins with an inspection. A saved-and-reloaded table starts paused; use the table's Resume button.

## Checks and troubleshooting

Run `npm ci` once to install the pinned development-only Lua test harness, then `npm test`. The application itself uses only Node built-ins. If port 39998 is busy, close the other editor or Buddy process and restart. If Buddy cannot connect, confirm a TTS Singleplayer table with the Signal Run script is open. If the model is unavailable or times out, inspect the table and use the baseline to isolate the problem; do not assume a timed-out move failed. The app pauses on an unknown action result and does not automatically replay it.

See [validation](validation.md) for completed checks and remaining pilot gates. Do not tag or distribute a pilot until those gates and the distribution review are complete.
