# Signal Run — external Windows pilot

The personal-use packages through 0.1.2 and their technical checks are recorded in [validation](validation.md). The earlier technical pilot ZIP used commit `10285982045d0ba2bc47bc852e918fdd36b9a506`. Select and tag an external pilot revision after the checks below.

## Independent playtest

Use a dedicated Windows VM or spare PC so the development desktop remains available. The test VM runs Steam, Tabletop Simulator and Ollama with software rendering for TTS. See [validation](validation.md) for the guest configuration and results. Once a table is loaded, the local bridge can run without foreground desktop interaction. The tester needs their own licensed TTS installation, Node.js 24 or later, Ollama and the candidate files in a fresh folder. Prepare prerequisites and the model before timing. Use an unused TTS save slot and keep existing saves intact.

1. Once sharing is cleared, give the tester the reviewed candidate ZIP. Have them follow its included quick start to install the demo table, sit at White, start Buddy, and start a new match. Time the setup from extraction to Buddy's first confirmed move after prerequisites are ready. Record any help needed.
2. Let them play a complete match using the table buttons. Record the score, outcome, errors, delays, unexpected behaviour and interventions. If a move's result is uncertain, pause and inspect before resuming. The [rules](signal-run.md) and quick start describe play, pause, takeover and recovery.
3. Ask whether they could set up without help, whether Buddy's moves made sense, what felt slow or unfair, and whether they would play another match. Capture suggestions and permission to retain any shared diagnostics. Review the local turn history before sharing it.

The earlier candidate has two technical setup timings and a VM model batch. The 0.1.2 launcher also has model-startup checks and personal desktop feedback. Use the [pilot gates](../project_memory/roadmap/improvement-plan.md#pilot-release-gates) to review that evidence and repeat affected checks if the candidate changes. Record the independent tester's machine, model, candidate revision, results and any assistance.

## Evidence and remaining work

[Validation](validation.md) records two setup timings and five consecutive live model matches over the local bridge. In the host batch, scripted White-seat actions exercised 28 model turns with a 1.8545-second median and zero illegal moves, duplicated moves or manual repairs. Earlier live play used the in-game human buttons. The later personal desktop playtest reported responsive turns after loading a fresh save.

M3 packaging checks found that Windows Git archive line endings could affect the outer JSON and embedded Lua. The builder now normalizes CRLF and `.gitattributes` pins table files to LF. LF and CRLF exports produced the same save SHA-256 `550D8A7F8F9AFD8F55FC5D60FB80F84DD673F94EDEAABD472B55F54F26F03292`. The guest rebuilt and loaded that exact save for the M3 live checks.

Before tagging, verify the fresh-machine setup and exact release save. Obtain independent feedback including willingness to play again, resolve the distribution questions below, and record acceptance of the evidence.

## Initial distribution review

The published terms were checked on 9 November 2026. They describe free, non-commercial distribution to licensed users in object-code form for mods and derivative works. The pilot has a separately running Node companion that uses the documented local External Editor API and a standard JSON save with original readable Lua and built-in asset references. The published materials leave open how the object-code provision applies to each part. Keep the package in the local workspace pending written clarification. [Berserk Games' EULA](https://store.steampowered.com/eula/286160_eula_0) · [Importing saves](https://kb.tabletopsimulator.com/custom-content/importing-mods/) · [External Editor API](https://api.tabletopsimulator.com/externaleditorapi/)

- **Free, invite-only pilot.** Ask Berserk Games whether licensed testers can receive the JSON save and the companion source directly and whether a particular format or private channel is required. The local package contains project files and the built-in asset references. Each tester obtains their own licensed game, Node, Ollama and the model separately. [Berserk Games contact](https://tabletopsimulator.com/contactsupport)
- **Online use.** The EULA restricts unauthorised automation in connection with online features. The current pilot uses one local Singleplayer session. Assess online multiplayer or automation separately with Berserk Games.
- **Paid use.** The mod and derivative-work distribution terms require free, non-commercial releases. Assess any paid companion, subscription or bundle separately and establish what permission it would require from Berserk Games.

Record the proposed package contents, recipients and distribution method. Resolve classification and permissions before sharing or publication.
