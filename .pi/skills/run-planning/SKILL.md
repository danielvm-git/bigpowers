---
name: run-planning
description: "\"DISCOVER-PHASE ADVANCER — Drive the discover-phase checklist (specs/planning-status.yaml) through survey-context → scope-work → research-first → elaborate-spec → plan-release → slice-tasks. NOT a duplicate of plan-work or the planning spine; it orchestrates the pre-coding discover phase only.\""
model: sonnet
---


# Run Planning

> **HARD GATE** — Before running planning skills, confirm the epic capsule exists and the active story is clear. Planning without a target is noise.
>
> **Role:** DISCOVER-PHASE ADVANCER — orchestrates the discover-phase sequence; hands off to the scope-work → slice-tasks → plan-work spine for implementation planning.

Updates `specs/planning-status.yaml` as discover-phase skills complete. This is NOT a duplicate of plan-work — it orchestrates the *pre-coding* discovery phase only (Discover phase in the 6-phase PMBOK lifecycle), handing off to the planning spine for implementation detail.

## When to use

- Starting a brand-new feature or initiative with no prior planning artifacts
- Returning to a stalled initiative and needing to resume the discovery workflow
- After `orchestrate-project` hands off to the Discover phase
- When a new epic emerges from `change-request` and needs to go through full discovery

## Pre-flight

- [ ] Does `specs/planning-status.yaml` exist? If not, create it with the default workflow keys.
- [ ] Does `specs/state.yaml` have `active_flow: planning`? Set it if not already.
- [ ] Is the epic identified in `release-plan.yaml`? The epic must exist before discovery begins.

## Workflows (default keys)

- `survey-context` → `scope-work` → `research-first` → `elaborate-spec` (optional) → `plan-release` → `slice-tasks`

Each key maps to a skill invocation. Optional keys can be skipped; required keys must complete before the phase advances.

## Process

1. **Read state** — Read `specs/planning-status.yaml` and `specs/state.yaml`. Understand where discovery stands: which workflow keys are `done`, which are `pending`, and which are `optional` (can be skipped).

2. **Find next step** — Find the first workflow key with `status: pending`. If the key is `optional`, check if the user wants to run it. If not, mark it `skipped`.

3. **Invoke the matching skill** — Run the skill that matches the workflow key:
   - `survey-context` — where are we?
   - `scope-work` — what's in and out?
   - `research-first` — what already exists?
   - `elaborate-spec` — refine the idea (optional)
   - `plan-release` — sequence epics by WSJF
   - `slice-tasks` — cut vertical slices

4. **Update status** — On successful completion, set `status: done` for that workflow key in `planning-status.yaml`.

5. **Advance** — Set `state.yaml` `active_flow: planning` while in this chain. When all required keys are done, set `handoff.next_skill` to `plan-work`.

## Workflow Keys Schema

In `specs/planning-status.yaml`:
```yaml
workflows:
  survey-context:
    required: true
    status: done
  scope-work:
    required: true
    status: pending
  research-first:
    required: false
    status: optional
    note: "Skip if no external dependencies"
  elaborate-spec:
    required: false
    status: optional
  plan-release:
    required: true
    status: pending
  slice-tasks:
    required: true
    status: pending
```

## Verify

→ verify: `test -f specs/planning-status.yaml && grep -c 'status: done' specs/planning-status.yaml | awk '{if($1>=3) print "OK"; else print "INCOMPLETE"}'`
