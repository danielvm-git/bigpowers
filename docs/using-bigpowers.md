# Using bigpowers

Welcome to **bigpowers** v2.0.0 — a lifecycle of **70** agent skills for production-ready, TDD-driven software by solo developers.

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

The canonical lifecycle is the **orchestrate-project 6-phase model**. See [`docs/WORKFLOW-SOP-v2.md`](WORKFLOW-SOP-v2.md) for the full standard operating procedure.

```
ONE TIME    seed-conventions  (machine setup: CLAUDE.md, .claude/, .gemini/, skill sync)
              ↓
ONCE/PROJECT orchestrate-project --mode standard
              │
              ├─ Ph1 DISCOVER   survey-context, research-first, elaborate-spec
              ├─ Ph2 ELABORATE  model-domain, grill-me, define-language, deepen-architecture
              ├─ Ph3 PLAN       scope-work, slice-tasks, plan-work → release-plan.yaml (BCP baseline)
              ├─ Ph4 BUILD      build-epic × N stories ─────────────────────────────────────────┐
              │                                                                                  │
              │  ONCE/STORY (8-step build-epic cycle)                                           │
              │   1. survey-context   ← stamps story_start timestamp                            │
              │   2. plan-work        ← writes [BCP N] tasks + verify: commands                 │
              │   3. kickoff-branch   ← creates worktree + feature branch                       │
              │   4. develop-tdd      ← RED → GREEN → REFACTOR (vertical slices)                │
              │   5. verify-work      ← UAT gate (developer confirms)                           │
              │   6. audit-code       ← quality gate ≥ 94%                                      │
              │   7. commit-message   ← Conventional Commits + semver bump                      │
              │   8. release-branch   ← land to main; stamps story_end + cycle-times.yaml ──────┘
              │
              ├─ Ph5 VERIFY     run-evals, verify-work (project-level)
              └─ Ph6 RELEASE    commit-message, release-branch, semantic-release → v1.0.0 MVP
```

**Semver convention (v2.0.0):** starts at `0.0.0-β`; each `feat:` story → minor bump (`0.1.0`, `0.2.0`…); developer declares MVP by allowing `1.0.0` tag.

**Monitoring:** `npm run dashboard` (TUI) or `npm run dashboard:web` (browser, port 7742) — live panels showing pipeline, epic queue, BCP metrics, and cycle-time ledger.

## Where to start

| Your situation | First skill to call |
|---------------|---------------------|
| Greenfield project, nothing set up | seed-conventions to orchestrate-project |
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

## YAML cockpit and dashboard (v2.0.0)

Operational source of truth — all files live under `specs/` at your project root:

- `specs/state.yaml` — session, active epic/story, step, `handoff.next_skill`, `metrics.story_start`
- `specs/release-plan.yaml` — BCP baseline per story, WSJF-ordered
- `specs/epics/eNN-*.yaml` — stories and tasks labeled `[BCP N]` with `verify:` commands
- `specs/execution-status.yaml` — done/pending per story/epic
- `specs/metrics/cycle-times.yaml` — per-story: BCPs, start, end, cycle minutes, BCP/hr (**new in v2.0.0**)

**Live monitoring dashboard (v2.0.0 new):**

| Command | Mode |
|---------|------|
| `npm run dashboard` | TUI (terminal) — 6-panel blessed screen |
| `npm run dashboard:web` | Browser — same panels served via SSE at `http://localhost:7742` |

The dashboard is read-only. It watches `specs/` for file changes and updates all panels automatically. No configuration needed beyond having run `seed-conventions` and `orchestrate-project`.

For the legacy HTTP cockpit: `visual-dashboard` → `GET /api/status?projectDir=<abs>` and `GET /cockpit.html`.

## Key conventions

- **specs/ is your memory.** All domain docs, plans, and investigation outputs go in `specs/` at your project root.
- **Integrate:** team default is `gh pr` (team-pr); solo profile uses `land-branch.sh`. Never create GitHub issues from skills — use local Markdown files instead.
- **One skill, one thing.** If you're unsure which skill to call, call `survey-context` — it reads your current state and recommends the next step.
- **verify: every step.** Every epic task must have `verify: <runnable command>`. Evidence over claims.
- **BCP accounting.** Every task in `plan-work` is labeled `[BCP N]`. The total is the story's scope unit. `release-branch` auto-logs BCP/hr to `specs/metrics/cycle-times.yaml`.
- **next_skill signaling.** Every critical-path skill writes `handoff.next_skill` to `state.yaml`. Run `survey-context` after any interruption to resume exactly where you left off.
- **70 skills.** See [`specs/SKILL-SEARCH-INDEX_LATEST.md`](../specs/SKILL-SEARCH-INDEX_LATEST.md) (auto-generated catalog — regenerate with `bash scripts/build-skill-index.sh`); find the right skill with `search-skills`. Full SOP at `docs/WORKFLOW-SOP-v2.md`.

## After this

Call `survey-context` to read your project's current state and get a personalized recommendation for where to go next.
