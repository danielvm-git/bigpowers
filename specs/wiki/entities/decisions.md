# Decisions Synthesis

Narrative summary of architecture decisions. Authoritative source remains `specs/adr/` — this page links and synthesizes only.

## Naming and discoverability

[[../../adr/0001-verb-noun-naming.md|ADR-0001]] — All skills use `verb-noun` kebab-case (`develop-tdd`, `plan-work`). Exceptions (`terse-mode`, `visual-dashboard`) are documented in CONVENTIONS.md. Enables grep-ability: skill names return fewer than five hits.

## Local-first planning

[[../../adr/0002-local-first-specs.md|ADR-0002]] — All planning output lives in `specs/` as git-tracked Markdown. No core skill reads external issue trackers. Trade-off: no sprint boards; full offline agent context and `git blame` audit trail.

## Prescriptive lifecycle

[[../../adr/0003-prescriptive-core-loop.md|ADR-0003]] — Six phases (discover → elaborate → plan → build → verify → release) enforced via `orchestrate-project`. Modes: Standard (all gates), Fast-track (data-driven skips), Ad-hoc (no enforcement).

## Context isolation (pending v2.4.0)

[[../../adr/0004-context-isolation.md|ADR-0004]] — Fresh context window per skill spawn; orchestrator passes explicit file list; continuity via [[../../STATE.md]] not conversation replay.

## Hard gates

[[../../adr/0005-hard-gate-mandate.md|ADR-0005]] — Critical transitions use `> **HARD GATE**` blockquotes with `→ verify:` shell commands. Skips must be logged in STATE.md with explicit rationale.

## Model routing (pending v2.4.0)

[[../../adr/0006-model-routing.md|ADR-0006]] — Haiku / Sonnet / Opus tiers by task complexity; declared in SKILL.md frontmatter; orchestrator enforces assignment.

## Cross-cutting themes

- **Specs as memory:** Operational files ([[../../STATE.md]], [[../../RELEASE-PLAN.md]]) hold current truth; wiki compiles understanding without replacing checkboxes.
- **Verification over prose:** Gates are testable commands, not “please remember to review.”
- **Solo-git:** [[../../../profiles/solo-git.md]] — land via `scripts/land-branch.sh` after release-branch gates.

## Related

- [[../../CONTEXT.md]] — Project constitution
- [[../synthesis/open-questions.md]] — Unresolved tensions
