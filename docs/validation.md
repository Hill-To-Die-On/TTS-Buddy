# Prototype validation record

9 November 2026. The local MVP is playable and has passed live technical checks. Independent player feedback and distribution review are pending for the pilot.

## Completed so far

- M0 disposable-table connection, read, named move, independent read and callback-port contention/rebind: see [M0 evidence](m0-evidence.md).
- Automated tests: `npm test` runs Node tests and the actual Lua rules and table callbacks in Fengari (a development-only Lua 5.3 implementation). Rules tests cover Charge, Boost, Jam and the minimum score, first-to-seven, exhausted deck winner/draw, invalid turn, and 20 seeded rules-only matches. Callback tests cover setup, action, duplicate request, stale request, paired hidden states and a guessed action ID. Node tests cover sanitisation, validation and simulated interruption/recovery. These are not substitutes for live play.
- In a fresh TTS Singleplayer prototype, a human played via in-game buttons and the deterministic player took five automatic turns. Charge, Boost and Jam were exercised; the game ended Human 7–Buddy 3, with the UI and CLI agreeing on the winner and no manual repair or duplicated move. An initial in-match inspection timeout was traced to nested TTS callback serialization; serializing the snapshot to JSON inside a flat callback fixed the live inspect/play/inspect loop. The later generated package added score previews and physical markers, which were subsequently exercised in the pilot batch below.
- One generated-save live model match completed from a clean setup: human played through White hand buttons, the actual CLI and local model played five automatic turns, and Buddy won 8–5 without repair. The CLI started before New match and waited correctly. The subsequently rebuilt save adjusted marker placement and added a public local history; it was tested in the pilot batch below.
- **Model decisions.** The original prompt missed an immediately winning Boost. With rule-provided score previews and letter choices, the final adapter returned legal moves and matched the preferred choice in all six tactical samples. The deterministic player matched five of the six. It missed the defensive Jam when the human had 6 points and Buddy had 3.

## Final-save pilot batch

The save used for live playtesting had SHA-256 `86D66505986EBF46DB5456B1798155DF78782198A6871E719533BCB346301C34`. It was loaded from a fresh slot 23; the physical markers were readable from White above the overlay. One setup, timed after prerequisites, reached the first model turn in 54.1 seconds. Five consecutive live matches used scripted White-seat actions against the real TTS table, production bridge/session and local Ollama model. Human–Buddy scores were 6–7, 7–6, 5–7, 4–7 and 8–5. Scores and revisions were independently asserted; no illegal or duplicate moves or manual repairs occurred. Across 28 model turns, median time was 1.8545 seconds and slowest 3.752 seconds, including a one-second polling allowance. The earlier model match was played with the human seat through the in-game buttons.

The committed save has SHA-256 `556F93B9020C5C97351AF23F676854B381ED999BD1DDB64175E5179A9F65E193`. It differs from the live-tested save only by one trailing whitespace character in the embedded Lua. The rebuilt save passed the automated suite.

Live recovery checks covered a forced Ollama timeout, stale decision after table pause/resume during model choice, manual takeover/release, a lost applied acknowledgement followed by resynchronisation and duplicate-request ID, and a guessed action ID. After Node runtime formatting, a fresh Buddy process attached to the existing Human 1–Buddy 2 table without replay; a newly launched CLI later completed the pending model turn at Human 3–Buddy 2 to make it 3–3. Actual JSONL records contained only the expected public fields. A clean runtime copy without node_modules rebuilt the identical save, installed a fresh slot 24, loaded in TTS and played its first model move in 77.0 seconds from copy/build start. Human tester feedback and distribution review are still outstanding. These tests do not establish an independent human tester's willingness to play again.

## Outstanding gates

- Ask independent testers whether they would play again.
- Review distribution terms. Do not tag a pilot or make it public until its gates pass.
