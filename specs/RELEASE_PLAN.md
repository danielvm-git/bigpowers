# Release Plan: Agentic Compliance & Quality Roadmap

This document outlines the sequential strategy for building our model-judged compliance infrastructure and remediating codebase quality gaps.

Current audit score: **75% (67/89)** — Claude-judged, 2026-05-18.

## Release Sequence

Ordered by WSJF: (Business Value + Time Criticality + Risk Reduction) / Job Size.

| Release | Status | WSJF | Focus | Objective | Bump |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **v1.11.0** | ✅ | — | Benchmarks | Define compliance reference features (Gherkin benchmarks) | Minor |
| **v1.12.0** | ✅ | — | Auditor | Harden compliance harness + Clean Code Ch.17 remediation | Minor |
| **v1.12.1** | ⏳ | 8.7 | Conventions | Harden CONVENTIONS.md: missing Ch.17 heuristics + test mandates | Patch |
| **v1.13.0** | ⏳ | 7.3 | Harness | Falsification suites + `npm run compliance` integration | Minor |
| **v1.14.0** | ⏳ | 5.0 | Karpathy | Behavioral mandates: ambiguity handling, loop-until-correct, pushback | Minor |
| **v1.15.0** | ⏳ | 4.2 | Superpowers | Auto bootstrap, red-flag detection, quality threshold gate | Minor |
| **v1.16.0** | ⏳ | 3.8 | Testing | F.I.R.S.T mandates: T4/T5/T8 explicit, Background: pre-conditions | Minor |
| **v1.17.0** | ⏳ | 3.2 | Guardrails | "Zoom-out" before modify + surgical-changes discipline | Minor |
| **v1.18.0** | ⏳ | 2.8 | Lifecycle | BMAD phase model (discover → sustain) + issue tracker integration | Minor |
| **v1.19.0** | ⏳ | 2.1 | Taxonomy | Metadata standards: Provenance, Type, Context in plans | Minor |
| **v1.20.0** | ⏳ | 1.8 | Complexity | Concurrency safety, Law of Demeter, module depth audit | Minor |
| **v1.21.0** | ⏳ | 1.4 | Ergonomics | Terse-mode optimization & cold-start handoff utility | Minor |

---

## Detailed Action Items

### v1.11.0: Compliance Reference Features ✅
- Created authoritative Gherkin benchmarks for: Akita, Karpathy, Clean Code, Pocock, BMAD, and Superpowers.

### v1.12.0: Compliance Auditor Stabilization ✅
- Added `--judge` (binary/gemini) and `--model` flags to `audit-compliance.sh`.
- Clean Code Chapter 17 initial remediation: G29, G34, T-series heuristics.
- Added `audit-code/HEURISTICS.md` and `references/` canonical Java examples.
- Skill consolidation: plan-release, change-request, assess-impact, trace-requirement added; scope-work, slice-tasks, diagnose-root, grill-with-docs removed.

### v1.12.1: CONVENTIONS.md Hardening (WSJF 8.7) ⏳
*Audit gaps fixed: ~8 fails → passes. Highest score-per-effort of any remaining release.*

Missing from CONVENTIONS.md that features test directly:
- **Boy Scout Rule**: mandate leaving every file touched at least as clean as found
- **Exceptions over error codes**: mandate exceptions, prohibit numeric return codes for errors
- **C5**: prohibit commented-out code (remove or delete, never comment out)
- **G9 / F4**: mandate removal of dead code and unused functions
- **G25**: prohibit magic strings and numbers; require named constants
- **G28**: complex boolean logic must be encapsulated in named functions
- **N7**: function names must describe side-effects (not just intent)
- **T5**: boundary conditions must be exhaustively tested
- **T8**: tests must verify behavior through public interfaces, not implementation details
- **Verify mandate**: every change must be verifiable with a runnable command (move from plan-work into CONVENTIONS.md)

### v1.13.0: Harness Falsification + npm integration (WSJF 7.3) ⏳
- Implement "Falsification" tests: intentionally broken scripts must trigger FAIL.
- Add `npm run compliance` command in `package.json` for full harness invocation.
- Add file-based caching to prevent redundant LLM calls on unchanged evidence.

### v1.14.0: Karpathy Behavioral Mandates (WSJF 5.0) ⏳
*Audit gaps fixed: 3 karpathy.feature fails.*

- **Multiple interpretations**: when a request is ambiguous, present ≥2 interpretations before proceeding — add to `elaborate-spec` and `plan-work` as a mandatory step.
- **Loop-until-correct**: add explicit "loop until behavioral correctness is verified" discipline to `validate-fix` and `execute-plan`.
- **Pushback on complexity**: add "complexity pushback" gate to `plan-work` — flag any plan step that introduces abstraction without a clear forcing function.

### v1.15.0: Superpowers Gates (WSJF 4.2) ⏳
*Audit gaps fixed: 4 superpowers.feature fails.*

- **Auto bootstrap**: make session-state loading mandatory at session start — add to CLAUDE.md as a required first step, not opt-in.
- **Red-flag detection**: add a "red flag" self-check to `plan-work` and `audit-code` — agent must name any rationalization for skipping a gate.
- **94% quality threshold**: define a numeric quality score in `request-review` output; set 94% as the merge gate threshold.

### v1.16.0: Testing Mandates (WSJF 3.8) ⏳
*Audit gaps fixed: 3 cleancode.feature testing fails.*

- **T4 (Ignored Tests)**: add explicit prohibition on ignored tests without ambiguity note — to CONVENTIONS.md and `develop-tdd`.
- **T5 (Boundary Conditions)**: mandate boundary testing in `develop-tdd` checklist and CONVENTIONS.md.
- **T8 (Public Interface Only)**: explicitly prohibit testing implementation details — add to CONVENTIONS.md.
- **Background: pre-conditions**: refactor feature files to include mandatory `Background:` blocks.

### v1.17.0: Guardrails & Safety (WSJF 3.2) ⏳
- **Zoom-out mandate**: before modifying any module, agent must explain the module's purpose and its callers — add as HARD-GATE step to `plan-work` and `investigate-bug`.
- **Surgical changes discipline**: formalize "touch only what is required" as an audit checklist item in `audit-code`.

### v1.18.0: BMAD Lifecycle + Issue Tracker (WSJF 2.8) ⏳
- **Phase model**: document the discover → elaborate → plan → build → sustain lifecycle explicitly in CONVENTIONS.md or a new `specs/LIFECYCLE.md`.
- **Issue tracker**: add `to-issues` skill to push specs/TASKS.md or RELEASE-PLAN.md stories to GitHub Issues.

### v1.19.0: Taxonomy Metadata (WSJF 2.1) ⏳
- Add `type:` (feat/fix/refactor) and `context:` (domain/infra) metadata fields to `specs/PLAN.md` and `specs/RELEASE-PLAN.md` templates.
- Provenance links: formalize ADR + commit SHA linkage in all plan artifacts.

### v1.20.0: Architectural Complexity (WSJF 1.8) ⏳
- Concurrency safety audit checklist (shared mutable state detection).
- Law of Demeter: add to `audit-code` checklist and CONVENTIONS.md.
- Module depth vs. interface breadth scoring in `deepen-architecture`.

### v1.21.0: Developer Ergonomics (WSJF 1.4) ⏳
- `terse-mode` token-reduction optimizations.
- Cold-start `handoff` utility: compact current session state for hand-off to a new agent context.
