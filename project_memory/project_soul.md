# Project Soul

> This file is the living identity of the project.

## Project Type

Local Windows AI companion for Tabletop Simulator.

## Vision

Let a player sit down with an AI opponent or teammate that follows the rules, takes its own turns and plays with the information available to its seat. Start with one two-player game in the host's existing Tabletop Simulator session. Grow towards more complex competitive, cooperative and campaign games through game-specific adapters.

## Principles

- Keep the Tabletop Simulator controller separate from the game rules and the AI player.
- Use deterministic rules and game state to check every model-proposed move.
- Give each player only the information their seat can see.
- Keep a human in control of starting, pausing and taking over a session.

## Key Decisions

- Start with the existing local TTS session. Test ChatGPT desktop control and a direct scripting bridge.
- The Git repository uses `main` as its default branch and `dev` for day-to-day work. Pull requests target `dev`, and `main` moves forward when `dev` is promoted.
- The proposed MVP scope and milestone gates live in the canonical roadmap.

## Maintained Pages

- [Product facts](domain/product-facts.md)
- [Contradictions](operations/contradictions.md)
- [MVP plan and roadmap](roadmap/improvement-plan.md)
