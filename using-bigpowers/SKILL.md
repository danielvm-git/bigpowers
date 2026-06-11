---
name: using-bigpowers
model: sonnet
description: One-time bootstrap that introduces the bigpowers skills system, the PMBOK lifecycle arc, and tells you which skill to call first for your situation. Use when starting with bigpowers for the first time, when user asks "where do I start?", or when the skills system needs to be explained.
---

# Using bigpowers
> **HARD GATE** — **HARD GATE** — This skill is the entry point. Do NOT skip it when onboarding new users or starting a new session. It establishes the bigpowers methodology, lifecycle phases, and conventions.


Welcome to **bigpowers** — a lifecycle of **61** agent skills for production-ready, TDD-driven software by solo developers.

## Install

```bash
npx bigpowers                  # one-shot setup
npm install -g bigpowers       # global install, then run: bigpowers
```

From source (contributors): `git clone` → `npm install` or `bash scripts/install.sh`.

Package: [bigpowers on npm](https://www.npmjs.com/package/bigpowers)

## What bigpowers is

A curated set of skills organized around the PMBOK developer lifecycle. Each skill does one thing. Skills reference each other by name only — low coupling, high cohesion. All written output goes to `specs/` at your project root.

## The lifecycle at a glance

See orchestrate-project for the canonical 6-phase lifecycle.

```
BOOTSTRAP   using-bigpowers (this skill, first time only)
              ↓
DISCOVER    survey-context → research-first → elaborate-spec
              ↓
DESIGN      model-domain / define-language / grill-me / deepen-architecture / design-interface
              ↓
PLAN        scope-work → slice-tasks → define-success → plan-work / plan-refactor
              ↓
INITIATE    kickoff-branch → guard-git / hook-commits / seed-conventions
              ↓
SPIKE?      spike-prototype → (feeds back to plan-work)
              ↓
EXECUTE     develop-tdd + enforce-first ←→ delegate-task / dispatch-agents / execute-plan
              ↓
VERIFY      run-evals → verify-work
              ↓
HARDEN      wire-observability (any phase)
              ↓
BUG?        investigate-bug → diagnose-root → validate-fix
              ↓
REVIEW      audit-code → request-review → respond-review
              ↓
INTEGRATE   commit-message → release-branch
              ↓
SUSTAIN     inspect-quality / organize-workspace (ongoing)

UTILITY     terse-mode / craft-skill / edit-document (any phase)
```

## Where to start

| Your situation | First skill to call |
|---------------|---------------------|
| Greenfield project, nothing set up | `seed-conventions` |
| Existing project, new task | `survey-context` |
| Vague idea that needs shaping | `elaborate-spec` |
| Plan exists, ready to implement | `kickoff-branch` → `develop-tdd` |
| Bug to fix | `investigate-bug` |
| Code ready for review | `audit-code` |
| Shipping a feature | `commit-message` → `release-branch` |
| Solo dev, PRs feel heavy | Enable `profiles/solo-git.md` → `specs/WORKFLOW-solo-git.md` → land via `scripts/land-branch.sh` |

## Solo Git profile

If you work alone and do not want PR ceremony every task:

1. Read [profiles/solo-git.md](../profiles/solo-git.md).
2. Register with `compose-workflow` → `specs/WORKFLOW-solo-git.md`.
3. Ship with `release-branch` in **solo-local** mode (`land-branch.sh`), not `gh pr create`.

You still use worktrees, protected `main`, and verification gates — only the integrate step changes.

## YAML cockpit and dashboard

Operational source of truth:

- `specs/state.yaml` — session, active epic/story, handoff
- `specs/release-plan.yaml` — release index and epic list
- `specs/epics/eNN-*.yaml` — stories and tasks with `verify`
- `specs/execution-status.yaml` — done/pending per story

Start the HTTP dashboard with `visual-dashboard` → `GET /api/status?projectDir=<abs>` and `GET /cockpit.html` for a read-only PM view.

## Key conventions

- **specs/ is your memory.** All domain docs, plans, and investigation outputs go in `specs/` at your project root.
- **Integrate:** team default is `gh pr` (team-pr); solo profile uses `land-branch.sh`. Never create GitHub issues from skills — use local Markdown files instead.
- **One skill, one thing.** If you're unsure which skill to call, call `survey-context` — it reads your current state and recommends the next step.
- **verify: every step.** Every epic task must have `verify: <runnable command>`. Evidence over claims.
- **61 skills.** See `SKILL-INDEX.md`; find skills with `search-skills`.

## After this

Call `survey-context` to read your project's current state and get a personalized recommendation for where to go next.
