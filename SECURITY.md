# Security policy

TTS Buddy runs entirely on your own Windows PC, but it does open a local connection to Tabletop Simulator and passes table state to an AI model. If you find a way to break that, I'd like to know.

## Supported versions

TTS Buddy is a pre-1.0 prototype, so only the latest code on `main` gets fixes.

| Version | Supported |
| --- | --- |
| 0.1.x (latest `main`) | Yes |
| Anything older | No |

## What counts as a security problem

- Buddy listening on, or accepting connections from, anything other than this PC.
- A way to run arbitrary Lua, or change table objects in general, through the AI-facing side or the bridge.
- Hidden information (the human's hand, unrevealed deck order or private choices) reaching the model, the turn history, error messages or logs.
- A move being applied twice, applied out of turn or applied without the table's rules checking it.
- API keys (such as `TTS_BUDDY_LM_STUDIO_API_KEY`) showing up in output, history or logs.
- A model download happening without an explicit yes.

Wrong moves, crashes and slow turns are ordinary bugs. Please use the normal bug report for those.

## How Buddy is meant to work

For this prototype, the Windows PC and the table's script are treated as trusted. Buddy's bridge listens on `127.0.0.1:39998` and talks to Tabletop Simulator on `127.0.0.1:39999`. Local model servers are reached on localhost too (Ollama `11434`, LM Studio `1234`, Unsloth Studio `8888` by default), unless you point `TTS_BUDDY_OLLAMA_URL` somewhere else yourself. Buddy doesn't contact the internet itself. The one exception is the optional model download, which runs `ollama pull` after you've said yes. The packaged build is only for local Singleplayer sessions.

## Reporting a problem

Please don't put the details in a public issue. Instead, open an issue titled **Security contact request** with no details at all, and I'll get back to you with a private way to send them.

Tell me what you found, the steps to reproduce it and which version or commit you were on. I'm a one-person studio, so I can't promise a set response time, but I'll get back to you as soon as I can and keep you posted while it's fixed. If you'd like a credit when the fix goes out, say so.
