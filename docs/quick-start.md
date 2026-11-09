# Signal Run — personal Windows MVP quick start

This is a local prototype for Windows and Tabletop Simulator. The bridge, packaged save and complete matches have been tested locally. The [validation record](validation.md) tracks the remaining pilot checks. Signal Run uses a scripted on-screen hand and physical tabletop markers for the deck count and last played card. The human sits at White. Treat the Windows host and table script as trusted.

If you have the personal-use MVP ZIP, start with its `START HERE.txt` and use the prebuilt save. The build instructions below are for a source checkout.

## Prerequisites

- Node.js 24 and Tabletop Simulator for Windows.
- For a model opponent, run at least one local server from the table below.
- Close other TTS external editors and Buddy instances. One program can listen on port 39998 at a time.

| Provider | Setup |
| --- | --- |
| Ollama | Start [Ollama for Windows](https://ollama.com/download/windows) on port 11434. Buddy tries its preferred Qwen3 4B tag first if it is installed. |
| LM Studio | Start the [local server](https://lmstudio.ai/docs/developer/core/server) from the Developer tab on port 1234. Buddy can load a suitable model from the installed library. For a server that requires a token, set `TTS_BUDDY_LM_STUDIO_API_KEY` in the PowerShell session used to launch Buddy. |
| Unsloth Studio | Start the local API on port 8888 and load a text model in Studio. For a server that requires a key, set `TTS_BUDDY_UNSLOTH_API_KEY` in the PowerShell session used to launch Buddy. [Unsloth local API](https://unsloth.ai/) |

## Install the demo table

1. Run `npm run build` in this folder. `tts/Signal Run.json` is generated from the included sanitized empty table and Global script.
2. Copy that JSON into `Documents\My Games\Tabletop Simulator\Saves` as an unused `TS_Save_<number>.json` file. Pick an unused number so your existing saves are safe.
3. Open TTS Singleplayer and find the slot under Save & Load. Its tile may initially show a question mark. Load the slot and sit at White.

## Play a local match

1. Open Signal Run in Singleplayer and sit at White.
2. Start your local model server. Double-click `start-buddy.cmd` or run it from PowerShell. The window shows which provider and model it is testing. Wait for **Buddy started**.
3. If the check fails, Buddy tries another suitable local candidate. With Ollama running, Buddy can offer to download a suggested model when no candidate works. Enter y to approve the listed download. Enter alone declines it. The launcher checks the model before starting a match.
4. Click **New match**, then play a card from the White hand. See [the Signal Run rules](signal-run.md).

## Pin an Ollama model or use the baseline

Set `TTS_BUDDY_MODEL` to pin a specific Ollama model. Set `TTS_BUDDY_OLLAMA_URL` to choose the server, which defaults to `http://127.0.0.1:11434`. Either setting takes precedence over automatic discovery. For example, to use a model imported into a separate development instance, run the following in PowerShell.

```powershell
$env:TTS_BUDDY_MODEL = 'tts-buddy-qwen3-4b:latest'
$env:TTS_BUDDY_OLLAMA_URL = 'http://127.0.0.1:11436'
.\start-buddy.cmd
```

To resume automatic selection in that PowerShell session, clear both settings.

```powershell
Remove-Item Env:TTS_BUDDY_MODEL, Env:TTS_BUDDY_OLLAMA_URL -ErrorAction SilentlyContinue
.\start-buddy.cmd
```

For a deterministic opponent, run the following from the extracted folder.

```powershell
.\start-buddy.cmd --baseline
```

Buddy stores public turn history in `tts-buddy-history.jsonl`. Commands in the Buddy window are pause, resume and stop. The table has **Pause**, **Resume**, **Take over** and **Release Buddy** controls. Takeover lets White see and play Buddy's cards. If Buddy pauses after an uncertain result, check the table and type resume. Buddy reads the state again before deciding. After reloading a saved match, use the table's **Resume** button.

## Checks and troubleshooting

The launcher keeps an interactive window open after a startup error. Read the message before pressing Enter to close it. Check that the entire ZIP is extracted and the server you want is running. If port 39998 is busy, close the other external editor or Buddy instance and restart. If Buddy cannot connect to the table, confirm Signal Run is open in Singleplayer.

Run `npm ci` once to install the pinned development-only Lua test harness, then `npm test`. The application uses Node built-ins at runtime.
