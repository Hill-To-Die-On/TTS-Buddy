# Contributing to TTS Buddy

TTS Buddy is a small, one-person project, so any help is welcome. That includes bug reports, playtest notes, rules questions and code. It's an early prototype though, so for anything bigger than a small fix, please open an issue first and we can talk it through before you spend an evening on it.

## Reporting bugs and ideas

- **Bugs:** use the bug report template on the [Issues](https://github.com/Hill-To-Die-On/TTS-Buddy/issues) tab. Include the launcher window output and say which model you were using, since a lot of Buddy's behaviour depends on it.
- **Ideas and game requests:** use the feature request template. If it's a new game, say which one and what makes it interesting for an AI player (hidden hands, simultaneous choices, line of sight, etc).
- **Security problems:** please don't open a public issue. See [SECURITY.md](SECURITY.md).

## Getting set up

You'll need Windows, [Node.js](https://nodejs.org/) 24 or newer and Git. To try changes at a real table you'll also want Tabletop Simulator and a local model server. The [quick start](docs/quick-start.md) covers Ollama, LM Studio and Unsloth Studio.

```powershell
git clone https://github.com/Hill-To-Die-On/TTS-Buddy.git
cd TTS-Buddy
npm ci
npm test
```

`npm ci` installs the one development dependency, a pinned Lua runner for the tests. At runtime Buddy only uses Node's built-in modules. `npm test` runs the Node tests and then the Lua rules and table tests. `npm run build` regenerates `tts/Signal Run.json` from the Lua sources in `tts/`.

## How the code is laid out

| Folder | What's in it |
| --- | --- |
| `src/` | The Node companion: the TTS bridge, the session and recovery logic, the players and local model discovery. `index.js` is the entry point. |
| `tts/` | The table side: the Lua rules, table callbacks and presentation, plus the blank table the save is built from. |
| `test/` | Node tests (`*.test.js`) and Lua tests (`*.lua`). |
| `docs/` | Rules, the quick start, validation evidence and plans for upcoming games. |
| `project_memory/` | The project's facts, decisions and roadmap (more on that below). |

## Ground rules for changes

A few things keep Buddy fair and safe, so please keep to them:

- **The rules live on the table.** Model output is only ever a choice from the legal moves the rules hand out. The Lua decides what's legal, applies the effects and keeps score.
- **Buddy only sees its own seat.** Hidden hands, unrevealed deck order and the human's private choices must never reach the model, the turn history or error messages. If you touch what Buddy is sent, add a paired hidden-state test (two states that differ only in hidden information should give Buddy identical input).
- **The model gets game actions and nothing else.** No raw table inspection, no running arbitrary Lua and no general object changes through the AI-facing side.
- **A human stays in charge.** Pause, takeover and stop have to keep working. Anything uncertain should pause and reread the table rather than guess or retry.
- **Moves happen once.** Keep request IDs and table revisions in place so a late reply or a reconnect can't replay a move.
- **Original game content only.** Don't commit Workshop saves, publisher art, rulebook scans or other third-party assets. Link to official rules instead, and write your own test fixtures.

## Making a change

1. Branch from `dev`. That's where day-to-day work happens, and `main` only moves when `dev` is promoted.
2. Write the test first and watch it fail for the reason you expect. Then make the smallest change that passes it and run the full `npm test`.
3. If a check needs the live game (a full match, a reconnect, something you can only see in TTS), do it by hand and write down what you checked and the result in [docs/validation.md](docs/validation.md).
4. Add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) for anything a player would notice.
5. Open a pull request against `dev` and fill in the template.

Commit messages are short, plain sentences in the imperative, like "Discover and verify local models at Buddy startup".

## Project Memory

`project_memory/` is the project's single source of truth for what TTS Buddy does, its limits and defaults, and the decisions behind them. It's read by people and by AI coding agents alike (it's kept with [AtlasMind](https://marketplace.visualstudio.com/items?itemName=JoelBondoux.atlasmind), an Open Source tool I built for VS Code), so it needs to stay accurate:

- If your change alters a fact recorded there (a default, a limit, a supported model, etc), update the page in the same pull request. The main ones are [product facts](project_memory/domain/product-facts.md) and the [roadmap](project_memory/roadmap/improvement-plan.md).
- If the docs, Project Memory and the code disagree and you can't settle it, add a line to [contradictions](project_memory/operations/contradictions.md) rather than guessing.

[AGENTS.md](AGENTS.md) has the full version for AI agents.

## Troubleshooting the tests

- **The three launcher tests fail with "'start-buddy.cmd' is not recognized".** Your shell has `NoDefaultCurrentDirectoryInExePath` set (some AI coding tools set it), which stops `cmd.exe` from finding the batch file in the current folder. Clear it for the test run, for example `env -u NoDefaultCurrentDirectoryInExePath npm test` in Git Bash.
- **Port 39998 is busy.** Close any other TTS external editor (such as an editor plugin) or Buddy instance. Only one program can listen for Tabletop Simulator at a time.

## Licence

TTS Buddy doesn't have a licence yet. Until it does, please check with me in an issue before reusing the code elsewhere.
