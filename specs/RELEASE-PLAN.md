# Release Plan: Agentic Compliance & Quality Roadmap

This document outlines the sequential strategy for building our model-judged compliance infrastructure and remediating codebase quality gaps.

Current audit score: **~94% (~84/89)** — post-v2.0.0, deployed 2026-05-18.

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
| **v1.17.0** | ✅ | 3.2 | Guardrails | Zoom-out mandate + surgical-changes discipline | Minor |
| **v1.18.0** | ✅ | 2.8 | Execution | Decision logging + minimal brief discipline into execution loop | Minor |
| **v2.0.0** | ✅ | — | Framework | Reference library (11 docs) + orchestrate meta-skill (6-phase) | Major |
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

### v1.17.0: Guardrails & Safety (WSJF 3.2) ✅
*Shipped c2ee71b.*

- **Zoom-out mandate**: Hard-gate in `plan-work/SKILL.md` requiring purpose/callers/contracts analysis before modifying any module. Prevents accidental blast radius and enforces module understanding.
- **Surgical changes discipline**: Audit checklist in `audit-code/SKILL.md` ensuring modifications are strictly scoped — only code strictly required for the task is touched; no speculative cleanup.

### v1.18.0: Execution Loop Hardening (WSJF 2.8) ✅
*Shipped 9619068.*

**Implementation note:** Scope shifted from planned "BMAD lifecycle + issue tracker" to execution loop hardening based on priority assessment.

- **Decision logging**: `execute-plan/SKILL.md` now logs non-obvious decisions to `STATE.md` after verify passes. Prevents agent amnesia and enables audit trail of why decisions were made.
- **Brief discipline**: `dispatch-agents/SKILL.md` and `delegate-task/SKILL.md` enforce minimal brief template and require reading existing `STATE.md` before writing new briefs. Reduces per-agent token cost while maintaining traceability.
- **Traceability**: Closes decision-to-code gap in execution chain; agents start cold but inherit prior decisions; decisions → code flow becomes auditable.
- Files changed: 12 total (6 skill sources + 6 generated artifacts for Cursor/Gemini).

### v2.0.0: Reference Library & Orchestration Framework ✅
*Shipped bc9b437.*

- **Orchestrate meta-skill**: Enforces 6-phase core loop (discover → elaborate → plan → build → verify → release) with hard gates. Three operational modes: Standard (enforce all gates), Fast-track (conditional skips), Ad-hoc (legacy). Coordinates multi-phase projects with guaranteed quality checkpoints.
- **Reference library** (11 comprehensive documents, 2,572 lines total):
  - `orchestration.md` (343 lines): 6-phase model, gates, checkpoints, mode specifications
  - `gates.md` (137 lines): Four gate types (Confirm, Quality, Safety, Transition) with decision logic
  - `checkpoints.md` (194 lines): Checkpoint types and integration strategy
  - `tdd.md` (314 lines): F.I.R.S.T principles, TDD workflow with code examples
  - `verification-patterns.md` (316 lines): Verification patterns for code, docs, configs, plans
  - `git-integration.md` (329 lines): Commit strategy, worktrees, hooks, merge patterns
  - `code-review.md` (173 lines): Clean Code heuristics, reviewer checklist, review patterns
  - `security-threats.md` (183 lines): STRIDE threat model, slopcheck verdicts, security gates
  - `model-profiles.md` (205 lines): Model assignments (Haiku/Sonnet/Opus), token budgets, context sizing
  - `thinking-models.md` (205 lines): Extended thinking patterns, use cases, when to use each model
  - `domain-probes.md` (173 lines): Domain-specific grill-me questions, domain probe library
- **Artifact synchronization**: 42 skills now synced to `.cursor/rules` and `.gemini/extensions/bigpowers`
- **Status**: Phase 1-2 complete (reference library + orchestrate skill). Phases 3-5 (context isolation, security gates, testing) deferred to v2.1.0+

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

---

## Audit Score Tracking

| Version | Score | Notes |
|---------|-------|-------|
| v1.12.0 baseline | ~75% (67/89) | First measured score |
| v1.12.1 | ~84% (~75/89) | +9 from CONVENTIONS.md heuristics (Boy Scout, G25, G28, N7, C5, G9/F4, T5, T8, verify) |
| v1.14.0 | ~87% (~77/89) | +3 from karpathy.feature (10/10 PASS) behavioral mandates |
| v1.15.0 | ~90–91% (~80–81/89) | +3–4 from superpowers.feature gates (bootstrap, red-flag, 94% threshold) |
| v1.16.0 | ~93% (~83/89) | +3 from cleancode.feature T4/T5/T8 testing mandates (5→8 PASS) |
| v1.17.0 | ~94% (~84/89) | +1 from guardrails discipline (zoom-out mandate, module understanding) |
| v1.18.0 | ~94% (~84/89) | +0 (decision logging is internal; no external heuristic fixes) |
| v2.0.0 | ~94% (~84/89) | +0 (reference library + orchestrate are guidance/framework; enforcement comes v2.1+) |
| **Current** | **~94%** | **Next enforcement lift: v1.19.0+ Taxonomy metadata** |
