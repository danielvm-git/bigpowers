
# Using bigpowers

Welcome to **bigpowers** — a lifecycle of 37 agent skills for production-ready, TDD-driven software by solo developers.

## What bigpowers is

A curated set of skills organized around the PMBOK developer lifecycle. Each skill does one thing. Skills reference each other by name only — low coupling, high cohesion. All written output goes to `specs/` at your project root.

## The lifecycle at a glance

```
BOOTSTRAP   using-bigpowers (this skill, first time only)
              ↓
DISCOVER    survey-context → elaborate-spec
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

## Key conventions

- **specs/ is your memory.** All domain docs, plans, and investigation outputs go in `specs/` at your project root.
- **`gh` for PRs only.** Never create GitHub issues from skills — use local Markdown files instead.
- **One skill, one thing.** If you're unsure which skill to call, call `survey-context` — it reads your current state and recommends the next step.
- **verify: every step.** Every task in `specs/PLAN.md` must have a `verify: <runnable command>`. Evidence over claims.

## After this

Call `survey-context` to read your project's current state and get a personalized recommendation for where to go next.
