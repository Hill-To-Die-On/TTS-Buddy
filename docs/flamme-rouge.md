# Flamme Rouge head-to-head plan

Selected on 10 November 2026 as the next game after Signal Run. Implementation and live validation are pending.

## First playable race

Run one base-game race on **Avenue Corso Paseo** in a local Tabletop Simulator Singleplayer session. The human and Buddy each control one team with a Rouleur and a Sprinteur. Use the introductory course with the tile faces indicated in the rulebook. The prototype covers that race from setup through the official finish order. Expansions, other courses and online play are outside this milestone. [Publisher's base game](https://en.lautapelit.fi/product/22825/flamme-rouge-eng) · [Official rulebook](https://www.buffalolib.org/sites/default/files/gaming-unplugged/inst/Flamme%20Rouge%20Instructions.pdf)

The local Workshop cache contains **Flamme Rouge [ENG] [RUS]**. Before building against it, open a disposable local table and verify the track tiles, riders and decks are usable. Record the edition and object mapping. Keep the Workshop save, publisher assets and rulebook copies outside Git and any Buddy package. Link to the rules and use original test fixtures. [Workshop entry](https://steamcommunity.com/sharedfiles/filedetails/?id=1203556563)

## What Buddy needs to do

- Identify the selected game and supported table before requesting a model decision or attempting a move. Keep the existing Signal Run save and launcher usable.
- Represent the track as ordered spaces and lanes. Send Buddy the public rider positions, round phase and its own available choices. Keep the human's drawn cards, committed choices and unrevealed deck order out of the model payload and history.
- Allow both sides to choose privately and commit their cards before revealing. The table owns the reveal, movement and lane rules, slipstreaming, exhaustion and finish order. The model chooses among legal options for its own team.
- Preserve safe pause and reconnect behaviour. A stale revision or repeated acknowledgement must never apply a second card choice or resolve a round twice.

## Build and acceptance

1. **Rules first.** Write failing tests for starting placement, independent rider decks, private commitment and reveal, blocked lanes, slipstreaming, exhaustion and multiple riders crossing in the same round. Implement against the fixed introductory course.
2. **Deterministic opponent.** Complete a race through the table controls against a rules-based Buddy. Add paired hidden-state tests and cover a restart or lost response between commitment and reveal.
3. **Local model.** Use the same legal actions with a local model. Complete a human-vs-Buddy race through the visible controls. Record the result, response timings and any interventions. Rerun Signal Run's regression suite.

Imperial Assault Skirmish is a later tactical candidate. Its unit abilities, line of sight and mission rules make it a larger adapter. [Official Skirmish Guide](https://www.fantasyflightgames.com/ffg_content/imperial-assault/support/SWI01_Skirmish%20Guide.pdf)
