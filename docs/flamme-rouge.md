# Flamme Rouge head-to-head plan

Selected on 10 November 2026 as the next game after Signal Run, and as the first test of Buddy joining an existing Workshop table. The rules engine and tutorial lessons are written and tested. Table integration and live validation are pending (see [progress](#progress) and [joining the Workshop table](#joining-the-workshop-table) below).

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

## Progress

Updated 10 November 2026.

**Rules (step 1).** `tts/flamme-rouge/rules.lua` holds the rules for two teams. `test/flamme-rouge.lua` covers:
- independent rider decks with the base-game values;
- placement behind the start line, one team at a time, right lane first;
- drawing four, keeping one face down and recycling the rest, including reshuffling and short decks;
- paired hidden states, where Buddy's view is identical whatever the human drew, chose or has left in their decks;
- front-to-back movement, riding through others, full squares and the right-lane rule;
- slipstreaming chains and gaps of two, and exhaustion (including an empty lane that doesn't count);
- several riders crossing in one round, and a right-lane tie;
- ascent and descent limits;
- the course layout;
- 20 seeded races that always finish with every card accounted for.

Two rulings the rulebook leaves open:
- A rider with no cards left at all plays an exhaustion card, so the race can continue.
- A pack with any rider on an ascent neither gives nor gets slipstream, whether it's the pack behind the gap or the one in front. This doesn't matter on the flat introductory course.
- A finishing move isn't stopped at the last square of the track. The full distance counts, so a rider who would have gone further across the line still finishes ahead.

**Tutorial lessons.** `tts/flamme-rouge/tutorial.lua` has eight lessons, with practice steps for choosing energy and catching a slipstream. See [tutorial mode](tutorial.md).

**Course.** The rulebook sets Avenue Corso Paseo as tiles `a` to `u` in order, lower-case side up. The tile shapes in the Workshop save give the types: `a` start, `u` finish, `b c d f l m n` straights, and the twelve other letters turns. The course data assumes the following, all still to check on the live table:
- 6 squares on the start, finish and straight tiles and 2 on turns, 78 squares in all;
- 5 squares behind the start line;
- the finish line 5 squares before the end;
- every lower-case face is flat.

**Workshop table, from the cached save (read only).** Flamme Rouge [ENG] [RUS], saved with TTS v10.0.2. It has no scripting and no object names or descriptions. It contains:
- a catalogue of the 21 track tiles with A to U labels and both faces side by side, plus all 21 already laid out in the middle on one face;
- eight rider figurines, an R and an S in each of red, blue, green and black;
- eight rider decks of 15 and two exhaustion decks of 30;
- four single cards that look like player boards;
- a deck of six plus one loose card, probably the stage cards.

Which face is lower case, which deck belongs to which rider and the card values all need a look at the live table, because nothing is labelled.

## Joining the Workshop table

Decided on 10 November 2026: Flamme Rouge runs on its existing Workshop table, not an original one. It's the first test of Buddy joining a Workshop game it didn't come with. The longer-term aim is for Buddy to join any Workshop game as an opponent, a teammate or a games master, and to teach it. So each piece below is built to carry over to other games.

1. **Attach.** With the Workshop table loaded in Singleplayer, Buddy's host connects over the same localhost External Editor API and loads a small agent script into the running game. The mod itself is never edited or saved over. Only the trusted host does this; the model still only ever picks from legal moves.
2. **Survey.** The agent lists the table's objects (type, tint, position, deck contents and images), and Buddy proposes a mapping:
   - which tiles form the track, and in what order;
   - which figure and deck belong to each rider;
   - which piles hold the exhaustion cards.

   For an unlabelled mod like this one, the player confirms or corrects that mapping once, and it's saved locally as a table profile. This is also where the square counts, line positions and tile faces get checked.
3. **Seats and hidden cards.** Buddy takes a seat colour with its own hand zone. The agent reads Buddy's hand and anything face up. It never reads the player's hand or face-down cards until the rules reveal them.
4. **Physical moves.** Buddy draws into its hand, places its chosen card face down, and after the reveal moves riders to the right squares, worked out from the tile positions. The player uses the normal TTS controls, and the agent only reads their choices once they're turned over.
5. **Play, then teach.** First comes a full race against the rules-based Buddy, then one against the local model. After that, a guided first round on the live table, where Buddy explains each phase as it happens, using the lessons in `tts/flamme-rouge/tutorial.lua`.

Questions for the first spike:
- Can code sent through the External Editor API register the event handlers the agent needs, such as `onExternalMessage`, without a Save & Play, which would reload the table? The fallback is Save & Play, which is how the [M0 spike](m0-evidence.md) installed its handler on a disposable table.
- How reliably can the player's committed card be detected while it's face down, and when is it safe to read its value?
- How well can rider positions be read back if someone nudges a piece by hand?

Imperial Assault Skirmish is a later tactical candidate. Its unit abilities, line of sight and mission rules make it a larger adapter. [Official Skirmish Guide](https://www.fantasyflightgames.com/ffg_content/imperial-assault/support/SWI01_Skirmish%20Guide.pdf)
