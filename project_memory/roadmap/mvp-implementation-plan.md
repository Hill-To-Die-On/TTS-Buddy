# TTS Buddy MVP implementation plan

9 November 2026 · Execution plan for the [canonical roadmap](improvement-plan.md)

## Deliverable

A Windows player can open a supplied local Tabletop Simulator demo, start Buddy and finish a match against it inside the table. A rules-based player is the diagnostic baseline. One locally running model provides the actual MVP opponent. The player can pause, resume or take over Buddy's seat.

Implement on the local `dev` working copy. Keep the roadmap's existing item IDs. Update its checkboxes and product facts as evidence comes in, with the test and result alongside any unfinished live gate. Use the repository's test-first guidance. The pilot build and its supporting data stay local while distribution is reviewed.

## M0 · Prove the table connection and choose the fixture

1. Use the existing Windows TTS installation and a new single-player or hotseat test table. Record the TTS build and confirm which local mode supports the host's script and normal player interaction.
2. On a disposable table, try the subscription-only desktop route for three consecutive exchanges. Check recognition, a deliberate piece move or card interaction, turn handoff and the number of manual prompts. Record one of pass, fail or blocked with the observed reason. Continue with the scripting bridge while resolving any desktop blocker.
3. Implement a minimal Node.js client and Lua handler around the TTS External Editor API custom messages. Check a known object or public marker, request one named move, read its acknowledgement and inspect the result in the live table. Repeat after a disconnect. Test Windows callback-port contention and release. Compare the upstream MCP server's transport and smoke-test approach. Start with a narrow bridge unless reuse demonstrably saves work, and record the decision. [TTS External Editor API](https://api.tabletopsimulator.com/externaleditorapi/) · [Existing TTS MCP server](https://github.com/gosuni2025/tabletop-simulator-mcp)
4. Create an original fixture with a short rules sheet and seeded examples. Working title **Signal Run**. Use 18 numbered cards, 8 Charge cards worth 1 point, 6 Boost cards worth 2 points and 4 Jam cards worth 1 point that also remove 1 point from the other seat, to a minimum of zero. Deal two private cards to each seat. On a turn, draw one if available and play one. First to 7 wins. If both hands and the deck empty first, highest score wins and equal scores draw. Use known seeds in tests and a normal shuffled deal during play. Keep the fixture small enough to finish and replay in minutes.

**Exit evidence.** A live read, action, acknowledgement and reconnect on the disposable save, plus the game rules and the desktop experiment result. A loopback simulator can cover failure modes before the live run. Report simulated and live results separately.

## M1 · Finish a match in TTS

1. Use the current Node.js LTS already installed for the local process and Lua for the TTS script. Start with the standard library and Node's test runner. Add a development-only Lua harness if needed to run the real rules script independently of TTS.
2. Keep authoritative game state and rules in Lua so the same rules enforce human and Buddy moves. Store seat, hand slots, draw pile, scores, latest public effect, active seat and match result. Represent the table with a deck, visible score and turn status, and a seat-restricted hand view in TTS. Ensure play works through the actual in-game controls, including the start of a new match.
3. Have Lua build a seat-specific snapshot. Node receives only public state, Buddy's hand, legal action IDs and revision. Human-only visibility and revealed effects follow the rules sheet. An action ID is scoped to its snapshot and points to a legal card slot. Keep GUIDs and raw Lua away from the model.
4. Connect the baseline player through the same interface the model will use. Cover setup, each card effect, minimum score, turn order, empty-deck handling, win and draw. Run seeded matches and then complete a live match in TTS with a human seat and the baseline opponent.

### Bridge contract

| Operation | Input | Result |
| --- | --- | --- |
| Inspect | Protocol version and request ID | Match ID, revision, phase, active seat, score, public last action, Buddy's hand, legal action IDs and a safe status |
| Play | Protocol version, request ID, match ID, expected revision and legal action ID | Applied or rejected, a safe reason, and the resulting revision |
| Control | Pause, resume, take over or release, via the host interface | Acknowledged mode and fresh revision |

Accept fixed commands from the companion on loopback. Check request type, match ID, revision, active seat and action before mutation. The same play request must return the same outcome without replaying it. Use a new match ID on reset. Correlate callbacks to the active request, bound the payload size, and ignore stale or unexpected messages. A lost acknowledgement triggers a fresh observation before any new move. Keep private cards and prompts out of operational logs.

## M2 · Add the model and recover safely

1. Benchmark one locally available model through Ollama. Confirm its availability, local resource use and latency on the target PC. Send the filtered snapshot and the short rules, request a constrained action-ID response, and validate the response before passing it to Lua. Keep the baseline selectable for diagnosis. Report whether any runs used it.
2. Display a concise public move description derived from the observed move. Keep the model's optional reasoning private by default because it can mention its hand. Host controls should visibly distinguish waiting, paused, manual and completed.
3. Test model timeout and malformed output, loss of an acknowledgement after the table changed, human changes while a decision is in flight, duplicate request, restart of Buddy while TTS stays open, and pause or takeover during a decision. Any unknown result pauses play and requires a fresh snapshot. Verify no double draw, score or turn advance.
4. Use paired states that vary only hidden cards. Confirm the model payload, error and logs contain no opponent identities or unrevealed deck order. Try a guessed object ID and wrong seat action, and verify both leave state unchanged.

**Exit evidence.** At least one full live model-driven match, the failure tests and a recorded baseline comparison. Treat a simulated or baseline match as evidence for its own layer.

## M3 · Package the personal-use MVP

1. Supply a reproducible Windows launch command or launcher, the original demo save with its Lua, and a quick start with prerequisites, first match, pause/resume, port conflict and troubleshooting. Record the TTS build and model used. Keep API credentials out of the workflow.
2. Run the canonical pilot gates. Time two clean setups after prerequisites are ready. Run five consecutive full model-driven matches and at least 20 AI turns. Record turn timings, slowest turn, correct result, rejected or duplicate attempts, interventions and whether each tester would play again.
3. Check the demo and run tests from a fresh copy of the intended package. Match its runtime and save bytes to the live evidence, or repeat affected checks if they differ. Record usability observations separately from the automated results.

An external pilot requires independent feedback, distribution review and acceptance of the pilot revision before tagging it. The personal-use Windows package and its technical evidence are recorded in [validation](../../docs/validation.md).

## Ownership and handoffs

Terra 6.1 High works through M0–M3 in order and reports at each milestone with changed files, commands, observed results and the next gate. If a section stalls after a focused reproduction and one reasonable alternative, report the blocker and park that section. Include the current hypothesis, smallest failing case and files touched. Sol 6.1 takes that section while Terra continues independent work. Hand the result back to Terra for integration and rerun the affected checks. Use one writer per file during a handoff.

The starting task is a live inspect → named move → observe loop on a disposable TTS table. Bring up the fixture and rules tests in parallel if the live app needs setup.
