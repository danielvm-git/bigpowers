# Release Plan: Agentic Compliance & Quality Roadmap

This document outlines the sequential strategy for building our model-judged compliance infrastructure and remediating codebase quality gaps.

Current audit score: **~93% (~83/89)** — estimated post-v1.16.0, Claude-judged, 2026-05-18.

## Release Sequence

Ordered by WSJF: (Business Value + Time Criticality + Risk Reduction) / Job Size.

| Release | Status | WSJF | Focus | Objective | Bump |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **v1.11.0** | ✅ | — | Benchmarks | Define compliance reference features (Gherkin benchmarks) | Minor |
| **v1.12.0** | ✅ | — | Auditor | Harden compliance harness + Clean Code Ch.17 remediation | Minor |
| **v1.12.1** | ✅ | 8.7 | Conventions | Harden CONVENTIONS.md: missing Ch.17 heuristics + test mandates | Patch |
| **v1.13.0** | ✅ | 7.3 | Harness | Falsification suites + `npm run compliance` integration | Minor |
| **v1.13.1** | ✅ | — | Skills | Fix execute-plan + plan-work: PLAN.md → RELEASE-PLAN.md | Patch |
| **v1.14.0** | ✅ | 5.0 | Karpathy | Behavioral mandates: ambiguity handling, loop-until-correct, pushback | Minor |
| **v1.15.0** | ✅ | 4.2 | Superpowers | Auto bootstrap, red-flag detection, quality threshold gate | Minor |
| **v1.16.0** | ✅ | 3.8 | Testing | F.I.R.S.T mandates: T4/T5/T8 explicit, Background: pre-conditions | Minor |
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

### v1.12.1: CONVENTIONS.md Hardening (WSJF 8.7) ✅
*Shipped a6bf36a. Estimated audit improvement: 75% → ~84%.*

Added to CONVENTIONS.md:
- Boy Scout Rule, G25 (named constants), G28 (boolean predicates), N7 (side-effect names)
- C5 (no commented-out code), G9/F4 (remove dead code), Exceptions over error codes
- T5 (boundary conditions), T8 (public interfaces only), Verify mandate

### v1.13.0: Harness Falsification + npm integration (WSJF 7.3) ✅
*Shipped 501e98b.*

- Added `npm run compliance` to `package.json` for one-command harness invocation.
- Added `specs/audit/falsification/harness-falsification.feature` — intentional FAIL fixture.
- Added `specs/audit/steps/then-this-step-always-fails.sh` — proves harness honours failures.
- File-based caching deferred: risk of stale verdicts outweighs benefit at current volume.

### v1.13.1: Skill correctness fix ✅
*Shipped d125789.*

- `execute-plan` and `plan-work` referenced non-existent `specs/PLAN.md`; corrected to `specs/RELEASE-PLAN.md` throughout.

### v1.14.0: Karpathy Behavioral Mandates (WSJF 5.0) ✅
*Shipped 6207082. karpathy.feature: 0/10 → 10/10 PASS.*

- `elaborate-spec`: present ≥2 interpretations when request is ambiguous before proceeding.
- `plan-work`: multiple interpretations gate in pre-flight; complexity pushback with forcing function.
- `validate-fix`: loop-until-all-green rule — return to step 1 if any check fails.
- `execute-plan`: behavioral correctness note — mechanical green ≠ behaviorally correct.
- 10 evidence scripts added to `specs/audit/steps/` for karpathy.feature.

### v1.15.0: Superpowers Gates (WSJF 4.2) ✅
*Shipped 3cdd81a. Audit gaps fixed: superpowers.feature gates.*

- **Auto bootstrap**: make session-state loading mandatory at session start — add to CLAUDE.md as a required first step, not opt-in.
- **Red-flag detection**: add a "red flag" self-check to `plan-work` and `audit-code` — agent must name any rationalization for skipping a gate.
- **94% quality threshold**: define a numeric quality score in `request-review` output; set 94% as the merge gate threshold.

### v1.16.0: Testing Mandates (WSJF 3.8) ✅
*Shipped. cleancode.feature Professional Testing: +3 PASS (T4/T5/T8). Total: 5→8 PASS.*

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
- Add `type:` (feat/fix/refactor) and `context:` (domain/infra) metadata fields to `specs/RELEASE-PLAN.md` templates.
- Provenance links: formalize ADR + commit SHA linkage in all plan artifacts.

### v1.20.0: Architectural Complexity (WSJF 1.8) ⏳
- Concurrency safety audit checklist (shared mutable state detection).
- Law of Demeter: add to `audit-code` checklist and CONVENTIONS.md.
- Module depth vs. interface breadth scoring in `deepen-architecture`.

### v1.21.0: Developer Ergonomics (WSJF 1.4) ⏳
- `terse-mode` token-reduction optimizations.
- Cold-start `handoff` utility: compact current session state for hand-off to a new agent context.
