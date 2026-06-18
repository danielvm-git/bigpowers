---
description: Track implementation decisions and progress in specs/state.yaml to prevent context rot. Use at the start of a session to load context, and whenever a significant decision is made or a milestone is reached.
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

## State Write-Lock Protocol

> **HARD GATE** — Before any write to `specs/state.yaml` or `specs/execution-status.yaml`, acquire `specs/state.yaml.lock`. Release it immediately after the write. A stale lock (>60s) may be force-released.

### Acquire

1. Check if `specs/state.yaml.lock` exists.
2. If it exists, read the agent ID and timestamp inside.
3. If the lock is stale (>60s old), remove it and proceed.
4. If the lock is fresh (<60s), wait 2s and retry (max 15 attempts = 30s).
5. Write `agent_id: <name>\nacquired_at: <ISO-8601>` to `specs/state.yaml.lock`.

### Release

1. After the write to `state.yaml` or `execution-status.yaml` completes:
2. `rm specs/state.yaml.lock`

### Lock format (`specs/state.yaml.lock`)

```yaml
agent_id: session-state
acquired_at: "2026-06-11T14:30:00Z"
```



## Operations

### show-state (absorbed)

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
  target_version: "3.0.0"
  last_tag: null
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

## Anti-Patterns

- **Duplicate Plan**: Don't copy `release-plan.yaml` or epic shards into `state.yaml`.
- **Stale State**: Forgetting to update `state.yaml` after a major refactor or decision.
- **Status in release-plan**: Story/epic status lives only in `execution-status.yaml`.
