# Skill Index — Single Source of Truth

**Purpose:** One canonical reference for all bigpowers skills. Referenced by README.md, RELEASE-PLAN.md, and CONVENTIONS.md. Updated per-release.

**Last updated:** 2026-05-20 (v2.1.0 — reconciled orphan/ghost skills; 44 active, 6 planned)

---

## Quick Navigation by BMAD Phase

| Phase | Active | Planned | Skills |
|---|---|---|---|
| **Bootstrap** | 1 | — | using-bigpowers |
| **Orchestrate** | 1 | — | orchestrate-project |
| **Discover** | 3 | — | survey-context, elaborate-spec, map-codebase |
| **Elaborate** | 5 | 1 | model-domain, define-language, grill-me, deepen-architecture, design-interface · _(grill-with-docs 📋)_ |
| **Plan** | 6 | 2 | assess-impact, change-request, define-success, plan-work, plan-refactor, plan-release · _(scope-work 📋, slice-tasks 📋)_ |
| **Spike** | 1 | — | spike-prototype |
| **Initiate** | 4 | — | kickoff-branch, guard-git, hook-commits, seed-conventions |
| **Build** | 5 | — | develop-tdd, enforce-first, delegate-task, dispatch-agents, execute-plan |
| **Harden** | 1 | — | wire-observability |
| **Bug** | 2 | 1 | investigate-bug, validate-fix · _(diagnose-root 📋)_ |
| **Review** | 4 | — | audit-code, request-review, respond-review, trace-requirement |
| **Integrate** | 2 | — | commit-message, release-branch |
| **Sustain** | 2 | — | inspect-quality, organize-workspace |
| **Utility** | 7 | 2 | terse-mode, craft-skill, edit-document, session-state, migrate-spec, visual-dashboard, write-document · _(setup-environment 📋, reset-baseline 📋)_ |
| **TOTAL** | **44** | **6** | |

---

## Full Reference Table

| # | Phase | Skill | Intent | Artefact Output | Status | Source |
|---|---|---|---|---|---|---|
| 1 | Bootstrap | `using-bigpowers` | Lifecycle intro; where to start | (dialogue) | ✅ Active | original |
| 2 | Orchestrate | `orchestrate-project` | Meta-skill enforcing 6-phase core loop (Standard / Fast-Track / Ad-Hoc modes) | (orchestration) | ✅ Active | original v2.0.0 |
| 3 | Discover | `survey-context` | Per-task context map; suggests next skill | (dialogue, update STATE.md) | ✅ Active | mattpocock/skills (zoom-out) |
| 4 | Discover | `elaborate-spec` | Dialogue to refine rough idea into spec | (dialogue) | ✅ Active | superpowers/brainstorming |
| 5 | Discover | `map-codebase` | High-fidelity codebase survey; stack, architecture, gray areas | CODEBASE-MAP.md | ✅ Active | original |
| 6 | Elaborate | `model-domain` | Interactive domain model; updates CONTEXT.md | CONTEXT.md, adr/ | ✅ Active | mattpocock/skills (domain-model) |
| 7 | Elaborate | `define-language` | Extract ubiquitous language glossary | UBIQUITOUS_LANGUAGE.md | ✅ Active | mattpocock/skills (ubiquitous-language) |
| 8 | Elaborate | `grill-me` | Stress-test design by grilling assumptions (Design mode + Docs mode) | (dialogue, refine design) | ✅ Active | mattpocock/skills (grill-me) |
| 9 | Elaborate | `grill-with-docs` | Grill assumptions grounded in real library docs | (dialogue, refine design) | 📋 Planned | mattpocock/skills (grill-with-docs) |
| 10 | Elaborate | `deepen-architecture` | Surface architecture deepening opportunities (Ousterhout deep modules) | (dialogue, update CONTEXT.md) | ✅ Active | mattpocock/skills (improve-codebase-architecture) |
| 11 | Elaborate | `design-interface` | Generate multiple radically different interface designs via parallel subagents | INTERFACE-OPTIONS.md | ✅ Active | original |
| 12 | Plan | `assess-impact` | Analyze blast radius of a proposed change before any code is written | IMPACT.md | ✅ Active | original |
| 13 | Plan | `change-request` | Add a new requirement or reorder epics by WSJF against RELEASE-PLAN.md | (updated RELEASE-PLAN.md) | ✅ Active | original |
| 14 | Plan | `scope-work` | Define what's in/out → SCOPE.md | SCOPE.md | 📋 Planned | mattpocock/skills (to-prd, adapted: local-first) |
| 15 | Plan | `slice-tasks` | Break work into vertical slices → TASKS.md | TASKS.md | 📋 Planned | mattpocock/skills (to-issues, adapted: local-first) |
| 16 | Plan | `define-success` | Convert imperative task to step → verify pairs | (dialogue, feed to plan-work) | ✅ Active | Karpathy principle |
| 17 | Plan | `plan-work` | Write detailed plan with verify steps | PLAN.md | ✅ Active | superpowers/writing-plans + Karpathy verify-template |
| 18 | Plan | `plan-refactor` | Plan a refactor via interview | REFACTOR.md | ✅ Active | mattpocock/skills (request-refactor-plan, adapted) |
| 19 | Plan | `plan-release` | Convert elaborated specs into a release plan with Gherkin acceptance criteria | RELEASE-PLAN.md | ✅ Active | original |
| 20 | Spike | `spike-prototype` | Throw-away spike for unknown problem spaces | SPIKE-<name>.md | ✅ Active | mattpocock/skills (prototype) |
| 21 | Initiate | `kickoff-branch` | Create worktree + branch + verify test baseline | (git state) | ✅ Active | superpowers/using-git-worktrees |
| 22 | Initiate | `guard-git` | Block dangerous git commands via pre-command hooks | (git state) | ✅ Active | mattpocock/skills (git-guardrails) |
| 23 | Initiate | `hook-commits` | Install pre-commit: lint, format, typecheck, test | (git state) | ✅ Active | mattpocock/skills (setup-pre-commit) |
| 24 | Initiate | `seed-conventions` | Generate CLAUDE.md + CONVENTIONS.md + specs/ scaffold | CLAUDE.md, CONVENTIONS.md, specs/ | ✅ Active | Akita "writing CLAUDE.md is a skill" |
| 25 | Build | `develop-tdd` | Red → green → refactor TDD loop | src/ (code) | ✅ Active | superpowers/tdd + mattpocock/tdd (override) |
| 26 | Build | `enforce-first` | F.I.R.S.T test-quality rubric (Fast, Independent, Repeatable, Self-Validating, Timely) | (checklist) | ✅ Active | Clean Code Ch.9 + Akita |
| 27 | Build | `delegate-task` | One subagent, one task, sequential + two-stage review | (code + review) | ✅ Active | superpowers/subagent-driven-development |
| 28 | Build | `dispatch-agents` | Multiple subagents in parallel on independent tasks | (code + review) | ✅ Active | superpowers/dispatching-parallel-agents |
| 29 | Build | `execute-plan` | Batch execute plan tasks sequentially with checkpoints | src/ (code per task) | ✅ Active | superpowers/executing-plans |
| 30 | Harden | `wire-observability` | Add structured JSON logging + idempotent setup + observability commands | CLAUDE.md (commands), src/ (logging) | ✅ Active | Akita "structured logging + idempotent setup" |
| 31 | Bug | `investigate-bug` | Investigate a bug → DIAGNOSIS.md | DIAGNOSIS.md | ✅ Active | mattpocock/skills (triage-issue, adapted: local-first) |
| 32 | Bug | `diagnose-root` | 4-phase root cause (reproduce → isolate → hypothesize → verify) | (dialogue, update DIAGNOSIS.md) | 📋 Planned | superpowers/systematic-debugging |
| 33 | Bug | `validate-fix` | Prove fix works: re-run suite, typecheck, lint | (dialogue, verify) | ✅ Active | superpowers/verification-before-completion |
| 34 | Review | `audit-code` | Self-review: CONVENTIONS.md compliance, SOLID, no `any`, test coverage | (checklist, pass/fail) | ✅ Active | superpowers/requesting-code-review + Clean Code |
| 35 | Review | `request-review` | Dispatch fresh reviewer agent (clean context, no shared state) | review-report (structured) | ✅ Active | original |
| 36 | Review | `respond-review` | Act on reviewer feedback: categorize (must/should), apply, verify | src/ (updated) | ✅ Active | superpowers/receiving-code-review |
| 37 | Review | `trace-requirement` | Link story IDs from RELEASE-PLAN.md to implementing code and tests | TRACEABILITY.md | ✅ Active | original |
| 38 | Integrate | `commit-message` | Draft Conventional Commits + semver prediction | (git message) | ✅ Active | mattpocock/skills (prepare-semantic-commit) |
| 39 | Integrate | `release-branch` | Merge/PR/keep/discard decision + worktree cleanup | (git PR created) | ✅ Active | superpowers/finishing-a-development-branch |
| 40 | Sustain | `inspect-quality` | Run structured QA session → BUG-LOG.md | BUG-LOG.md | ✅ Active | mattpocock/skills (qa, adapted: local-first) |
| 41 | Sustain | `organize-workspace` | Classify, show, confirm, then clean workspace | (filesystem state) | ✅ Active | mattpocock/skills (clean-my-room) |
| 42 | Utility | `terse-mode` | Fallback: ultra-terse output when context critically long | (prompt override) | ✅ Active | mattpocock/skills (caveman); fallback-only |
| 43 | Utility | `craft-skill` | Build a new bigpowers skill with proper structure | skills/<name>/SKILL.md | ✅ Active | superpowers/writing-skills + mattpocock/write-a-skill |
| 44 | Utility | `edit-document` | Edit and restructure a document in specs/ | specs/<name>.md | ✅ Active | mattpocock/skills (edit-article) |
| 45 | Utility | `session-state` | Track implementation decisions and progress in specs/STATE.md | STATE.md | ✅ Active | original |
| 46 | Utility | `migrate-spec` | Detect GSD/spec-kit/BMAD artifacts and transform to bigpowers specs/ format | specs/ (migrated artifacts) | ✅ Active | original v2.1.0 |
| 47 | Utility | `visual-dashboard` | Browser-based dashboard: architecture, plans, and UI mockups | (browser view) | ✅ Active | original |
| 48 | Utility | `write-document` | Write and sync high-integrity technical documents (BMAD methodology) | specs/<name>.md | ✅ Active | original |
| 49 | Utility | `setup-environment` | Pre-install deps, configure tools before work | (.env, installed packages) | 📋 Planned | autoresearch experiment |
| 50 | Utility | `reset-baseline` | Restore project to known state between runs | (clean working tree) | 📋 Planned | autoresearch experiment |

**Total: 50 rows — 44 ✅ Active, 6 📋 Planned.**

---

## Lifecycle Arc

```
[First time]
using-bigpowers → orchestrate-project (choose Standard / Fast-Track / Ad-Hoc)
                         ↓
survey-context → elaborate-spec → map-codebase
                         ↓
     model-domain / define-language / grill-me / design-interface / deepen-architecture
                         ↓
  assess-impact → change-request → define-success → plan-work / plan-refactor / plan-release
                         ↓
    kickoff-branch → guard-git / hook-commits / seed-conventions
                         ↓
       [Unknown domain?] spike-prototype → (learnings feed back to plan-work)
                         ↓
  develop-tdd (+ enforce-first) ←→ delegate-task / dispatch-agents / execute-plan
                         ↓
        wire-observability (production-readiness gate, any phase)
                         ↓
    investigate-bug → validate-fix
                         ↓
      audit-code → request-review → respond-review → trace-requirement
                         ↓
      commit-message → release-branch
                         ↓
        inspect-quality → organize-workspace (ongoing)

Transversal utilities (any phase):
  terse-mode, craft-skill, edit-document, session-state, migrate-spec, visual-dashboard, write-document
```

---

## Status Legend

| Icon | Meaning |
|---|---|
| ✅ Active | Implemented — SKILL.md exists, skill is usable |
| 📋 Planned | Designed or referenced, not yet implemented (no directory) |
| 🔄 Refactoring | Active but under revision |
| ⚠️ Deprecated | Will be removed in a future release |

## Naming Convention Notes

All skills follow `verb-noun` kebab-case (ADR-0001). Two documented exceptions:
- `terse-mode` — adjective-noun; retained for clarity (the verb form `enable-terse` is confusing)
- `visual-dashboard` — adjective-noun; retained for clarity (`view-dashboard` implies read-only)

## How to Update

1. Every new skill: add a row here before the skill is published.
2. Every rename: update the Skill column; add a note in the Added column.
3. Every phase change: update the Phase column.
4. After any change: bump the "Last updated" date and run `bash scripts/sync-skills.sh`.

→ verify: `find . -maxdepth 2 -name "SKILL.md" | grep -v ".git\|.cursor\|.gemini" | wc -l`
