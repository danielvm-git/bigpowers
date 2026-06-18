# Workflow Steps Reference: Phase 0–8 Detail

**Source of Truth:** `docs/WORKFLOW-SOP-v2.md` (pinned)  
**Purpose:** Per-step operational detail for the 8-step story cycle and project-phase conductors.

---

## Phase 0: seed-conventions (one-time only)

- **Trigger:** `/seed-conventions`
- **How:**
  1. Runs `scripts/sync-skills.sh` to generate Cursor, Gemini CLI, and Claude Code skill artifacts
  2. Creates `CLAUDE.md` with project instructions for Claude Code
  3. Creates `CONVENTIONS.md` with git rules, code style, and skill naming conventions
  4. Creates `.claude/settings.json`, `.gemini/extensions/bigpowers/`, `.cursor/rules/`
- **Output:** Agent-ready project directory; all AI coding tools configured identically
- **Gate:** READY → next: `orchestrate-project`
- **Do NOT re-run** per story — machine-level setup only

---

## Phase 1–3: orchestrate-project

- **Trigger:** `/orchestrate-project --mode standard`
- **How:**
  1. DISCOVER — `survey-context` reads codebase; `elaborate-spec` refines requirements
  2. ELABORATE — `model-domain`, `grill-me`, `define-language` produce domain understanding
  3. PLAN — `scope-work`, `slice-tasks`, `plan-work` produce `specs/release-plan.yaml`
- **Output:**
  - `specs/state.yaml` (active_flow: build_epic)
  - `specs/release-plan.yaml` (BCP baseline, WSJF-ordered)
  - `specs/product/SCOPE_LATEST.yaml`, `VISION_LATEST.yaml`
  - `specs/tech-architecture/TECH_STACK_LATEST.md`
- **Gate:** Confirm (human) → plan → build; requires release-plan.yaml
- **Semver:** `0.0.0-β` (pre-delivery)

---

## Step 1 — survey-context

- **Trigger:** `/survey-context`
- **How:** Reads `CONVENTIONS.md` → `specs/state.yaml` → `specs/release-plan.yaml` → git state → maps lifecycle phase → recommends next skill
- **Output:** Console report with phase, active epic/story, open blockers
- **Writes:** `state.yaml metrics.story_start: <ISO>`, `handoff.next_skill: plan-work`
- **Gate:** READY (no blockers, SCOPE_LATEST.yaml exists) → next: `plan-work`

---

## Step 2 — plan-work

- **Trigger:** `/plan-work`
- **How:**
  1. HARD GATE: success criteria must be clear before writing tasks
  2. ZOOM-OUT: check module callers and contracts
  3. Write story tasks to `specs/epics/<eNN>-<name>.yaml`, each labeled `[BCP N]`
  4. Every task must have a `verify: <runnable command>` pair
  5. SLOPCHECK: reject SLOP packages; flag [SUS] dependencies
- **Output:** `specs/epics/eNN-name.yaml` with `bcps: N`
- **Writes:** `state.yaml epic_cycle.story_bcps = N`, `handoff.next_skill: kickoff-branch`
- **Gate:** READY (all tasks have verify: commands, no [SLOP]) → next: `kickoff-branch`

---

## Step 3 — kickoff-branch

- **Trigger:** `/kickoff-branch`
- **How:**
  1. HARD GATE: must not be on main/master
  2. `git worktree add ../<slug> feat/<eNNsNN>-<desc>`
  3. Run full test suite — baseline must be green before any code is written
- **Output:** Feature branch + worktree at `../bp-<story-id>/`
- **Writes:** `state.yaml git.branch`, `handoff.next_skill: develop-tdd`
- **Gate:** READY (branch created, baseline PASS) → next: `develop-tdd`

---

## Step 4 — develop-tdd

- **Trigger:** `/develop-tdd`
- **How (one cycle per BCP task):**
  1. **RED** — Write failing test against public interface; confirm FAIL
  2. **GREEN** — Write minimum implementation; confirm PASS
  3. **REFACTOR** — Clean up; confirm still PASS
  4. Repeat for each `[BCP N]` task
- **Rules:** Public interfaces only; vertical slices only; F.I.R.S.T
- **Writes:** `state.yaml handoff.next_skill: verify-work`
- **Gate:** READY (all BCP tasks GREEN, all verify: commands pass) → next: `verify-work`

---

## Step 5 — verify-work

- **Trigger:** `/verify-work`
- **How:**
  1. Cold-start smoke: full build + test suite from clean state
  2. Mechanical gates: build ✓, typecheck ✓, lint ✓, tests ✓
  3. UAT: follow each epic shard step; confirm behavioral correctness manually
  4. Gaps loop: if any UAT step fails → return to `develop-tdd`
- **Developer action required:** Confirm each UAT step — cannot be automated
- **Writes:** `state.yaml handoff.next_skill: audit-code`
- **Gate:** PASS (all mechanical + all UAT confirmed) → next: `audit-code`
- **HARD GATE:** No story is "done" without manual UAT confirmation.

---

## Step 6 — audit-code

- **Trigger:** `/audit-code`
- **How:**
  1. Function size: 4–20 lines (flag violations)
  2. SRP: each function/module does one thing
  3. Boy Scout Rule: code must be cleaner than found
  4. No commented-out code, no debug statements
  5. Tests only through public interfaces
  6. Run `npm run compliance` → must be ≥ 94%
- **Writes:** `state.yaml handoff.next_skill: commit-message`
- **Gate:** Quality ≥ 94% (hard) → next: `commit-message`

---

## Step 7 — commit-message

- **Trigger:** `/commit-message`
- **How:**
  1. Review working tree diff
  2. Draft `<type>(<scope>): <desc>` (Conventional Commits)
  3. Determine semver bump: `feat` → minor, `fix` → patch, `feat!` → major
  4. No `Co-authored-by` footer (per CONVENTIONS.md)
  5. `git commit -m "<message>"`
- **Semver:** `0.0.0-β` → first `feat:` → `0.1.0` → ... → MVP `1.0.0`
- **Writes:** `state.yaml handoff.next_skill: release-branch`
- **Gate:** READY (Conventional Commits format) → next: `release-branch`

---

## Step 8 — release-branch

- **Trigger:** `/release-branch` (solo mode: `bash scripts/land-branch.sh`)
- **How:**
  1. SAFETY GATE: "About to land on main — confirm?"
  2. Squash-merge feature branch to main
  3. `git push origin main`
  4. `git worktree remove ../bp-<story-id>`
  5. Update `specs/execution-status.yaml`: story → done
  6. Write metrics row to `specs/metrics/cycle-times.yaml`
- **Writes:**
  - `state.yaml metrics.story_end`, `metrics.cycle_minutes`, `metrics.bcp_per_hour`
  - `specs/metrics/cycle-times.yaml` — new row appended
  - `state.yaml handoff.next_skill: survey-context` (next story) OR `semantic-release` (all done)
- **Gate:** READY (landed, worktree removed, metrics written)

---

## Phase 5–6: verify + release (once per project)

- **Phase 5 VERIFY:** `run-evals` for capability measurement + `verify-work` for full regression UAT
- **Phase 6 RELEASE:** `npm run release` (semantic-release) to tag the MVP version
  - All `feat:` commits accumulate as minor bumps
  - Developer explicitly declares MVP by allowing the `1.0.0` tag
  - CHANGELOG.md generated; npm publish triggered if configured
- **Output:** `v1.0.0` git tag, CHANGELOG.md, npm package published
