# Contradictions

> Maintained page. When Project Memory, the docs and the code disagree, and the agent that noticed cannot
> settle it in the same change (out of scope, or unclear which side is right), it is recorded here so it
> is resolved rather than lost. AtlasMind lists the open entries in `index/import-freshness.md`, at
> start-up, and in its own chat context. Never record secrets here.

One line per contradiction, newest first, in this shape:

```
- [ ] YYYY-MM-DD — what disagrees — `path/a` says X; `path/b` says Y — why it was not settled — found by (tool)
- [x] YYYY-MM-DD — what disagreed — settled: which side was right, and what changed
```

Tick the box and move the line to Resolved once it is settled.

## Open

- [ ] 2026-11-10 — whether the companion source and built save may be published yet — `docs/pilot.md` keeps the package local "pending written clarification" and asks Berserk Games whether testers can receive the JSON save and companion source; `project_memory/domain/product-facts.md` defers external sharing. But the public GitHub repo (`dev` since before 2026-11-10, `main` from 2026-11-10) already contains `src/` and the built `tts/Signal Run.json` — needs The User's ruling on whether a public repo counts as "sharing" for the EULA review, or whether the repo should be private until then — found by Claude Code

## Resolved
