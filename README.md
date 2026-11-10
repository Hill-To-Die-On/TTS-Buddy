# TTS Buddy

An AI player for Tabletop Simulator that follows the rules, takes its own turns and only looks at its own cards.

Right now Buddy plays one game, **Signal Run** (a quick original card game for two), against you in a local Singleplayer session on Windows. It's an early prototype that I'm building in the open, so expect a few rough edges.

> **Status: personal-use prototype, version 0.1.2.** There's no download yet. The packaged build stays on my PC until I've checked with Berserk Games how it can be shared (see the [pilot brief](docs/pilot.md)). You can build and run it from source though.

## What it does

- **Plays its own turns.** Buddy takes the other seat and plays a whole match against you, from the first card to the final score.
- **Plays fair.** It only gets what its seat could see: the cards on the table, its own hand and the moves it's allowed to make. Your hand and the deck order stay hidden from it.
- **Can't bend the rules.** The table's own script holds the rules and checks every move Buddy picks before it happens, so a confused model can't sneak in an illegal play.
- **Leaves you in charge.** Pause it, take over its seat or hand it back whenever you like.
- **Runs on your PC.** No accounts or cloud services needed. Buddy uses a model you run locally in Ollama, LM Studio or Unsloth Studio, or a simple rules-based opponent if you'd rather not bother with a model at all.

## How it works

Buddy is a small Node.js program that runs alongside Tabletop Simulator and talks to the table through TTS's own local [External Editor API](https://api.tabletopsimulator.com/externaleditorapi/). On Buddy's turn, the table's Lua sends it the public state, its hand and a lettered list of legal moves. The model picks a letter, then the table checks the move and plays it. Every request carries an ID and a table revision, so a late reply or a reconnect can't play the same move twice.

## Play Signal Run

You'll need Windows, your own copy of Tabletop Simulator and [Node.js](https://nodejs.org/) 24 or newer. For a model opponent you'll also want a local model server. Buddy looks for [Ollama](https://ollama.com/download/windows), [LM Studio](https://lmstudio.ai/) or Unsloth Studio, and tries Qwen3 4B in Ollama first.

1. Run `npm run build` to regenerate the Signal Run save. Copy it into an unused save slot and open it in Singleplayer. The [quick start](docs/quick-start.md) has the details.
2. Sit at White and run `start-buddy.cmd`. It checks your local models and tells you which one it's using. For the rules-based opponent, run `start-buddy.cmd --baseline` instead.
3. When the window says **Buddy started**, click **New match** on the table and play a card from the White hand.

The [Signal Run rules](docs/signal-run.md) fit in a paragraph, and the quick start covers pausing, taking over and getting going again if something goes wrong.

## How far it's got

Buddy has played complete live matches against a local model with no illegal moves, no repeated moves and no manual fixes. On the development PC its turns took a median of about 2 seconds. It has also passed recovery checks for timeouts, lost replies, takeovers and restarts mid-match. The [validation record](docs/validation.md) has the full results.

Still to do:

- An independent playtest by someone who isn't me.
- The distribution review, before anything is shared as a download.

Next up is [Flamme Rouge](docs/flamme-rouge.md), a cycling race with simultaneous secret card choices. That's a nice step up from Signal Run's hidden hands. Further out, the plan is bigger competitive, co-op and campaign games, each with its own game adapter. The [roadmap](project_memory/roadmap/improvement-plan.md) has the details.

## Contributing

Bug reports, playtest notes and ideas are all welcome on the [Issues](https://github.com/Hill-To-Die-On/TTS-Buddy/issues) tab. If you'd like to work on the code, [CONTRIBUTING.md](CONTRIBUTING.md) covers getting set up, running the tests (`npm ci`, then `npm test`) and the ground rules that keep Buddy fair. Security problems go through [SECURITY.md](SECURITY.md) rather than a public issue, and the [changelog](CHANGELOG.md) lists what's changed in each version.

## Licence

TTS Buddy doesn't have a licence yet. Until it does, please ask in an issue before reusing the code.

## Disclaimer

TTS Buddy is an unofficial fan project from [A Hill To Die On](https://github.com/Hill-To-Die-On). It isn't affiliated with or endorsed by Berserk Games. Tabletop Simulator is a trademark of Berserk Games, and the other games mentioned here belong to their publishers.
