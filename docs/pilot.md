# Signal Run — first Windows pilot

M3 is in progress. Commit `c0f2eaecbd0673266a1aa9a30c06eadc6ffa4e7c` is the baseline before the M3 packaging fix. Select the pilot revision after the checks below.

## Independent playtest

Use a dedicated Windows VM or spare PC so the development desktop remains available. A VM's ability to run Steam, TTS, guest 3D graphics and the local model is unproven. Check these on that machine before relying on it. Once a table is loaded, the local bridge baseline can run without foreground desktop interaction. The tester needs their own licensed TTS installation, Node.js 24 or later, Ollama and the candidate files in a fresh folder. Prepare prerequisites and the model before timing. Use an unused TTS save slot and keep existing saves intact.

1. Give the tester the reviewed candidate package and [quick start](quick-start.md). Have them install the demo table, sit at White, start Buddy with the fresh-machine model instructions, and start a new match. Time the setup from the first quick-start step after prerequisites to Buddy's first turn. Record any help needed. The official Ollama model tag in the quick start has yet to be benchmarked in this project.
2. Let them play a complete match using the table buttons. Record the score, outcome, errors, delays, unexpected behaviour and interventions. If a move's result is uncertain, pause and inspect before resuming. The [rules](signal-run.md) and quick start describe play, pause, takeover and recovery.
3. Ask whether they could set up without help, whether Buddy's moves made sense, what felt slow or unfair, and whether they would play another match. Capture suggestions and permission to retain any shared diagnostics. Review the local turn history before sharing it.

For the release evidence, repeat a second fresh setup and apply the full [pilot gates](../project_memory/roadmap/improvement-plan.md#pilot-release-gates), including five consecutive model matches, information filtering, recovery and timing. Record machine and model details, candidate revision, results and deviations. A tester's match may contribute only where the required evidence is actually captured.

## Evidence and remaining work

[Validation](validation.md) records two setup timings and five consecutive live model matches over the local bridge. Scripted White-seat actions exercised 28 model turns with a 1.8545-second median and zero illegal moves, duplicated moves or manual repairs. Earlier live play used the in-game human buttons.

M3 packaging checks found that Windows Git archive line endings could affect the outer JSON and embedded Lua. The builder now normalizes CRLF and `.gitattributes` pins table files to LF. LF and CRLF exports produced the same save SHA-256 `550D8A7F8F9AFD8F55FC5D60FB80F84DD673F94EDEAABD472B55F54F26F03292`. The normalized artifact still needs a live run. See [validation](validation.md) for the checks and historical hashes.

Before tagging, verify the fresh-machine setup and exact release save. Obtain independent feedback including willingness to play again, resolve the distribution questions below, and record acceptance of the evidence.

## Initial distribution review

The published terms were checked on 9 November 2026. Their application to this companion and its generated save needs clarification before sharing. [Berserk Games' Tabletop Simulator EULA](https://store.steampowered.com/eula/286160_eula_0)

- **Free, local pilot.** The EULA allows personal, non-commercial game use and sets conditions on free mod and derivative-work distribution, including distribution to licensed users in object-code form. Check how these terms apply to the companion and generated save, what may be shared, and the rights to included assets and dependencies. Package the pilot separately from the game.
- **Online use.** The EULA restricts unauthorised automation in connection with online features. The current pilot uses one local Singleplayer session. Assess online multiplayer or automation separately with Berserk Games.
- **Paid use.** The mod and derivative-work distribution terms require free, non-commercial releases. Assess any paid companion, subscription or bundle separately and establish what permission it would require from Berserk Games.

Record the proposed package contents, recipients and distribution method. Resolve classification and permissions before sharing or publication.
