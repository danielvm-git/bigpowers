# Skill Index — Single Source of Truth

**Purpose:** One canonical reference for all 38 bigpowers skills. Referenced by README.md, RELEASE-PLAN.md, and CONVENTIONS.md. Updated per-release.

**Last updated:** 2026-05-19 (v1.17.0 — added 6 missing skills + 2 experiment skills)

---

## Quick Navigation by BMAD Phase

| Phase | Count | Skills |
|---|---|---|
| **Discover** | 2 | survey-context, elaborate-spec |
| **Elaborate** | 7 | model-domain, define-language, challenge-design, grill-me, grill-with-docs, deepen-architecture |
| **Plan** | 7 | scope-work, slice-tasks, define-success, plan-work, plan-refactor |
| **Spike** | 1 | spike-prototype |
| **Initiate** | 4 | kickoff-branch, guard-git, hook-commits, seed-conventions |
| **Build** | 5 | develop-tdd, enforce-first, delegate-task, dispatch-agents, execute-plan |
| **Harden** | 1 | wire-observability |
| **Bug** | 3 | investigate-bug, diagnose-root, validate-fix |
| **Review** | 3 | audit-code, request-review, respond-review |
| **Integrate** | 2 | commit-message, release-branch |
| **Sustain** | 2 | inspect-quality, organize-workspace |
| **Utility (any phase)** | 5 | terse-mode, craft-skill, edit-document, setup-environment, reset-baseline |
| **Bootstrap (one-time)** | 1 | using-bigpowers |
| **TOTAL** | **44** | |

---

## Full Reference Table

| # | Phase | Skill | Intent | Artefact Output | Status | Source | Added |
|---|---|---|---|---|---|---|---|
| 1 | Bootstrap | `using-bigpowers` | Lifecycle intro; where to start | (dialogue) | ✅ Active | (original) | v1.14.0 |
| 2 | Discover | `survey-context` | Per-task context map; suggests next skill | (dialogue, update STATE) | ✅ Active | mattpocock/skills (zoom-out) | v1.0.0 |
| 3 | Discover | `elaborate-spec` | Dialogue to refine rough idea into spec | (dialogue) | ✅ Active | superpowers/brainstorming | v1.0.0 |
| 4 | Elaborate | `model-domain` | Interactive domain model; updates CONTEXT.md | CONTEXT.md, adr/ | ✅ Active | mattpocock/skills (domain-model) | v1.0.0 |
| 5 | Elaborate | `define-language` | Extract ubiquitous language glossary | UBIQUITOUS_LANGUAGE.md | ✅ Active | mattpocock/skills (ubiquitous-language) | v1.0.0 |
| 6 | Elaborate | `challenge-design` | Stress-test plan by grilling assumptions | (dialogue, refine design) | ✅ Active | mattpocock/skills (grill-me) | v1.0.0 |
| 7 | Elaborate | `grill-with-docs` | Grill assumptions grounded in real library docs | (dialogue, refine design) | ✅ Active | mattpocock/skills (grill-with-docs) | v1.14.0 |
| 8 | Elaborate | `deepen-architecture` | Surface architecture deepening opportunities | (dialogue, update CONTEXT.md) | ✅ Active | mattpocock/skills (improve-codebase-architecture) | v1.0.0 |
| 9 | Plan | `scope-work` | Define what's in/out → SCOPE.md | SCOPE.md | ✅ Active | mattpocock/skills (to-prd, adapted: local-first) | v1.0.0 |
| 10 | Plan | `slice-tasks` | Break work into vertical slices → TASKS.md | TASKS.md | ✅ Active | mattpocock/skills (to-issues, adapted: local-first) | v1.0.0 |
| 11 | Plan | `define-success` | Convert imperative task to step → verify pairs | (dialogue, feed to plan-work) | ✅ Active | Karpathy principle | v1.14.0 |
| 12 | Plan | `plan-work` | Write detailed plan with verify steps | PLAN.md | ✅ Active | superpowers/writing-plans + Karpathy verify-template | v1.0.0 |
| 13 | Plan | `plan-refactor` | Plan a refactor via interview | REFACTOR.md | ✅ Active | mattpocock/skills (request-refactor-plan, adapted) | v1.0.0 |
| 14 | Spike | `spike-prototype` | Throw-away spike for unknown problem spaces | SPIKE-<name>.md | ✅ Active | mattpocock/skills (prototype) | v1.14.0 |
| 15 | Initiate | `kickoff-branch` | Create worktree + branch + verify test baseline | (git state) | ✅ Active | superpowers/using-git-worktrees | v1.0.0 |
| 16 | Initiate | `guard-git` | Install pre-command hooks blocking destructive git | (git state) | ✅ Active | mattpocock/skills (git-guardrails) | v1.0.0 |
| 17 | Initiate | `hook-commits` | Install pre-commit: lint, format, typecheck, test | (git state) | ✅ Active | mattpocock/skills (setup-pre-commit) | v1.0.0 |
| 18 | Initiate | `seed-conventions` | Generate CLAUDE.md + CONVENTIONS.md + specs/ | CLAUDE.md, CONVENTIONS.md, specs/ | ✅ Active | Akita "writing CLAUDE.md is a skill" | v1.14.0 |
| 19 | Build | `develop-tdd` | Red → green → refactor TDD loop | src/ (code) | ✅ Active | superpowers/tdd + mattpocock/tdd (override) | v1.0.0 |
| 20 | Build | `enforce-first` | F.I.R.S.T test-quality rubric (Fast, Independent, Repeatable, Self-Validating, Timely) | (dialogue, checklist) | ✅ Active | Clean Code Ch.9 + Akita | v1.14.0 |
| 21 | Build | `delegate-task` | One subagent, one task, sequential + two-stage review | (code + review) | ✅ Active | superpowers/subagent-driven-development | v1.0.0 |
| 22 | Build | `dispatch-agents` | Multiple subagents in parallel on independent tasks | (code + review) | ✅ Active | superpowers/dispatching-parallel-agents | v1.0.0 |
| 23 | Build | `execute-plan` | Batch execute plan tasks sequentially with checkpoints | src/ (code per task) | ✅ Active | superpowers/executing-plans | v1.0.0 |
| 24 | Harden | `wire-observability` | Add structured JSON logging + idempotent setup + observability commands | CLAUDE.md (commands), src/ (logging) | ✅ Active | Akita "structured logging + observable + idempotent setup" | v1.14.0 |
| 25 | Bug | `investigate-bug` | Investigate a bug → DIAGNOSIS.md | DIAGNOSIS.md | ✅ Active | mattpocock/skills (triage-issue, adapted: local-first) | v1.0.0 |
| 26 | Bug | `diagnose-root` | 4-phase root cause (reproduce → isolate → hypothesize → verify) | (dialogue, update DIAGNOSIS.md) | ✅ Active | superpowers/systematic-debugging | v1.0.0 |
| 27 | Bug | `validate-fix` | Prove fix works: re-run suite, typecheck, lint | (dialogue, verify) | ✅ Active | superpowers/verification-before-completion | v1.0.0 |
| 28 | Review | `audit-code` | Self-review: CONVENTIONS.md compliance, SOLID, no `any`, test coverage | (checklist, pass/fail) | ✅ Active | superpowers/requesting-code-review + Clean Code | v1.0.0 |
| 29 | Review | `request-review` | Dispatch fresh reviewer agent (clean context, no shared state) | review-report (structured) | ✅ Active | (gap-filler; new) | v1.14.0 |
| 30 | Review | `respond-review` | Act on reviewer feedback: categorize (must/should), apply, verify | src/ (updated) | ✅ Active | superpowers/receiving-code-review | v1.0.0 |
| 31 | Integrate | `commit-message` | Draft Conventional Commits + semver prediction | (git message) | ✅ Active | mattpocock/skills (prepare-semantic-commit) | v1.0.0 |
| 32 | Integrate | `release-branch` | Merge/PR/keep/discard decision + worktree cleanup | (git PR created) | ✅ Active | superpowers/finishing-a-development-branch | v1.0.0 |
| 33 | Sustain | `inspect-quality` | Run structured QA session → BUG-LOG.md | BUG-LOG.md | ✅ Active | mattpocock/skills (qa, adapted: local-first) | v1.0.0 |
| 34 | Sustain | `organize-workspace` | Classify, show, confirm, then clean workspace | (filesystem state) | ✅ Active | mattpocock/skills (clean-my-room) | v1.0.0 |
| 35 | Utility | `terse-mode` | Fallback: ultra-terse output when context critically long | (dialogue, prompt override) | ✅ Active | mattpocock/skills (caveman); repositioned as fallback-only | v1.14.0 |
| 36 | Utility | `craft-skill` | Build a new bigpowers skill with proper structure | skills/<name>/SKILL.md | ✅ Active | superpowers/writing-skills + mattpocock/write-a-skill (merged) | v1.0.0 |
| 37 | Utility | `edit-document` | Edit and restructure a document in specs/ | specs/<name>.md | ✅ Active | mattpocock/skills (edit-article) | v1.0.0 |
| 38 | Utility | `setup-environment` | Pre-install deps, configure tools before work | (.env, installed packages) | ✅ Active | autoresearch experiment | v1.17.0 |
| 39 | Utility | `reset-baseline` | Restore project to known state between runs | (clean working tree) | ✅ Active | autoresearch experiment | v1.17.0 |

**Total: 44 skills listed. Version check: compare row count to v1.17.0 baseline (44).**

---

## Lifecycle Arc (Text)

```
[First time only]
using-bigpowers (intro to skills system)
                    ↓
survey-context → elaborate-spec → model-domain / define-language
                    ↓
    challenge-design / grill-with-docs → deepen-architecture
                    ↓
        scope-work → slice-tasks → define-success
                    ↓
              plan-work / plan-refactor
                    ↓
    kickoff-branch → guard-git / hook-commits / seed-conventions
                    ↓
        [Unknown domain?] spike-prototype → (learnings feed back to plan-work)
                    ↓
  develop-tdd (+ enforce-first) ←→ delegate-task / dispatch-agents / execute-plan
                    ↓
        wire-observability (production-readiness gate, any phase)
                    ↓
    investigate-bug → diagnose-root → validate-fix
                    ↓
      audit-code → request-review → respond-review
                    ↓
      commit-message → release-branch
                    ↓
        inspect-quality → organize-workspace (ongoing)

Transversal utilities (any phase): terse-mode, craft-skill, edit-document, setup-environment, reset-baseline
```

---

## Sourcing & Lineage

### Base Frameworks

- **superpowers (obra):** 14 core implementation skills (TDD, delegation, review loop)
  - Mapped: develop-tdd, delegate-task, dispatch-agents, execute-plan, audit-code, request-review, respond-review, commit-message, release-branch, plan-work, investigate-bug, validate-fix, kickoff-branch, craft-skill
  - **Newly added**: challenge-design, grill-with-docs, scope-work, slice-tasks, diagnose-root, setup-environment, reset-baseline
- **mattpocock/skills:** 18 discovery and planning skills (domain modeling, scope, triage)
- **Akita (akitaonrails):** Clean Code re-ranked for agents (F.I.R.S.T, structured logging, idempotent setup)
- **Karpathy (andrej-karpathy-skills):** Four behavioral principles (think first, simplicity, surgical changes, goal-driven)
- **Uncle Bob (Clean Code, 2008):** Naming discipline, SRP, small functions, TDD, exceptions with context

### Dropped (Project-Specific, Not General Purpose)

- `scaffold-exercises` — tied to ai-hero-cli
- `obsidian-vault` — personal vault path hardcoded
- `migrate-to-shoehorn` — TypeScript-specific library migration
- `github-triage` — pure GitHub issue state machine (contradicts local-first rule)
- `test-skill` — placeholder, discard

---

## Status Legend

| Icon | Meaning |
|---|---|
| ✅ Active | Implemented, tested, stable |
| 🔲 Planned | Designed, not yet implemented |
| 🔄 Refactoring | Active but under revision |
| ⚠️ Deprecated | Will be removed in future release |

---

## How to Update This Table

1. Every new skill gets a row here (before the skill is published)
2. Every skill rename: update Column 3 (Skill name)
3. Every phase reassignment: update Column 2 (Phase)
4. Every major change: bump the "Last updated" date at top

Run: `git log --oneline -- SKILL-INDEX.md` to see when each change was made.
