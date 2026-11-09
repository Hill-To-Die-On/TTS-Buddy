# Project Soul

> This file is the living identity of the project.

## Project Type
Unknown

## Vision
Maintain a developer-centric multi-agent orchestrator that routes work safely across models, preserves long-term project memory, and makes autonomous execution reviewable inside VS Code.

## Principles
- Default to the safest reasonable behavior.
- Keep project knowledge structured, current, and reviewable.
- Prefer explicit approvals and traceable automation for risky work.
- Treat documentation, versioning, and release hygiene as part of correctness.

## Key Decisions
- Safety and security regressions are correctness bugs, not polish work.
- Long-term project context belongs in the SSOT under `project_memory/`.
- Provider credentials live in SecretStorage, not in project memory or source.
- `develop` is the routine integration branch and `master` is the protected release-ready branch.
- See `decisions/development-guardrails.md`, `operations/security-and-safety.md`, and `architecture/runtime-and-surfaces.md` for supporting detail.

## Maintained Pages
Pages kept current by hand, or by an agent in any tool, in the same change as the facts they record.
AtlasMind's import never overwrites a page listed here.
- domain/product-facts.md — what the product does, its limits, defaults, tiers and the decisions behind them
- operations/contradictions.md — open contradictions between Project Memory, docs and code, until resolved

## Imported References
- architecture/project-overview.md
- architecture/runtime-and-surfaces.md
- architecture/model-routing.md
- architecture/agents-and-skills.md
- operations/development-workflow.md
- decisions/development-guardrails.md
- roadmap/improvement-plan.md