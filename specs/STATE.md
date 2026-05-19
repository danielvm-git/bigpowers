# Session State: Project Lifecycle Hardening

## Current Milestone

Bigpowers 2.0 orchestration framework complete. Deployed: v2.0.0 reference library + orchestrate meta-skill.
Next: v1.19.0 — Taxonomy metadata (type/context fields, provenance links).

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
- [x] v1.14.0 — Karpathy behavioral mandates: interpretations gate, loop-until-correct, complexity pushback; 10 evidence scripts (karpathy.feature 10/10 PASS)
- [x] v1.15.0 — Superpowers gates: mandatory session bootstrap in CLAUDE.md, red-flag self-check in plan-work + audit-code, 94% merge threshold in request-review

- [x] v1.16.0 — Testing mandates: T4/T5/T8 in CONVENTIONS.md + develop-tdd checklist, Background: blocks in cleancode + akita features; +3 PASS (5→8)
- [x] v1.17.0 — Guardrails: zoom-out mandate + surgical changes discipline
- [x] v1.18.0 — Execution loop hardening: decision logging + minimal brief discipline
- [x] v2.0.0 — Reference library (11 docs, 2,572 lines) + orchestrate meta-skill (6-phase core loop)

## Pending Releases

- [ ] v1.19.0 — Taxonomy metadata (type/context fields, provenance links) ← **next**
- [ ] v1.20.0 — Architectural complexity (Demeter, concurrency, module depth)
- [ ] v1.21.0 — Developer ergonomics (terse-mode, cold-start handoff)
- [ ] v2.1.0 — Orchestration Phases 3-5 (context isolation, security gates, testing)

## Project Capabilities

- **Remediated Clean Code References**: High-fidelity source code examples (ComparisonCompactor, DayDate) resolving Chapter 17 smells.
- **Gherkin Compliance Features**: Authoritative benchmarks for Akita, Karpathy, Clean Code, Pocock, BMAD, and Superpowers.
- **Agentic Compliance Harness**: Binary step-script harness + `npm run compliance` for one-command auditing.
- **Harness Falsification**: Intentional FAIL fixture proves harness honours failures.
- **Skill Consolidation**: plan-release, change-request, assess-impact, trace-requirement added; scope-work, slice-tasks, diagnose-root, grill-with-docs removed.
- **Git-Worktree Lifecycle**: Robust kickoff/release and automated cleanup scripts.
- **Session State Management**: Persistent tracking of project lifecycle phase and git metadata.

## Active Decisions

- **RELEASE-PLAN.md is the single planning artifact** — specs/PLAN.md is retired; plan-work appends to RELEASE-PLAN.md.
- **One plan file per release** — specs/PLAN-vX.Y.Z.md for each upcoming release.
- **Mandatory session start**: read CLAUDE.md → CONVENTIONS.md → specs/STATE.md → specs/RELEASE-PLAN.md before any task.

## Audit Score Tracking

| Version | Score | Notes |
|---------|-------|-------|
| v1.12.0 baseline | ~75% (67/89) | First measured score |
| v1.12.1 | ~84% (~75/89) | +9 from CONVENTIONS.md heuristics |
| v1.14.0 | ~87% (~77/89) | +3 from karpathy.feature (10/10 PASS) |
| v1.15.0 | ~90–91% (~80–81/89) | +3–4 from superpowers.feature gates |
| v1.16.0 | ~93% (~83/89) | +3 from cleancode.feature T4/T5/T8 (5→8 PASS) |
| v1.17.0 | ~94% (~84/89) | +1 from guardrails (zoom-out mandate, module understanding) |
| v1.18.0 | ~94% (~84/89) | +0 (decision logging internal; no external fixes) |
| v2.0.0 | ~94% (~84/89) | +0 (reference/guidance; enforcement via v2.1+) |
