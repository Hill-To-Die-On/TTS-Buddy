# Signal Run — personal Windows MVP quick start

This is a local prototype for Windows and Tabletop Simulator. The bridge, packaged save and complete matches have been tested locally; remaining pilot checks are listed in the validation record. The table uses a scripted on-screen hand; built-in tabletop markers display the deck count and the last played card. Individual cards are not physical objects. The human must sit at White. Treat the Windows host and table script as trusted; this is not an anti-cheat boundary against the host.

If you have the personal-use MVP ZIP, start with its `START HERE.txt` and use the prebuilt save. The build instructions below are for a source checkout.

## Prerequisites

- Node.js 24 and the installed Tabletop Simulator game.
- For the model opponent, install [Ollama for Windows](https://ollama.com/download/windows), start its local server, and install a model as described below. No API key is needed.
- Close other TTS external editors and Buddy instances: only one program can listen on port 39998.

## Install the demo table

1. Run `npm run build` in this folder. `tts/Signal Run.json` is generated from the included sanitized empty table and Global script.
2. Copy that JSON to TTS's `Saves` directory as an unused `TS_Save_<number>.json` file; do not overwrite an existing save. On this machine the directory is `X:\OneDrive\Documents\My Games\Tabletop Simulator\Saves`. Open TTS Singleplayer and find the slot number you chose under Save & Load. On first import its tile may appear as `?` without a thumbnail; load that slot and TTS should open **Signal Run**. Seat yourself at White.
## Play a local match

1. Open Signal Run in **Singleplayer** and sit at **White**.
2. Start Ollama. The first time, install the model with `ollama pull qwen3:4b-instruct-2507-q4_K_M` in PowerShell.
3. Open [start-buddy.cmd](../start-buddy.cmd) from File Explorer, or run `./start-buddy.cmd` in PowerShell from the project folder. A moving bar shows that the model is loading. Wait for **Buddy started**. The model can take up to two minutes to load. [Ollama's model preload documentation](https://docs.ollama.com/faq#how-can-i-preload-a-model-into-ollama-to-get-faster-response-times)
4. Click **New match**, then play a card from the White hand. The table displays the scores, deck count and last public card. See [the Signal Run rules](signal-run.md).

## Alternate model or baseline

For the deterministic opponent, open PowerShell in this folder and run:

```powershell
./start-buddy.cmd --baseline
```

The launcher uses Ollama at `http://127.0.0.1:11434` by default. Set `TTS_BUDDY_MODEL` and `TTS_BUDDY_OLLAMA_URL` before launch to use a different installed model and server. For example, use these settings if you have started the separate development instance with its locally imported model:

```powershell
$env:TTS_BUDDY_MODEL = 'tts-buddy-qwen3-4b:latest'
$env:TTS_BUDDY_OLLAMA_URL = 'http://127.0.0.1:11436'
./start-buddy.cmd
```

Buddy stores public turn history in `tts-buddy-history.jsonl` in this folder. Commands in the Buddy window are `pause`, `resume` and `stop`. The in-table **Pause**, **Resume**, **Take over** and **Release Buddy** controls change table state. Takeover lets White see and play Buddy's cards. If Buddy pauses after an uncertain result, check the table and type `resume`. Buddy reads the state again before deciding. When you reload a saved match, use the table's **Resume** button.

## Checks and troubleshooting

The launcher keeps an interactive terminal open if startup fails. Read the error before pressing Enter to close it. Check that the ZIP was fully extracted, that Ollama is running and that `ollama list` shows the requested model. If port 39998 is busy, close the other editor or Buddy process and restart. If Buddy cannot connect, confirm that the Signal Run table is open in Singleplayer.

Run `npm ci` once to install the pinned development-only Lua test harness, then `npm test`. The application uses Node built-ins at runtime.

See [validation](validation.md) for completed checks and remaining pilot gates. Do not tag or distribute a pilot until those gates and the distribution review are complete.
