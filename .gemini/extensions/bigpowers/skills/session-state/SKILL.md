---
name: session-state
description: "Track implementation decisions and progress in specs/state.yaml to prevent context rot. Use at the start of a session to load context, and whenever a significant decision is made or a milestone is reached."
---


# Session State
> **HARD GATE** — **HARD GATE** — Session state must be synchronized with git state. If state.yaml conflicts with the working tree, halt and ask for clarification. Do NOT assume state is correct.


Track the current state of implementation, including decisions made, pending tasks, and open questions, to ensure continuity across session boundaries and prevent "context rot."

## Goal

Maintain a single source of truth for the *current* session in `specs/state.yaml`. This complements long-term docs in `specs/tech-architecture/` and delivery detail in `specs/epics/` + `specs/release-plan.yaml`.

Legacy markdown (`specs/archive/STATE.md`, `RELEASE-PLAN.md`) is **not** SoT when YAML exists — use `specs/state.yaml` only.

## Handoff block (cold start)

When ending a session or before a context-heavy spawn, update `handoff` in `state.yaml`:

```yaml
handoff:
  last_step_completed: "e02s01 verify-work passed"
  open_decisions:
    - "Use folder mode for e07 (>5 stories)"
  required_reading:
    - CONVENTIONS.md
    - specs/epics/e02-verification/epic.yaml
  next_skill: develop-tdd
```

## Strategic compaction

| Trigger | Action |
|---------|--------|
| Phase transition (Plan → Build → Verify) | Compact handoff; archive verbose decisions to ADR |
| Context > 70% estimated | Run terse-mode for status only; move detail to specs/ |
| Before `dispatch-agents` wave | `state.yaml` only channel between spawns |

## Workflow

### 1. Initialize (Session Start)

If `specs/state.yaml` does not exist, or if starting a new major phase:

- [ ] Read `specs/release-plan.yaml` and `specs/product/SCOPE_LATEST.yaml`.
- [ ] Get git metadata: `git branch --show-current` and `git rev-parse --short HEAD`.
- [ ] Create `specs/state.yaml` with active flow, git, handoff, and epic cycle if in build.

### 2. Load (Context Refresh)

When starting a new session or after a significant context flush:

- [ ] Read `specs/state.yaml` to understand where the previous agent left off.
- [ ] Read `specs/execution-status.yaml` for story progress (do not infer from release-plan).
- [ ] Verify git matches `state.yaml` `git.branch` / `git.hash`.

### 3. Update (Decision Point/Milestone)

Whenever a significant decision is made or a milestone is reached:

- [ ] Patch via `bash scripts/bp-yaml-set.sh specs/state.yaml git.hash <hash>` (or edit directly).
- [ ] Update `handoff.open_decisions` with rationale.
- [ ] Update `epic_cycle` when advancing `ship-epic` steps.
- [ ] Record open questions under `handoff.open_decisions` or an ADR.

→ verify: `bash scripts/validate-specs-yaml.sh`

## Universal checkpoint pattern

Every multi-step flow (>3 steps) in bigpowers uses a cycle counter in `state.yaml`:

| Flow | Cycle key | Step field | Phases/Steps |
|------|-----------|------------|-------------|
| build-epic | `epic_cycle` | `current_step` | 8 (survey → release) |
| fix-bug | `bug_cycle` | `current_step` | 5 (investigate → release) |
| orchestrate-project | `project_cycle` | `current_phase` | 6 (discover → release) |

**Checkpoint:** After each step/phase completes, increment the counter in `state.yaml` and update `handoff.next_skill`.

**Resume:** On session start, read the current step/phase from the cycle key — continue from there, not from step 1.

**Completed steps:** Track completed steps in `completed_steps` (comma-separated string) for audit trail.

## Strategic compaction

Print the current session state: `cat specs/state.yaml`, then display `active_flow` and `handoff.next_skill` for quick reference.

### reset-state (absorbed)

Clear ephemeral session state. Set `active_epic_id`, `active_story_id`, and `epic_cycle.current_step` to `null` in `specs/state.yaml`. Use when ending a phase or starting a new project context.

### compact-state (absorbed)

Archive verbose decisions before a context transition. Move all entries from `handoff.open_decisions` to their appropriate location:

- **System-wide decisions** → `specs/adr/NNNN-slug.md` (global Architectural Decision Records)
- **Epic-scoped decisions** → `specs/epics/<active_epic_id>-<slug>/adr/NNNN-slug.md` (epic-local ADRs, archived with epic)

After archiving, reset `handoff.open_decisions` to an empty list.

## File Format: specs/state.yaml

```yaml
active_flow: build_epic       # planning | build_epic | fix_bug
active_epic_id: e02
active_story_id: e02s01       # required when epic mode: folder
active_bug_id: null           # BUG-2026-06-01T143022 when fix_bug
release:
  target_version: null         # NOT tracked manually — semantic-release decides at merge
  last_tag: v2.28.0            # mirror of `gh release view`, reference only
  last_publish: null
epic_cycle:
  current_step: develop-tdd
  next_skill: develop-tdd
  completed_steps: [kickoff-branch]
bug_cycle:
  current_step: null
  completed_steps: []
git:
  branch: feat/e02-verify
  hash: abc1234
handoff:
  last_step_completed: null
  open_decisions: []
  next_skill: survey-context
```

## Tracking commit ratio

After `release-branch` lands, compute fix-to-feature ratio via:
```bash
FEAT_COUNT=$(git log main --oneline --grep="^feat" | wc -l | tr -d ' ')
FIX_COUNT=$(git log main --oneline --grep="^fix" | wc -l | tr -d ' ')
FIX_PCT=$((FIX_COUNT * 100 / (FEAT_COUNT + FIX_COUNT)))
```
Update `specs/state.yaml` `metrics.commit_ratio` with counts. If `fix_pct > 30%`, emit: `"High fix rate (N%) — deploy + smoke-test recommended"`.

## Anti-Patterns

- **Duplicate Plan**: Don't copy `release-plan.yaml` or epic shards into `state.yaml`.
- **Stale State**: Forgetting to update `state.yaml` after a major refactor or decision.
- **Status in release-plan**: Story/epic status lives only in `execution-status.yaml`.
