# Skill Index — Single Source of Truth

**Purpose:** One canonical reference for all bigpowers skills. Referenced by README.md, RELEASE-PLAN.md, and CONVENTIONS.md. Updated per-release.

**Last updated:** 2026-06-10 (v3.1.0 — YAML cockpit; 61 active, 0 planned; 18 sub-ops absorbed into parent skills)

---

## Quick Navigation by BMAD Phase

| Phase | Active | Skills |
|---|---|---|
| **Bootstrap** | 1 | using-bigpowers |
| **Orchestrate** | 1 | orchestrate-project |
| **Discover** | 4 | survey-context, research-first, elaborate-spec, map-codebase |
| **Elaborate** | 6 | model-domain, define-language, grill-me, grill-with-docs, deepen-architecture, design-interface |
| **Plan** | 8 | assess-impact, change-request, scope-work, slice-tasks, define-success, plan-work, plan-refactor, plan-release |
| **Spike** | 1 | spike-prototype |
| **Initiate** | 4 | kickoff-branch, guard-git, hook-commits, seed-conventions |
| **Build** | 8 | develop-tdd, enforce-first, delegate-task, dispatch-agents, execute-plan, build-epic, run-planning, fix-bug |
| **Harden** | 1 | wire-observability |
| **Verify** | 2 | verify-work, run-evals |
| **Bug** | 3 | investigate-bug, diagnose-root, validate-fix |
| **Review** | 4 | audit-code, request-review, respond-review, trace-requirement |
| **Integrate** | 2 | commit-message, release-branch |
| **Sustain** | 4 | inspect-quality, organize-workspace, stocktake-skills, evolve-skill |
| **Utility** | 12 | terse-mode, craft-skill, edit-document, session-state, migrate-spec, visual-dashboard, write-document, setup-environment, reset-baseline, search-skills, compose-workflow, simulate-agents |
| **TOTAL** | **61** | |

---

## Full Reference Table

| # | Phase | Skill | Intent | Artefact Output | Status |
|---|---|---|---|---|---|
| 1 | Bootstrap | `using-bigpowers` | Lifecycle intro; where to start | (dialogue) | ✅ Active |
| 2 | Orchestrate | `orchestrate-project` | Meta-skill enforcing 6-phase core loop | (orchestration) | ✅ Active |
| 3 | Discover | `survey-context` | Per-task context map; suggests next skill | STATE.md update | ✅ Active |
| 4 | Discover | `research-first` | Look-before-build; prior art search | Prior Art in spec | ✅ Active |
| 5 | Discover | `elaborate-spec` | Dialogue to refine rough idea into spec | (dialogue) | ✅ Active |
| 6 | Discover | `map-codebase` | High-fidelity codebase survey | CONTEXT.md | ✅ Active |
| 7 | Elaborate | `model-domain` | Interactive domain model | CONTEXT.md, adr/ | ✅ Active |
| 8 | Elaborate | `define-language` | Extract ubiquitous language glossary | UBIQUITOUS_LANGUAGE.md | ✅ Active |
| 9 | Elaborate | `grill-me` | Stress-test design (Design + Docs modes) | (dialogue) | ✅ Active |
| 10 | Elaborate | `grill-with-docs` | Grill assumptions grounded in real library docs | (dialogue) | ✅ Active |
| 11 | Elaborate | `deepen-architecture` | Architecture deepening (Ousterhout deep modules) | CONTEXT.md | ✅ Active |
| 12 | Elaborate | `design-interface` | Multiple interface designs via parallel subagents | INTERFACE-OPTIONS.md | ✅ Active |
| 13 | Plan | `assess-impact` | Blast radius before code | IMPACT.md | ✅ Active |
| 14 | Plan | `change-request` | Add requirement or WSJF reorder | RELEASE-PLAN.md | ✅ Active |
| 15 | Plan | `scope-work` | Define in/out boundaries | SCOPE.md | ✅ Active |
| 16 | Plan | `slice-tasks` | Vertical slices | TASKS.md | ✅ Active |
| 17 | Plan | `define-success` | Step → verify pairs; absorbs zoom-out, slopcheck | (dialogue) | ✅ Active |
| 18 | Plan | `plan-work` | Detailed plan with verify steps; absorbs plan-work-fast | RELEASE-PLAN.md | ✅ Active |
| 19 | Plan | `plan-refactor` | Refactor plan via interview | REFACTOR.md | ✅ Active |
| 20 | Plan | `plan-release` | Release plan with Gherkin criteria | RELEASE-PLAN.md | ✅ Active |
| 21 | Spike | `spike-prototype` | Throw-away spike | SPIKE-&lt;name&gt;.md | ✅ Active |
| 22 | Initiate | `kickoff-branch` | Worktree + branch + test baseline | (git state) | ✅ Active |
| 23 | Initiate | `guard-git` | Block dangerous git commands | (git state) | ✅ Active |
| 24 | Initiate | `hook-commits` | Pre-commit hooks | (git state) | ✅ Active |
| 25 | Initiate | `seed-conventions` | CLAUDE.md + CONVENTIONS.md + specs/ | CLAUDE.md, CONVENTIONS.md | ✅ Active |
| 26 | Build | `develop-tdd` | Red → green → refactor TDD; absorbs red-phase, green-phase, refactor-phase | src/ | ✅ Active |
| 27 | Build | `enforce-first` | F.I.R.S.T test-quality rubric | (checklist) | ✅ Active |
| 28 | Build | `delegate-task` | One subagent, sequential + review | (code) | ✅ Active |
| 29 | Build | `dispatch-agents` | Parallel subagents on independent tasks | (code) | ✅ Active |
| 30 | Build | `execute-plan` | Batch execute plan with checkpoints | src/ | ✅ Active |
| 31 | Harden | `wire-observability` | Structured logging + observability | src/, CLAUDE.md | ✅ Active |
| 32 | Verify | `verify-work` | Multi-phase UAT; loop on gaps; absorbs cold-start-smoke, gaps-loop, verify-work-smoke | (dialogue) | ✅ Active |
| 33 | Verify | `run-evals` | EDD capability + regression evals | EVALS-&lt;feature&gt;.md | ✅ Active |
| 34 | Bug | `investigate-bug` | Investigate bug → diagnosis | bugs/BUG-*.md | ✅ Active |
| 35 | Bug | `diagnose-root` | 4-phase root cause analysis | bugs/BUG-*.md | ✅ Active |
| 36 | Bug | `validate-fix` | Prove fix works | (verify) | ✅ Active |
| 37 | Review | `audit-code` | Self-review checklist; absorbs audit-code-quick | (checklist) | ✅ Active |
| 38 | Review | `request-review` | Fresh reviewer agent | review-report | ✅ Active |
| 39 | Review | `respond-review` | Act on reviewer feedback | src/ | ✅ Active |
| 40 | Review | `trace-requirement` | Story ID → code/tests | TRACEABILITY.md | ✅ Active |
| 41 | Integrate | `commit-message` | Conventional Commits + semver; absorbs commit-message-fix | (git message) | ✅ Active |
| 42 | Integrate | `release-branch` | Merge/PR decision + cleanup; absorbs release-branch-hotfix | (git PR) | ✅ Active |
| 43 | Sustain | `inspect-quality` | Structured QA session | BUG-LOG.md | ✅ Active |
| 44 | Sustain | `organize-workspace` | Safe workspace cleanup | (filesystem) | ✅ Active |
| 45 | Sustain | `stocktake-skills` | Batch audit of skill catalog | specs/ audit report | ✅ Active |
| 46 | Sustain | `evolve-skill` | Benchmark-gated skill evolution | ADR, STATE.md | ✅ Active |
| 47 | Utility | `terse-mode` | Ultra-terse output (fallback) | (prompt) | ✅ Active |
| 48 | Utility | `craft-skill` | Build new bigpowers skill | skills/&lt;name&gt;/SKILL.md | ✅ Active |
| 49 | Utility | `edit-document` | Edit documents in specs/ | specs/&lt;name&gt;.md | ✅ Active |
| 50 | Utility | `session-state` | Track decisions in state.yaml; absorbs show-state, reset-state, compact-state, list-epics, check-gates | state.yaml | ✅ Active |
| 51 | Utility | `migrate-spec` | Migrate foreign spec formats | specs/ | ✅ Active |
| 52 | Utility | `visual-dashboard` | Browser dashboard | .bigpowers/dashboard/ | ✅ Active |
| 53 | Utility | `write-document` | BMAD technical documents | specs/&lt;name&gt;.md | ✅ Active |
| 54 | Utility | `setup-environment` | Pre-install deps before work | (.env, packages) | ✅ Active |
| 55 | Utility | `reset-baseline` | Restore clean known state | (clean tree) | ✅ Active |
| 56 | Utility | `search-skills` | Natural language → right skill | SKILL-SEARCH-INDEX.md | ✅ Active |
| 57 | Utility | `compose-workflow` | Chain skills into workflow recipe | WORKFLOW-&lt;name&gt;.md | ✅ Active |
| 58 | Utility | `simulate-agents` | Mock User + Auditor simulation | SIMULATION-&lt;feature&gt;.md | ✅ Active |
| 59 | Build | `build-epic` | Eight-step epic build cycle | state.yaml, epics/ | ✅ Active |
| 60 | Build | `run-planning` | Discover-phase workflow tracker | planning-status.yaml | ✅ Active |
| 61 | Bug | `fix-bug` | Bug fix orchestrator | bugs/BUG-*.md | ✅ Active |

**Total: 61 ✅ Active, 0 📋 Planned.**

---

## Lifecycle Arc

```
[First time]
using-bigpowers → orchestrate-project (Standard / Fast-Track / Ad-Hoc)
                         ↓
survey-context → research-first → elaborate-spec → map-codebase
                         ↓
  model-domain / define-language / grill-me / grill-with-docs / design-interface / deepen-architecture
                         ↓
  scope-work → assess-impact → change-request → define-success → slice-tasks → plan-work / plan-refactor / plan-release
                         ↓
    kickoff-branch → guard-git / hook-commits / seed-conventions
                         ↓
       [Unknown domain?] spike-prototype → (learnings feed back to plan-work)
                         ↓
  develop-tdd (+ enforce-first) ←→ delegate-task / dispatch-agents / execute-plan / build-epic
                         ↓
  run-planning (discover workflows → planning-status.yaml)
                         ↓
        wire-observability (production-readiness gate, any phase)
                         ↓
              ★ VERIFY ★  run-evals → verify-work  (prove it works)
                         ↓
    fix-bug → investigate-bug → diagnose-root → validate-fix
                         ↓
      audit-code → request-review → respond-review → trace-requirement
                         ↓
      commit-message → release-branch
                         ↓
   inspect-quality → organize-workspace → stocktake-skills → evolve-skill

Transversal utilities (any phase):
  terse-mode, craft-skill, edit-document, session-state, migrate-spec, visual-dashboard,
  write-document, setup-environment, reset-baseline, search-skills, compose-workflow, simulate-agents
```

---

## Status Legend

| Icon | Meaning |
|---|---|
| ✅ Active | SKILL.md exists and is usable |
| 📋 Planned | Designed but not yet implemented |
| 🔄 Refactoring | Active but under revision |
| ⚠️ Deprecated | Will be removed in a future release |

## Naming Convention Notes

All skills follow `verb-noun` kebab-case (ADR-0001). Documented exceptions:
- `terse-mode` — adjective-noun; retained for clarity
- `visual-dashboard` — adjective-noun; retained for clarity

## How to Update

1. Every new skill: add a row here before publishing.
2. After any change: bump "Last updated" and run `bash scripts/sync-skills.sh`.

→ verify: `find . -maxdepth 2 -name "SKILL.md" | grep -v ".git\|.cursor\|.gemini" | wc -l`
