# TTS Buddy MVP plan and roadmap

Personal-use Windows MVP 0.1.2 · Updated 10 November 2026

[Detailed implementation plan](mvp-implementation-plan.md)

## MVP outcome

A Windows player opens one supported Tabletop Simulator save and finishes a match against TTS Buddy in the same local session. Buddy recognises the relevant pieces, sees what its seat is allowed to know, chooses and plays its own legal turns, and tracks the result. The player uses the normal tabletop controls. The AI seat is driven by the host's script, with the existing TTS installation as the only game client.

**First game proposal.** Use an original, short two-player draw-and-play card game with a hidden hand, a targeted card effect and a clear scoring or win condition. The first table can use simple cards and tokens. This tests fair observations, rule exceptions and turn progression in a game small enough to replay frequently. Confirm the fixture in the first milestone. A third-party game can be a later test with authorised material.

## Two ways to test play

- **ChatGPT desktop experiment.** On a disposable local table, see whether Computer Use can recognise visible pieces, make a legal move, operate cards or dice, and hand play back across three consecutive turn exchanges. Record timing, prompts and manual interventions. Keep this as an interactive mode if it works reliably. OpenAI documents desktop app control. Account access and sustained gameplay in TTS are questions for the test. [OpenAI Computer Use guide](https://developers.openai.com/training/walkthroughs/using-your-computer-and-browser)
- **Scripted bridge for repeatable play.** Use a small local process and a reviewed Lua script in the supported save. Start with structured custom messages over TTS's documented localhost connection. Evaluate the existing experimental MCP server for transport and test ideas. Test callback port conflicts and reconnection on Windows. If code is reused, pin the revision and retain its MIT notice. Its general table tools and best-effort filtering require review before reuse. [TTS External Editor API](https://api.tabletopsimulator.com/externaleditorapi/) · [Existing TTS MCP server](https://github.com/gosuni2025/tabletop-simulator-mcp)
- **Model choice.** Build a deterministic test player first, then try one local model as the default for the autonomous MVP. Measure it on the target PC. Where a supported desktop integration works, the same restricted interface can support a ChatGPT-driven turn. A hosted model can be evaluated separately if local quality or speed falls short. The OpenAI API has separate billing from ChatGPT. [OpenAI billing documentation](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform)

## How a turn works

1. The game adapter identifies objects in the supported save, tracks the active seat and publishes a versioned view containing public state, Buddy's own hand, recent permitted events and legal action IDs.
2. The model chooses one action ID and can supply a short explanation. The rules code handles legality, effects, scoring and the outcome. Define the rules once for the chosen game from a short, reviewed rule sheet and cover each effect with a test.
3. The local bridge rechecks the active seat, action and state version before applying it, then confirms what changed. Each request has an ID so a delayed acknowledgement or reconnect cannot repeat a draw, play or score change.
4. The player can pause Buddy or take over. On a timeout, unexpected table change or ambiguous result, pause and reread the authoritative table state before continuing. Resume after restarting Buddy while the TTS session remains open. Store a minimal, redacted turn history locally.

Filter before handing observations to a model, chat tool or diagnostic log. The AI-facing interface accepts only game actions. Keep raw table inspection, arbitrary Lua execution and general object mutation out of that interface. Treat a fully privileged local host as trusted for this prototype.

## Roadmap

Working estimate for one developer is **10–18 focused development days**, with playtest availability and fixes determining the calendar. Re-estimate after the first milestone.

| Milestone | Effort | Exit gate |
| --- | --- | --- |
| M0 · Prove the connection | 1–2 days | On the current Windows TTS build, read a known object, apply one named move, observe the result and reconnect safely. Choose the demo game and record the desktop experiment and bridge reuse decision. |
| M1 · Finish a game with a test player | 3–5 days | From setup to final score, one human and a deterministic opponent finish the supported game in TTS. The rules tests cover each card effect, scoring and game end. |
| M2 · Replace test decisions with a model | 4–7 days | Buddy finishes full matches with model-driven moves. Test pause, manual takeover and recovery after a forced interruption. Retain the deterministic player for comparison and debugging. |
| M3 · Package the personal MVP | 2–4 days | Produce a reproducible Windows package, demo save and quick start. Verify the included runtime and save against the technical evidence below. |
| External pilot | Later | Resolve distribution questions, collect independent playtest feedback and accept a revision for the pilot tag. |

M0 evidence, including the desktop experiment and bridge reuse decision, is recorded in [docs/m0-evidence.md](../../docs/m0-evidence.md). [Validation](../../docs/validation.md) records the live model batch, recovery checks and two timed setups from the exact M3 candidate ZIP. The [pilot brief](../../docs/pilot.md) covers the remaining distribution clarification and independent playtest. The pilot tag follows acceptance of those checks.

The private 0.1.0 ZIP contains the exact runtime and save that finished a scripted local Singleplayer match. The 0.1.1 launcher update adds model-loading progress and keeps startup errors visible. Version 0.1.2 discovers local models, verifies that a candidate can play a sample turn and offers an Ollama download with interactive consent when needed. Package reproducibility, fresh-extract tests and the VM observations are in [validation](../../docs/validation.md). A personal playtest confirmed the game controls and responsive Buddy turns after loading a fresh save. A complete personal match result and independent playtest remain open.

### Delivery backlog

<!-- atlasmind:roadmap-items:start -->
- [x] M0 · Prove local TTS read, named move, acknowledgement and reconnect on a disposable save. #mvp <!-- rm:mvp-bridge-spike -->
- [x] M0 · Run the subscription-only desktop control test and decide which bridge code, if any, to reuse. #mvp <!-- rm:mvp-desktop-and-reuse -->
- [x] M0 · Pick the demo game and write the one-page rules and expected outcomes. #mvp <!-- rm:mvp-demo-fixture -->
- [x] M1 · Map the demo save's pieces to game state and implement seat-specific observations and legal actions. #mvp <!-- rm:mvp-game-adapter -->
- [x] M1 · Run a full match with the deterministic player and verify turn order, effects, final score and win condition. #mvp <!-- rm:mvp-baseline-match -->
- [x] M2 · Connect one model provider, compare its decisions to the test player and surface Buddy's public move explanations. #mvp <!-- rm:mvp-model-player -->
- [x] M2 · Verify hidden-information filtering, interrupted actions, pause, takeover and resync. #mvp <!-- rm:mvp-turn-safety -->
- [x] M3 · Package and verify the personal-use Windows MVP. #mvp <!-- rm:mvp-personal-package -->
- [ ] External pilot · Collect independent feedback, complete distribution review and tag the accepted pilot build. #mvp <!-- rm:mvp-pilot -->
- [ ] Flamme Rouge · Verify the local table, lock the introductory course and test the rules and private commitments. #post-mvp <!-- rm:flamme-rouge-rules -->
- [ ] Flamme Rouge · Finish a live race against a deterministic Buddy and verify recovery during the reveal phase. #post-mvp <!-- rm:flamme-rouge-baseline -->
- [ ] Flamme Rouge · Finish a live head-to-head race with a local model and rerun Signal Run checks. #post-mvp <!-- rm:flamme-rouge-model -->
- [ ] Tutorial · Play through the Signal Run tutorial live in TTS, with a local model explaining each step. #post-mvp <!-- rm:tutorial-signal-run-live -->
- [ ] Tutorial · Give every game adapter its own lessons, starting with Flamme Rouge on its table. #post-mvp <!-- rm:tutorial-every-game -->
- [ ] Workshop tables · Attach Buddy to a loaded Workshop table at runtime, survey its pieces and save a confirmed table profile, starting with Flamme Rouge. #post-mvp <!-- rm:workshop-attach-survey -->
- [ ] Tutorial · Teach through a guided first round on the live table, starting with Flamme Rouge. #post-mvp <!-- rm:tutorial-guided-round -->
<!-- atlasmind:roadmap-items:end -->

### Pilot release gates

These thresholds are initial targets for the local pilot.

- **Setup.** Two fresh setups following the quick start reach Buddy's first turn within 10 minutes, timed after installing the prerequisites and preparing the supported model.
- **Complete play.** Five consecutive full matches with the model enabled, with zero illegal actions applied, zero duplicate moves and zero manual state repairs. Log whether each match finished with the correct winner and score.
- **Fair information.** In paired test states that differ only in the human hand or unrevealed deck order, Buddy receives the same observation and legal actions. Check that diagnostic output and action errors also exclude those identities, and that a guessed object ID cannot be used to act on a private object. Exercise a legal reveal separately and verify it becomes available only to the intended seat.
- **Recovery.** Force a model timeout, a lost acknowledgement after a move, a stale decision after the human moves and a Buddy restart mid-match. The app pauses or resynchronises without replaying a move. Stop and manual takeover both work.
- **Playing experience.** Target a median of 10 seconds or less from Buddy's turn starting to its move being applied, across at least 20 AI turns on the pilot PC. Record the slowest turn and ask each tester whether they'd play another match.

## After MVP

- **Next.** Build the [Flamme Rouge head-to-head adapter](../../docs/flamme-rouge.md) for one local introductory race, on its existing Workshop table. It's the first test of Buddy joining a Workshop game it didn't come with, on the way to joining any Workshop game as an opponent, a teammate or a games master. Use visible track movement and private simultaneous card choices to exercise the adapter boundary. Verify the game identity before any model request or move and keep Signal Run compatible. Imperial Assault Skirmish remains the later tactical candidate.
- **Tutorial mode.** Every supported game gets step-by-step lessons that Buddy explains at the table, with practice moves checked by that game's rules. The shared runner and the Signal Run lessons are built and tested, and the Flamme Rouge lessons are ready for its table. [Tutorial mode](../../docs/tutorial.md)
- **Later.** Add voice, campaign memory and spoiler controls for **ISS Vanguard**, tactical movement and line of sight for **Imperial Assault**, then negotiation, several AI factions and separate player memories for **Twilight Imperium**.
- **Separate decisions.** Evaluate a separate Steam client if an independent player seat becomes a requirement. Treat online automation, third-party assets and monetisation as separate permission and distribution reviews. TTS's published EULA addresses mod distribution and unauthorised automation in online features. [Tabletop Simulator EULA](https://store.steampowered.com/eula/286160_eula_0)
