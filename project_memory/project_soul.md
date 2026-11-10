# Project Soul

> This file is the living identity of the project.

## Project Type

Local Windows AI companion for Tabletop Simulator.

## Vision

Let a player sit down with an AI that joins their Tabletop Simulator game as an opponent, a teammate or a games master, depending on the game. Buddy follows the rules, takes its own turns and plays with the information available to its seat. It understands the game well enough to teach a new player, through step-by-step lessons or a guided first round or match. Start with one two-player game in the host's existing Tabletop Simulator session. Then grow towards joining existing Workshop games, competitive, cooperative and campaign, through game-specific adapters. Flamme Rouge on its existing Workshop table is the first test.

## Principles

- Keep the Tabletop Simulator controller separate from the game rules and the AI player.
- Use deterministic rules and game state to check every model-proposed move.
- Give each player only the information their seat can see.
- Keep a human in control of starting, pausing and taking over a session.
- Teach from the same rules Buddy plays by, so a lesson can never disagree with the game.

## Key Decisions

- Start with the existing local TTS session. Test ChatGPT desktop control and a direct scripting bridge.
- The Git repository uses `main` as its default branch and also has a `dev` branch.
- The proposed MVP scope and milestone gates live in the canonical roadmap.
- 2026-11-10: Buddy should eventually join any Workshop game rather than only tables built for it. Flamme Rouge is built against its existing Workshop table, not an original one.

## Maintained Pages

- [Product facts](domain/product-facts.md)
- [Contradictions](operations/contradictions.md)
- [MVP plan and roadmap](roadmap/improvement-plan.md)
