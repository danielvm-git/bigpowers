# Session State: bigpowers

## Current Milestone

v2.1.0 — Repo Health. Documentation refactoring complete: specs/ restructured, SKILL-INDEX.md
reconciled (44 active, 6 planned), RELEASE-PLAN.md renumbered and reordered by WSJF.
Next: v2.2.0 — Supply-Chain Security (slopcheck integration).

## Git Metadata

- **Branch**: main
- **Hash**: bc9b437

## Completed Releases

- [x] v1.9.0 — Git-worktree lifecycle hardening (kickoff/release scripts)
- [x] v1.11.0 — Gherkin compliance benchmarks (Akita, Karpathy, Clean Code, Pocock, BMAD, Superpowers)
- [x] v1.12.0 — Compliance harness hardening + Clean Code Ch.17 remediation
- [x] v1.12.1 — CONVENTIONS.md: 10 missing heuristics (Boy Scout, G25, G28, N7, C5, G9/F4, T5, T8, verify mandate)
- [x] v1.13.0 — Harness falsification suites + `npm run compliance`
- [x] v1.13.1 — execute-plan + plan-work: PLAN.md → RELEASE-PLAN.md fix
- [x] v1.14.0 — Karpathy behavioral mandates: interpretations gate, loop-until-correct, complexity pushback
- [x] v1.15.0 — Superpowers gates: mandatory session bootstrap, red-flag self-check, 94% merge threshold
- [x] v1.16.0 — Testing mandates: T4/T5/T8 in CONVENTIONS.md + develop-tdd; cleancode.feature 5→8 PASS
- [x] v1.17.0 — Guardrails: zoom-out mandate + surgical changes discipline
- [x] v1.18.0 — Execution loop hardening: decision logging + minimal brief discipline
- [x] v2.0.0 — Reference library (11 docs) + orchestrate-project meta-skill (6-phase core loop)
- [x] v2.1.0 — Repo Health: specs/ restructure, 6 ADRs, SKILL-INDEX reconciliation, RELEASE-PLAN reorder

## Pending Releases

See `specs/RELEASE-PLAN.md` for full detail and success criteria.

- [ ] v2.2.0 — Supply-Chain Security (slopcheck) ← **next**
- [ ] v2.3.0 — Developer Ergonomics (handoff skill, terse-mode hardening)
- [ ] v2.4.0 — Context Isolation + Model Routing
- [ ] v2.5.0 — Taxonomy & Provenance
- [ ] v2.6.0 — Architectural Complexity (Demeter, Module Depth)
- [ ] v2.7.0 — Wave-Based Parallel Execution
- [ ] v3.0.0 — AI Capability Tier (Semantic Search, Skill Composition, etc.)

## Active Decisions

- **RELEASE-PLAN.md is the single planning artifact** — plan-work writes to RELEASE-PLAN.md; no separate PLAN.md.
- **Mandatory session start**: CLAUDE.md → CONVENTIONS.md → specs/STATE.md → specs/RELEASE-PLAN.md.
- **specs/ is the single output location** — all plans, investigations, and documents go in specs/.
- **Audit score table** lives in RELEASE-PLAN.md only — not duplicated here.
