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

The save committed at `c0f2eaecbd0673266a1aa9a30c06eadc6ffa4e7c` has SHA-256 `556F93B9020C5C97351AF23F676854B381ED999BD1DDB64175E5179A9F65E193`. It differs from the live-tested save only by one trailing whitespace character in the embedded Lua. The rebuilt save passed the automated suite at that stage.

Live recovery checks covered a forced Ollama timeout, stale decision after table pause/resume during model choice, manual takeover/release, a lost applied acknowledgement followed by resynchronisation and duplicate-request ID, and a guessed action ID. After Node runtime formatting, a fresh Buddy process attached to the existing Human 1–Buddy 2 table without replay; a newly launched CLI later completed the pending model turn at Human 3–Buddy 2 to make it 3–3. Actual JSONL records contained only the expected public fields. A clean runtime copy without node_modules rebuilt the identical save, installed a fresh slot 24, loaded in TTS and played its first model move in 77.0 seconds from copy/build start. Human tester feedback and distribution review are still outstanding. These tests do not establish an independent human tester's willingness to play again.

## M3 packaging findings

Windows Git archive exports exposed CRLF in the outer save and source-dependent line endings in embedded Lua. The builder now normalizes CRLF and `.gitattributes` pins table files to LF. Exports with LF and CRLF inputs reproduced the same save SHA-256 `550D8A7F8F9AFD8F55FC5D60FB80F84DD673F94EDEAABD472B55F54F26F03292`. A check using `git archive --worktree-attributes` verified the attributes. Embedded Lua matched after newline normalization and non-script JSON fields were identical.

The build regression test failed against the M2 builder with a line-ending mismatch and passed against the M3 fix. The full `npm test` suite passed all 15 Node tests and the Lua suites, including 20 seeded rules-only matches. The final pilot revision remains to be selected.

## M3 Windows VM live checks

On 9 November 2026, a dedicated VirtualBox 7.2.22 guest booted Windows 11 Enterprise LTSC Evaluation with four virtual CPUs and 6 GiB of RAM. Setup needed recovery from stalled reboots. The guest file-transfer service came up after a cold boot with basic graphics and guest paravirtualization disabled.

The guest rebuilt candidate `1028598`, reproduced the normalized save checksum above and passed all 15 Node tests, including the line-ending regression. The live harness failed at the expected table connection check before the guest had a running copy of Tabletop Simulator. Steam's initial client update failed before installing its interface library. Verified stable Valve packages repaired it. Steam installed Tabletop Simulator 14.2.2 (Steam build `22252224`). Steam Cloud was disabled in the guest after Steam flagged a save sync conflict. The exact candidate was staged in unused guest slot 99 and loaded in a local Singleplayer table using the in-game console.

With 8 GiB of guest RAM and 3D acceleration enabled, Tabletop Simulator initialized Direct3D 11.1 through the VirtualBox WDDM adapter. The game remained at a black window without a scripting listener. Direct3D 11 software rendering through the Microsoft Basic Render Driver reached the menu and loaded Signal Run with VirtualBox 3D disabled.

The exact normalized save completed a scripted White-seat match against the deterministic player. Human won 7–6 after six Buddy turns. The harness checked the public observation fields, turn revisions, scores and winner.

The first simulated timeout check used a 250 ms deadline and did not observe a request reaching the test endpoint. A rerun with a 3-second deadline confirmed that the stalled endpoint received the request, the adapter raised a timeout and Buddy paused without a move. The rerun also passed stale-decision rejection after pause/resume, lost acknowledgement, reconnect and replay of the same receipt without duplicating a move. The product timeout was unchanged.

Guest Ollama 0.40.15 used the official `qwen3:4b-instruct-2507-q4_K_M` tag on CPU. The first live request hit the existing 30-second deadline during a cold load and Buddy paused. A separate warm-up completed in 19.9 seconds, including 18.4 seconds loading weights. Three consecutive model matches then finished at 6–7, 6–7 and 8–4 (Human–Buddy). The fourth paused on a stalled turn. VirtualBox logged 132 seconds of clock lag during that run, and Ollama logged a request lasting 100 seconds. The batch did not satisfy the five-match gate.

A second batch with the model preloaded and the guest display reduced to 800 × 600 passed five consecutive scripted White-seat matches. Human–Buddy scores were 5–7, 7–5, 7–6, 7–6 and 5–7. The harness verified scores, winners and revisions without illegal moves, duplicate moves or manual repairs. Across 25 model turns, the median was 6.00 seconds and the slowest was 6.05 seconds from turn dispatch through table confirmation. The 30-second model deadline and five-second table deadline were unchanged.

An initial live privacy probe timed out during another VirtualBox clock lag. The retry used synthetic states in the loaded table with matching public state and different hidden White cards and deck order. The raw Buddy observations matched. A guessed object ID returned a generic rejection without changing state. The probe verified White-scoped UI declarations during takeover, manual play, release to automatic play, and a draw in Buddy's projection. It inspected UI declarations on the Singleplayer host. The production CLI then attached, wrote only public history fields and stopped without changing the table.

## Local pilot package

`TTS-Buddy-M3-1028598.zip` packages the committed code and table from `10285982045d0ba2bc47bc852e918fdd36b9a506` with a fresh-machine quick start. Two independent archive builds produced the same SHA-256 `E950FCE393B1B60304AC7608E2711A783F1ED71A46D8DC5A283A9747CF32E67D`. A fresh extraction rebuilt the exact normalized save, passed all 15 Node tests and passed the Lua suite using the existing pinned development dependencies. The ZIP contains project files only. The licensed game, Node, Ollama and the model are installed separately.

Timed setup 1 used a fresh extraction of that ZIP, guest save slot 19 and the production CLI in Singleplayer. With the model warmed, elapsed time from extraction start through the first confirmed Buddy move was **2 minutes 10.5 seconds**. The harness invoked the same White-seat callbacks as the in-game New match and first card buttons. The first Buddy move was Boost at revision 3, with the history and live table showing a 2–2 score. An earlier attempt stalled in VirtualBox before model preparation finished and before the setup timer started.

Timed setup 2 used a separate fresh extraction and guest save slot 21. After guest control stalled between runs, Windows was shut down cleanly and cold-started with VirtualBox's Hyper-V guest paravirtualization provider. With the model warmed, the production CLI confirmed Buddy's first move after **1 minute 38.1 seconds**. Buddy played Boost at revision 3 to make the score 2–2. Both technical setups met the 10-minute target. The VM was shut down, its prior settings were restored and autostart was verified off.

## Personal launcher

The Windows launcher now loads the installed model before the first table inspection. The preload tests initially failed because the operation was missing. They then passed for a prompt-free load, a missing model and an incomplete response. The full suite passed 17 Node tests and the Lua tests.

A Windows smoke check invoked the actual batch file from a fresh runtime copy with simulated Ollama and TTS services on localhost. It verified preload before the first model move, a custom model, a deterministic baseline without Ollama and a startup error without table requests when the model was missing. The timed pilot ZIP above represents the earlier candidate.

On 9 November, the dedicated Windows VM ran the updated batch launcher against the exact Signal Run save in slot 99. The guest needed clock recovery while opening the save. Ollama reported the model unloaded before launch and loaded after **20.345 seconds**. Scripted White moves exercised a complete real Singleplayer match. Buddy won **7–6** in five Buddy turns. The driver checked every public revision and score through revision 11 and confirmed that the CLI agreed with the result.

The full-match driver's stop wait timed out after the confirmed finish. A separate check attached the same launcher to the finished game, observed pause and resume, then sent `stop` with standard input still open. The process exited with code 0 in **1.730 seconds**, released its callback port and left the table at revision 11 with the same final score. A personal playthrough remains the next usability check.

## Personal-use MVP package 0.1.0

`TTS-Buddy-Signal-Run-MVP-0.1.0.zip` includes the updated Windows launcher, prebuilt Signal Run save and first-run guide. Its SHA-256 is `E2EEFBCFE629024904B60ABA0160D63F96CFE03E5C4F559712A5B866C6C510BA`. The package recipe regenerated that ZIP byte for byte. The fresh extraction passed all 17 Node tests and the Lua suite, and rebuilt the save to SHA-256 `550D8A7F8F9AFD8F55FC5D60FB80F84DD673F94EDEAABD472B55F54F26F03292`.

All seven files used by the packaged runtime match the earlier live launcher archive byte for byte. The save also matches the one used for the five-match batch and recovery checks. Signal Run publishes the card just played, and the paired-state probe exercised a private draw in Buddy's projection and the permitted disclosure during White's takeover.

On the first clean MVP install, the extracted save loaded in guest slot 98 and the packaged launcher preloaded the cold model in **35.644 seconds**. VirtualBox then lost the guest heartbeat. Buddy paused on an uncertain table response, and the New match click reached the table after clock recovery. That attempt ended before the first Buddy move. A two-CPU restart stalled in firmware and the guest was restored to four CPUs.

The restored VM booted Windows, then Guest Control timed out during model preparation before the second install started. The exact ZIP has fresh-extract, save-load and cold-start evidence. Full-match and recovery evidence comes from the byte-identical live runtime and save above. The timed setup results remain those of the earlier package. A full playthrough through the visible controls remains a usability check.

## Windows startup patch 0.1.1

When the launcher window closed on startup, the local Ollama service was reachable and its model list was missing the default Buddy model. The model appeared on a subsequent check. The 0.1.1 launcher reports an incomplete extraction or missing Node.js, displays an animated bar during model preload and leaves startup errors visible in an interactive console until Enter. Redirected runs preserve the exit code and finish without a prompt.

All five new launcher tests failed before the changes and passed afterward. The fresh 0.1.1 ZIP passed all 22 Node tests and the Lua suite. Two builds produced the same SHA-256 `F5BF26ADB9B5E78252903714298C8904243BD7E07FF61CC6BB7DA1F9D4EAFF8D`, and the included Signal Run save rebuilt to the same SHA-256 as 0.1.0. A hidden Windows console using the packaged launcher and a simulated model failure showed 16 animation frames, kept the error visible until Enter and returned the original nonzero exit code.

## Automatic local model startup 0.1.2

Ollama listed the exact Qwen3 tag, and the earlier launcher request ended after two minutes while the runner was starting. With the new 2,048-token context, the installed model passed the startup probe in 37.5 seconds and chose the expected action on a second sample turn. A separate check isolated LM Studio and verified that it loaded the installed Qwen3 4B and passed the startup probe in 9.3 seconds. The check released its LM Studio instance and confirmed the other loaded model stayed in place.

The new selector tests first failed because automatic discovery was missing. They then passed for model filtering, a failed Ollama startup followed by LM Studio, an active Unsloth model, reduced context on normal turns, and approved, declined and noninteractive download paths. The fresh 0.1.2 ZIP passed all 28 Node tests and the Lua suite. The actual batch file also passed isolated Windows smoke checks for baseline, a pinned Ollama model, redirected startup, declining with Enter and approving with y. The download was simulated. The local Unsloth Studio API was unavailable during live validation. These checks exercised model inference without opening or moving the game table.

Two builds produced the same archive SHA-256 `987D1148B4E57FF58F2C7A85EA0E5237B4699AA7ADD0D003F3BCF0E997238C7B`. The included save rebuilt to the existing Signal Run checksum.


## Outstanding gates

- Ask independent testers whether they would play again.
- Select the accepted release revision after the independent playtest. Repeat affected checks if the package changes.
- Review distribution terms. Do not tag a pilot or make it public until its gates pass.
