# Tutorial mode

Tutorial mode lets Buddy teach a new player a game one step at a time, right at the table. It's built so every game TTS Buddy supports can have one: the runner is shared, and each game only supplies its own lessons.

## How it plays

- Sit at White and press **Tutorial** on the table. Any match in progress is paused, and **Leave tutorial** takes you back to it.
- Each step shows a short piece of the rules. Some steps ask you to try a move with the normal hand buttons, on a small staged position. The table checks your move with the game's own rules and tells you how it went. A wrong move resets the position so you can have another go.
- Press **Next** to move on. Buddy can't play while the tutorial is open.
- If Buddy is running a local model, it adds a line explaining each step in its own words, shown under the lesson text as "Buddy: ...". With `--baseline` there's no model, so you get the lesson text on its own.

Signal Run has eight lessons: the goal, taking a turn, Charge, Boost, Jam, hidden information, running out of cards and a wrap-up. Charge, Boost and Jam are practice steps.

## How it fits together

| Part | What it does |
| --- | --- |
| `tts/tutorial.lua` | The game-agnostic runner: `register`, `start`, `view`, `next`, `attempt` and `setNote`. Its state is plain data, so it's saved with the table. |
| `tts/signal-run-tutorial.lua` | Signal Run's lessons, bundled into the Signal Run save by `npm run build`. Practice moves go through `Rules.play`. |
| `tts/flamme-rouge/tutorial.lua` | Flamme Rouge's lessons, ready for when its table lands. Practice moves go through the Flamme Rouge rules. |
| `tts/table.lua` | The **Tutorial**, **Next** and **Leave tutorial** buttons, the tutorial panel and the `teach` message. While a tutorial is open, an inspection reports status `tutorial` with the current step and no legal actions. |
| `src/tutor.js` | Builds the model prompt from the lesson text alone and checks the reply. |
| `src/session.js` | Asks the model for one explanation per step and sends it to the table. |

A few things keep the explanations honest:

- The lesson text is always on screen. Buddy's note sits beside it, labelled as Buddy's, never replacing it.
- The prompt gives the model only the step's title, text and hint, and asks it not to add anything.
- A note is one line of plain text, at most 240 characters. It's rejected if it uses a number that isn't in the lesson, which catches the most common slip ("Boost scores 3").
- The table escapes the note before putting it in the panel, and only accepts it for the step that's currently showing.
- If the model times out or its note is rejected, the step just shows the lesson text. Buddy doesn't pause or retry.

## Adding lessons for a new game

Register an ordered list of lessons with `Tutorial.register('<game-id>', lessons)`. Each lesson has:

- `id`, a short lower-case name such as `slipstream`.
- `title` and `text`. Keep the text under 400 characters, in British English and in your own words. Link to the official rules rather than copying them.
- Optionally `hint`, `setup` and `try` for a practice step. `setup()` returns a fresh practice position. `try(practice, action)` applies the move with the game's rules and returns `applied, outcome, feedback`, where outcome is `correct`, `wrong` (the position resets) or `continue` (a step on the way, such as drawing before choosing).

Add the game to the walkthrough in `test/tutorial.lua`, with a check for each practice step, and give the table a way to start the tutorial and send practice moves to `Tutorial.attempt`.

## Limits

- The number check can't catch everything. A model could still write numbers as words or paraphrase a rule badly, which is why the lesson text always stays on screen.
- Tutorial mode hasn't been tried live in Tabletop Simulator yet. See [validation](validation.md).
