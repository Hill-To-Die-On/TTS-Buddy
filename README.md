# TTS Buddy

TTS Buddy is a local Windows companion that plays one seat in Tabletop Simulator. The current MVP supports **Signal Run**, an original two-player card game. Buddy receives its own hand and legal moves, and the table's rules check each choice before applying it.

## Play Signal Run

1. Install Node.js 24 or newer and Tabletop Simulator on Windows.
2. Run `npm run build` to regenerate the Signal Run save. Install it in an unused save slot and open it in Singleplayer. The [quick start](docs/quick-start.md) has the steps.
3. Sit at White and run `start-buddy.cmd`. The launcher can discover a local model from Ollama, LM Studio or Unsloth Studio. For a deterministic opponent, run `start-buddy.cmd --baseline`.
4. When Buddy has started, click **New match** on the table and choose a card from the White hand.

## Develop

Run `npm ci` once to install the development dependencies, then `npm test` to run the Node and Lua suites. Follow the [test-first guidance](AGENTS.md#test-driven-development) when changing behaviour.

- [Signal Run rules](docs/signal-run.md)
- [Validation and live playtest evidence](docs/validation.md)
- [Flamme Rouge plan](docs/flamme-rouge.md) for the next head-to-head game
- [Roadmap](project_memory/roadmap/improvement-plan.md) and [external pilot gates](docs/pilot.md)

The repository records development. The pilot ZIP remains a personal-use build while the external pilot review is open.
