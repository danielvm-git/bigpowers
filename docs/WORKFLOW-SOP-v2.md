# Process Document: bigpowers — Solo Developer SDLC

**Owner:** Solo Developer | **Last Updated:** 2026-06-13 | **Version:** 2.1.2 | **Review Cadence:** Per major release

> **Note:** Version-specific sections tagged `(v2.0.0 ...)` below describe features introduced in v2.0.0 that remain current unless otherwise noted.

---

## Purpose

Provide a deterministic, auditable, enterprise-ready software delivery lifecycle for solo developers. Eliminates the "what comes next?" problem through a conductor hierarchy, mandatory next-skill signaling, BCP scope accounting, and automated cycle-time metrics. Every story that ships writes its own evidence trail.

---

## Scope

**In scope:**
- All new features delivered via bigpowers from initial machine setup through production release
- Bug fixes routed through the `fix-bug` conductor
- Refactors with a defined spec (`plan-refactor` → `build-epic`)
- Projects of any size: single-epic MVPs to multi-epic product releases

**Out of scope:**
- Emergency zero-downtime hotfixes (use `release-branch --hotfix` mode directly)
- Pure research spikes with no delivery commitment (use `spike-prototype` standalone)
- Multi-team orchestration (use `dispatch-agents` for parallel subagent work)
- One-off document edits with no code change (use `edit-document` or `write-document` directly)

---

## RACI Matrix

| Step | Responsible | Accountable | Consulted | Informed |
|------|-------------|-------------|-----------|----------|
| Machine setup (`seed-conventions`) | Developer | Developer | — | — |
| Project scoping (`orchestrate-project` Ph 1–3) | Agent + Developer | Developer | Domain experts | Stakeholders |
| Story planning (`plan-work`) | Agent | Developer | — | — |
| Branch + baseline (`kickoff-branch`) | Agent | Developer | — | — |
| TDD implementation (`develop-tdd`) | Agent | Developer | — | — |
| UAT sign-off (`verify-work`) | **Developer** | Developer | — | — |
| Code audit (`audit-code`) | Agent | Developer | — | — |
| Commit + land (`commit-message` + `release-branch`) | Agent | Developer | — | — |
| Metrics logging (`cycle-times.yaml`) | Agent (automated) | Developer | — | — |
| Dashboard monitoring (`npm run dashboard`) | Developer | Developer | — | — |
| MVP release (`semantic-release`) | Agent | Developer | — | Stakeholders |

> **Note:** UAT (`verify-work`) is the only step where the Developer is exclusively Responsible. The agent cannot confirm behavioral correctness on behalf of the user.

---

## Process Flow

```
ONE TIME (new machine or fresh clone)
────────────────────────────────────
seed-conventions
  └─ Creates: CLAUDE.md, CONVENTIONS.md, .claude/, .gemini/, .cursor/rules/
  └─ Syncs:   43 skills via scripts/sync-skills.sh
  └─ Gate: READY → next: orchestrate-project

ONCE PER PROJECT
────────────────
orchestrate-project --mode [standard | fast-track | ad-hoc]
  ├─ Phase 1  DISCOVER   survey-context, research-first, elaborate-spec
  ├─ Phase 2  ELABORATE  model-domain, grill-me, define-language, deepen-architecture, design-interface
  ├─ Phase 3  PLAN       scope-work, slice-tasks, plan-work → release-plan.yaml (BCP baseline)
  ├─ Phase 4  BUILD      → build-epic × N stories (see below)
  ├─ Phase 5  VERIFY     run-evals, verify-work (project-level UAT)
  └─ Phase 6  RELEASE    commit-message, release-branch, semantic-release → v1.0.0 MVP

ONCE PER STORY (inside Phase 4 — called by build-epic)
───────────────────────────────────────────────────────
Step 1  survey-context    ← stamps story_start timestamp
Step 2  plan-work         ← writes [BCP N] tasks + verify: commands
Step 3  kickoff-branch    ← creates worktree + feature branch
Step 4  develop-tdd       ← RED → GREEN → REFACTOR (vertical slices)
Step 5  verify-work       ← UAT gate (developer confirms behavioral correctness)
Step 6  audit-code        ← quality gate ≥ 94%
Step 7  commit-message    ← Conventional Commits + semver bump
Step 8  release-branch    ← land to main; stamps story_end + writes cycle-times.yaml
```

---

## Detailed Steps

### Phase 0: seed-conventions (one-time only)

- **Who:** Developer
- **When:** New machine, new clone, or first time using bigpowers on a project
- **Trigger:** `/seed-conventions`
- **How:**
  1. Runs `scripts/sync-skills.sh` to generate Cursor, Gemini CLI, and Claude Code skill artifacts
  2. Creates `CLAUDE.md` with project instructions for Claude Code
  3. Creates `CONVENTIONS.md` with git rules, code style, and skill naming conventions
  4. Creates `.claude/settings.json`, `.gemini/extensions/bigpowers/`, `.cursor/rules/`
- **Output:** Agent-ready project directory; all AI coding tools configured identically
- **Gate:** READY → next: `orchestrate-project`
- **Do NOT re-run** per story — it is a machine-level setup, not a feature step

---

### Phase 1–3: orchestrate-project (once per project)

- **Who:** Agent + Developer
- **When:** After `seed-conventions`, before any code is written
- **Trigger:** `/orchestrate-project --mode standard`
- **How:**
  1. DISCOVER — `survey-context` reads existing context; `elaborate-spec` refines requirements
  2. ELABORATE — `model-domain`, `grill-me`, `define-language` produce domain understanding
  3. PLAN — `scope-work`, `slice-tasks`, `plan-work` produce `specs/release-plan.yaml` with BCP baseline
- **Output:**
  - `specs/state.yaml` (YAML cockpit, active_flow: build_epic)
  - `specs/release-plan.yaml` (BCP baseline per story, WSJF-ordered)
  - `specs/product/SCOPE_LATEST.yaml`, `VISION_LATEST.yaml`
  - `specs/tech-architecture/TECH_STACK_LATEST.md`
- **Gate:** Confirm (human) → plan → build transition; requires release-plan.yaml to exist
- **Semver at this point:** `0.0.0-β` (pre-delivery)

---

### Phase 4: build-epic × story (repeats per story, WSJF order)

Each story runs the full 8-step cycle. `build-epic` tracks position in `state.yaml epic_cycle` and resumes from the correct step if the session is interrupted.

#### Step 1 — survey-context

- **Trigger:** `/survey-context`
- **How:** Reads `CONVENTIONS.md` → `specs/state.yaml` → `specs/release-plan.yaml` → git state → maps to lifecycle phase → recommends next skill
- **Output:** Console report with phase, active epic/story, open blockers, `next: plan-work`
- **Writes:** `state.yaml metrics.story_start: <ISO timestamp>`, `handoff.next_skill: plan-work`
- **Gate:** READY (no blockers, SCOPE_LATEST.yaml exists) → next: `plan-work`

#### Step 2 — plan-work

- **Trigger:** `/plan-work`
- **How:**
  1. HARD GATE: success criteria must be clear before writing tasks
  2. ZOOM-OUT: check module callers and contracts
  3. Write story tasks to `specs/epics/<eNN>-<name>.yaml`, each labeled `[BCP N]`
  4. Every task must have a `verify: <runnable command>` pair
  5. SLOPCHECK: reject SLOP packages; flag [SUS] dependencies
- **Output:** `specs/epics/eNN-name.yaml` with `bcps: N` count
- **Writes:** `state.yaml epic_cycle.story_bcps = N`, `handoff.next_skill: kickoff-branch`
- **Gate:** READY (all tasks have verify: commands, no [SLOP] packages) → next: `kickoff-branch`

#### Step 3 — kickoff-branch

- **Trigger:** `/kickoff-branch`
- **How:**
  1. HARD GATE: must not be on main/master
  2. `git worktree add ../<slug> feat/<eNNsNN>-<desc>`
  3. Run full test suite — baseline must be green before any code is written
- **Output:** Feature branch + worktree at `../bp-<story-id>/`
- **Writes:** `state.yaml git.branch: feat/<eNNsNN>-<desc>`, `handoff.next_skill: develop-tdd`
- **Gate:** READY (branch created, baseline PASS) → next: `develop-tdd`

#### Step 4 — develop-tdd

- **Trigger:** `/develop-tdd`
- **How (one cycle per BCP task):**
  1. **RED** — Write failing test against public interface; run → confirm FAIL
  2. **GREEN** — Write minimum implementation; run → confirm PASS
  3. **REFACTOR** — Clean up without breaking; run → confirm still PASS
  4. Repeat for each `[BCP N]` task in the epic shard
- **Rules:**
  - Tests verify behavior through public interfaces only (no implementation leakage)
  - No horizontal slicing (all tests first, then all code) — vertical slices only
  - F.I.R.S.T: Fast, Independent, Repeatable, Self-validating, Timely
- **Writes:** `state.yaml handoff.next_skill: verify-work`
- **Gate:** READY (all BCP tasks GREEN, all `verify:` commands pass) → next: `verify-work`

#### Step 5 — verify-work

- **Trigger:** `/verify-work`
- **How:**
  1. Cold-start smoke: full build + test suite from clean state
  2. Mechanical gates: build ✓, typecheck ✓, lint ✓, tests ✓
  3. UAT: follow each step in the epic shard, confirm behavioral correctness manually
  4. Gaps loop: if any UAT step fails → return to `develop-tdd`; do not advance
- **Developer action required:** Confirm each UAT step — this gate cannot be automated
- **Writes:** `state.yaml handoff.next_skill: audit-code`
- **Gate:** PASS (all mechanical + all UAT confirmed) → next: `audit-code`
- **HARD GATE:** No story is "done" without manual UAT confirmation. Agent assertion does not count.

#### Step 6 — audit-code

- **Trigger:** `/audit-code`
- **How:**
  1. Function size: 4–20 lines (flag violations)
  2. SRP: each function/module does one thing
  3. Boy Scout Rule: code must be cleaner than found
  4. No commented-out code, no debug statements
  5. Tests only test through public interfaces
  6. Run `npm run compliance` → must be ≥ 94%
- **Writes:** `state.yaml handoff.next_skill: commit-message`
- **Gate:** Quality ≥ 94% (hard) → next: `commit-message`

#### Step 7 — commit-message

- **Trigger:** `/commit-message`
- **How:**
  1. Review working tree diff
  2. Draft Conventional Commits message: `<type>(<scope>): <desc>`
  3. Determine semver bump: `feat` → minor, `fix` → patch, `feat!` → major
  4. No `Co-authored-by` footer (per CONVENTIONS.md)
  5. `git commit -m "<message>"`
- **Semver progression:** `0.0.0-β` → first `feat:` → `0.1.0` → subsequent `feat:` → `0.2.0` … → MVP release → `1.0.0`
- **Writes:** `state.yaml handoff.next_skill: release-branch`
- **Gate:** READY (message follows Conventional Commits format) → next: `release-branch`

#### Step 8 — release-branch

- **Trigger:** `/release-branch` (solo mode: `bash scripts/land-branch.sh`)
- **How:**
  1. SAFETY GATE: "About to land on main — confirm?" → developer must say yes
  2. Squash-merge feature branch to main
  3. `git push origin main`
  4. `git worktree remove ../bp-<story-id>`
  5. Update `specs/execution-status.yaml`: story → done (epic → done if all stories done)
  6. Write metrics row to `specs/metrics/cycle-times.yaml`
- **Output:** Story landed; metrics written; worktree cleaned
- **Writes:**
  - `state.yaml metrics.story_end: <ISO timestamp>`
  - `state.yaml metrics.cycle_minutes: <N>`
  - `state.yaml metrics.bcp_per_hour: <N>`
  - `specs/metrics/cycle-times.yaml` — new row appended
  - `state.yaml handoff.next_skill: survey-context` (next story) OR `semantic-release` (all stories done)
- **Gate:** READY (landed, worktree removed, metrics written) → next: `survey-context` or `semantic-release`

---

### Phase 5–6: verify + release (once per project)

- **Phase 5 VERIFY:** Run `run-evals` for capability measurement, then `verify-work` at project level for full regression UAT
- **Phase 6 RELEASE:** Run `npm run release` (semantic-release) to tag the MVP version
  - All `feat:` commits since `0.0.0-β` accumulate as minor bumps
  - Developer explicitly declares MVP by allowing the `1.0.0` tag
  - CHANGELOG.md generated; npm publish triggered if configured
- **Output:** `v1.0.0` git tag, CHANGELOG.md, npm package published

---

## Exceptions and Edge Cases

| Scenario | What to Do |
|----------|-----------|
| Bug found mid-story | Pause the story (`state.yaml` preserves position). Run `/fix-bug` → `investigate-bug` → `develop-tdd` → `validate-fix`. Then resume the story at its last `handoff.next_skill`. |
| Gate fails (quality < 94%) | Do NOT advance. Fix the issues, re-run `audit-code`. Never lower the threshold. |
| UAT step fails | Return to `develop-tdd` for that specific BCP. Do not mark story done. |
| Session interrupted mid-story | Run `/survey-context` — it reads `state.yaml epic_cycle` and resumes from `handoff.next_skill`. |
| Task is ambiguous (no clear verify command) | Do not write the task. Run `define-success` to convert the ambiguous goal into step → verify pairs first. |
| Story is blocked by an external dependency | Document in `state.yaml handoff.open_decisions`. Pause the story and work on the next WSJF-priority story. |
| New requirement arrives mid-build | Do NOT start it immediately. Run `change-request` to insert it into `release-plan.yaml` with WSJF ordering. Then finish the current story. |
| sync-skills.sh fails on `.gemini/` permissions | This is a sandbox-only issue. Run directly on the host machine where `.gemini/` is writable. |
| `setup-environment` needed | Run it once before the project, not inside each story. It is not part of the build-epic cycle. |
| Need to parallel-ship two stories | Use `dispatch-agents` inside `develop-tdd` for independent tasks. Never split the 8-step cycle across simultaneous stories on the same worktree. |

---

## Artifact Inventory

The following files are created or updated by the workflow. All live under `specs/` except as noted.

| Artifact | Created by | Updated by | Purpose |
|----------|-----------|------------|---------|
| `CLAUDE.md` | `seed-conventions` | Developer | Project instructions for Claude Code |
| `CONVENTIONS.md` | `seed-conventions` | Developer | Git, code style, skill rules |
| `.claude/settings.json` | `seed-conventions` | — | Claude Code agent config |
| `.gemini/extensions/bigpowers/` | `seed-conventions` via sync | `sync-skills.sh` | Gemini CLI skill artifacts |
| `.cursor/rules/` | `seed-conventions` via sync | `sync-skills.sh` | Cursor agent skill artifacts |
| `specs/state.yaml` | `orchestrate-project` | Every skill | Session state, active epic/story/step, metrics |
| `specs/release-plan.yaml` | `orchestrate-project` Ph 3 | `change-request` | BCP baseline, WSJF-ordered stories |
| `specs/product/SCOPE_LATEST.yaml` | `scope-work` | `change-request` | Project boundaries |
| `specs/product/VISION_LATEST.yaml` | `elaborate-spec` | Developer | Product vision |
| `specs/tech-architecture/TECH_STACK_LATEST.md` | `orchestrate-project` | Developer | Architecture decisions |
| `specs/epics/<eNN>-<name>.yaml` | `plan-work` | `plan-work` (per story) | BCP tasks + verify commands |
| `specs/execution-status.yaml` | `release-branch` | `release-branch` | Story/epic done status |
| `specs/metrics/cycle-times.yaml` | `release-branch` (first story) | `release-branch` (each story) | Per-story BCP/hr, cycle time |
| `specs/metrics/README.md` | `release-branch` (first story) | — | Metrics schema documentation |
| `specs/EVALS-<feature>.md` | `run-evals` | `run-evals` | Capability measurement results |
| `specs/bugs/BUG-*.md` | `investigate-bug` | `validate-fix` | Bug record and resolution |
| `CHANGELOG.md` | `semantic-release` | `semantic-release` | Auto-generated from Conventional Commits |

---

## Metrics

| Metric | Target | How to Measure | Written by |
|--------|--------|----------------|-----------|
| BCP/hr per story | ≥ 2.0 | `bcps / (cycle_minutes / 60)` | `release-branch` → `cycle-times.yaml` |
| Avg cycle time per story | ≤ 90 min | Mean of `cycle_minutes` across stories | `specs/metrics/cycle-times.yaml` |
| Code quality | ≥ 94% | `npm run compliance` output | `audit-code` |
| Test suite | 0 failures | `npm test` | `verify-work` (cold-start) |
| Semver progression | `feat:` → minor bump | `commit-message` analysis | `semantic-release` |
| Stories landed per epic | All planned BCPs | `specs/execution-status.yaml` | `release-branch` |

**Monitoring:** Run `npm run dashboard` (TUI) or `npm run dashboard:web` (browser on port 7742) to watch all metrics live as stories land. The dashboard reads `specs/metrics/cycle-times.yaml` and `specs/state.yaml` directly via file watchers — no configuration needed.

---

## Gate Reference

All gates must pass before advancing. Gates cannot be downgraded or skipped in Standard mode.

| Gate type | When | Passes when | Blocks on |
|-----------|------|-------------|-----------|
| **Confirm** | plan→build, safety-critical actions | Developer explicitly confirms | No response or "no" |
| **Quality** | `audit-code` | `npm run compliance` ≥ 94% | Score < 94% |
| **Safety** | `release-branch` land to main | Developer confirms "yes" to land | No confirmation |
| **Transition** | Phase advancement | Required artifact files exist | Missing state.yaml, SCOPE_LATEST.yaml, etc. |
| **Hard Gate** | Inline in skills (plan-work, kickoff-branch) | Specific precondition met | Precondition not met — skill stops |

---

## next_skill Signaling Reference

Each critical-path skill writes `state.yaml handoff.next_skill` on exit. Run `/survey-context` at any time to read the current recommended next skill.

```
survey-context    → plan-work
plan-work         → kickoff-branch
kickoff-branch    → develop-tdd
develop-tdd       → verify-work
verify-work       → audit-code
audit-code        → commit-message
commit-message    → release-branch
release-branch    → survey-context (next story) | semantic-release (all done)
```

---

## Dashboard Monitoring (v2.0.0 new)

The factory dashboard (`dashboard/`) provides live visibility into all workflow panels without interrupting the agent session.

| Command | Mode | What it shows |
|---------|------|---------------|
| `npm run dashboard` | TUI (terminal) | 6-panel blessed screen: pipeline · epic queue · action log · file system · state.yaml · cycle-time ledger |
| `npm run dashboard:web` | Browser (port 7742) | Same panels as the TUI, served as a live HTML page via SSE |
| `Ctrl-R` (TUI) | — | Force refresh all panels |
| `F` (TUI) | — | Toggle file system panel |
| `L` (TUI) | — | Toggle cycle-time ledger |

The dashboard is **read-only**. It never writes files. It updates automatically via `chokidar` file watchers — no polling, no manual refresh needed during a session.

---

## Semver Convention (v2.0.0 change)

| Stage | Version | How reached |
|-------|---------|-------------|
| Pre-delivery | `0.0.0-β` | Initial state after `orchestrate-project` |
| Per story feat | `0.N.0` | Each `feat:` commit via `commit-message` |
| Per story fix | `0.N.P` | Each `fix:` commit via `commit-message` |
| MVP release | `1.0.0` | Developer declares MVP; `npm run release` tags it |
| Post-MVP feat | `1.N.0` | Each `feat:` commit after MVP |
| Breaking change | `N.0.0` | `feat!:` or `BREAKING CHANGE:` footer |

The `1.0.0` tag is never automated — it is a deliberate human decision that all planned BCPs have been delivered and the product is ready for production.

---

## Related Documents

- [`CONVENTIONS.md`](../CONVENTIONS.md) — Git rules, code style, Conventional Commits format
- [`PRINCIPLES.md`](PRINCIPLES.md) — Seven philosophical layers (Uncle Bob → BMAD synthesis)
- [`SKILL-INDEX.md`](../SKILL-INDEX.md) — Canonical list of all 61 active skills by phase
- [`specs/tech-architecture/PLAN-refactor-skills-workflow.md`](../specs/tech-architecture/PLAN-refactor-skills-workflow.md) — The v2.0.0 refactor plan (24 BCPs, 4 epics)
- [`specs/tech-architecture/PLAN-factory-dashboard.md`](../specs/tech-architecture/PLAN-factory-dashboard.md) — Dashboard build plan (18 BCPs, 3 epics)
- [`specs/metrics/README.md`](../specs/metrics/README.md) — cycle-times.yaml schema reference
- [`orchestrate-project/REFERENCE.md`](../orchestrate-project/REFERENCE.md) — Full phase specs + gate truth table
- [`build-epic/SKILL.md`](../build-epic/SKILL.md) — 8-step story cycle reference
