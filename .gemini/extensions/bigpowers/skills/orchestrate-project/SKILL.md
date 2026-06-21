---
name: orchestrate-project
description: "Meta-skill that enforces the 6-phase core loop (discover → elaborate → plan → build → verify → release) with hard gates. Use to coordinate multi-phase projects with guaranteed quality checkpoints. One-time command for the entire project lifecycle."
---


# Orchestrate
> **HARD GATE** — **HARD GATE** — Do NOT invoke orchestrate-project unless you have a clear multi-phase workflow. Single-skill tasks should use dedicated skills instead. Orchestrate is for complex, multi-stage work that requires coordination across phases.


The orchestrate skill coordinates projects through a prescriptive 6-phase core loop with hard gates, ensuring consistent quality and preventing scope creep.

## Quick Start

```bash
# Start a new project (initializes specs/ YAML cockpit and begins discover phase)
claude /orchestrate --mode standard

# Or resume an existing project at the current phase
claude /orchestrate --mode standard --resume

# For low-risk scenarios (hotfixes, refactors on well-tested code)
claude /orchestrate --mode fast-track
```

## The 6-Phase Core Loop

1. **DISCOVER** (3-6 hours): Understand problem. Deliverables: `requirements/VISION_LATEST.yaml`, `requirements/SCOPE_LATEST.yaml`, `plans/TECH_STACK_LATEST.md`.
2. **ELABORATE** (3-6 hours): Research solutions. Deliverables: Prior art in scope YAML, ADRs in `specs/adr/`.
3. **PLAN** (2-4 hours): Write verifiable plan. Deliverables: `release-plan.yaml`, `epics/eNN-*.yaml` with `verify:` per task.
4. **BUILD** (1-8 hours): Execute plan. Runs build-epic once per story in WSJF order. Deliverables: Code; update `execution-status.yaml`.
5. **VERIFY** (1-3 hours): Validate success criteria. Deliverables: UAT evidence, `specs/EVALS-*.md` if used.
6. **RELEASE** (30 min - 2 hours): Ship to production. Deliverables: Release tag (vX.Y.Z), `state.yaml` `release.last_tag`.

### Checkpoint / resume

Track progress via `specs/state.yaml` `project_cycle`:
- `project_cycle.current_phase`: current phase (1–6)
- `project_cycle.completed_phases`: completed phase numbers
- `handoff.next_skill`: skill for the current phase
- On resume, read `project_cycle.current_phase` and continue from there

See [REFERENCE.md](REFERENCE.md) for detailed phase specifications and gate types.

## How Orchestrate Works

1. **Maintains state.yaml** — Tracks current phase, `active_epic`, `active_flow`, decisions, risks.
2. **Spawns appropriate skills** — Routes by `model:` frontmatter. Decisions pass only via `specs/state.yaml` `handoff` between spawns.
3. **Methodology lenses** — If `specs/tech-architecture/test.md` or ADRs exist, apply at phase gates.
4. **Enforces gates** — Hard stops if success criteria not met.
5. **The Gatekeeper** — Between stories in BUILD: read `specs/execution-status.yaml`; previous story must be `done` before starting the next; use `build-epic` for the 8-step epic cycle.
6. **Pauses for confirmation** — After each phase, asks "Ready to proceed?".
7. **Snapshots** — `bash scripts/bp-yaml-snapshot.sh` before major release cuts.

## Orchestration Modes

- **Standard**: Enforce all gates. Use for new features and major refactors.
- **Fast-Track**: Skip negotiable gates. Use for hotfixes and minor improvements.
- **Ad-Hoc**: Warnings only. Use for prototyping and spikes (non-production).

See [REFERENCE.md](REFERENCE.md) for full mode behaviors.

## Verification

All phases complete with artifacts:
```bash
verify: test -f specs/state.yaml && test -f specs/release-plan.yaml && test -f specs/product/SCOPE_LATEST.yaml && ls specs/epics/*.yaml 1>/dev/null && echo "✅ All phases complete"
```

---

# Orchestrate Reference: Phases, Modes, and Workflows

Detailed documentation for the `orchestrate-project` meta-skill.

## The 6-Phase Core Loop

### PHASE 1: DISCOVER
- **Goal**: Understand the problem completely and map existing context.
- **Deliverables**: `requirements/VISION_LATEST.yaml`, `requirements/SCOPE_LATEST.yaml`, `plans/TECH_STACK_LATEST.md`.
- **Skills**: `survey-context`, `elaborate-spec`, `grill-me`.
- **Gate**: Confirm ("Is the problem clear?").

### PHASE 2: ELABORATE
- **Goal**: Research solutions and lock architectural design.
- **Deliverables**: Prior art in scope YAML, ADRs in `specs/adr/`.
- **Skills**: `grill-me`, `model-domain`, `define-language`, `deepen-architecture`, `design-interface`.
- **Gate**: Quality ≥94% (via `request-review`) + Confirm ("Are decisions locked?").

### PHASE 3: PLAN
- **Goal**: Write a verifiable implementation plan with success criteria.
- **Deliverables**: `release-plan.yaml`, `epics/eNN-*.yaml` with `verify:` per task.
- **Skills**: `scope-work`, `slice-tasks`, `define-success`, `plan-work`.
- **Gate**: Quality (request-review ≥94%) + slopcheck [SUS]/[SLOP].

### PHASE 4: BUILD
- **Goal**: Execute the plan story-by-story using the 8-step `build-epic` cycle with TDD and vertical slices.
- **Deliverables**: Code; `execution-status.yaml` updated per story; `specs/metrics/cycle-times.yaml` row per story.
- **Skills**: `build-epic` (conductor) → per-story: `survey-context`, `plan-work`, `kickoff-branch`, `develop-tdd`, `verify-work`, `audit-code`, `commit-message`, `release-branch`.
- **BCP tracking**: `plan-release` sizes each story in Business Complexity Points (BCP) before the build queue; `plan-work` confirms and writes the size to `state.yaml` as `epic_cycle.story_bcps`. See `docs/references/bcp.md` for the canonical sizing method.
- **Timestamps**: `survey-context` stamps `metrics.story_start`; `release-branch` stamps `metrics.story_end` and writes BCP/hr to `specs/metrics/cycle-times.yaml`.
- **next_skill**: Each critical-path skill writes `handoff.next_skill` to `state.yaml`. Agents resume by reading `state.yaml` — no guessing.
- **Dashboard**: `npm run dashboard` (TUI) or `npm run dashboard:web` (browser, port 7742) shows live pipeline, epic queue, BCP metrics, and cycle-time ledger.
- **Gate**: Integration tests PASS; all 8 build-epic steps completed per story.

### PHASE 5: VERIFY
- **Goal**: Validate success criteria and ensure production readiness.
- **Deliverables**: UAT evidence, eval results.
- **Skills**: `run-evals`, `verify-work`, `audit-code`, `request-review` (optional).
- **Gate**: Verification Script confirmed; `verify-work` not on `main`/`master`.

### PHASE 6: RELEASE (Integrate)
- **Goal**: Ship to `main` with full traceability.
- **Deliverables**: Release tag (vX.Y.Z), release notes via semantic-release.
- **Skills**: `commit-message`, `release-branch`.
- **Git arc**:
  1. Plan on `main` (Discover / Plan)
  2. `kickoff-branch` → worktree + feature branch + clean baseline
  3. Build / Verify / Review on feature branch
  4. Integrate: **solo-local** (`scripts/land-branch.sh`) or **team-pr** (`gh pr create` → squash merge)
  5. Cleanup worktree; **end on `main`** in primary repo root
- **Gate**: Safety ("About to land on main. Confirm?").

---

## Orchestration Modes

### Mode 1: Standard (Enforce All Gates)
**Use Case**: New features, major refactors, architectural changes.
**Behavior**:
- All Confirm gates require explicit user approval.
- All Quality gates are hard stops if threshold is not met.
- No shortcuts or phase skipping.

### Mode 2: Fast-Track (Skip Negotiable Gates)
**Use Case**: Hotfixes, minor improvements, refactors on well-tested code.
**Behavior**:
- Skip Discover if `requirements/SCOPE_LATEST.yaml` exists.
- Skip Elaborate if design decisions are already locked.
- Skip Verify if coverage ≥95% + all tests PASS.
- Soft gates auto-approve if baseline conditions are met.

### Mode 3: Ad-Hoc (Legacy, Warnings Only)
**Use Case**: Exploration, prototyping, spikes (NOT for production).
**Behavior**:
- Gates emit warnings but do not block execution.
- User can manually skip any phase.
- No enforced quality thresholds.

---

## Gate & Checkpoint Types
*See `docs/references/gates.md` and `docs/references/checkpoints.md` for full specs.*

- **Confirm**: Requires human "yes/no" decision.
- **Quality**: Automated threshold check (e.g., coverage, audit score).
- **Safety**: Destructive actions require risk acknowledgment.
- **Transition**: Mandatory artifact presence check.
- **slopcheck**: Identification of [SUS] (Suspicious) or [SLOP] (High-risk) packages.

---

## Error Recovery & State
Orchestrate maintains `specs/state.yaml` to track:
- **Current flow / epic**: `active_flow`, `active_epic_id`, `epic_cycle`.
- **Handoff**: `last_step_completed`, `open_decisions`, `required_reading`, `next_skill`.
- **Git**: `branch`, `hash` for session continuity.
- **Progress**: Story status lives in `execution-status.yaml` only.

In the event of a crash or exit, run `claude /orchestrate --resume` to pick up exactly where the session left off.
