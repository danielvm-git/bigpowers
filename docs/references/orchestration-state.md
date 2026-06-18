# Orchestration State Tracking Reference

**Source of Truth:** `docs/references/orchestration.md` (pinned)  
**Purpose:** Documents how `specs/state.yaml` is maintained during orchestration and what a healthy state snapshot looks like.

---

## What state.yaml Tracks

The `orchestrate-project` skill maintains `specs/state.yaml` with:
- Current phase (Discover / Elaborate / Plan / Build / Verify / Release)
- Artifacts present (SCOPE_LATEST.yaml, state.yaml, epics/ shards, etc.)
- Decisions locked (so far)
- Risks surfaced
- Next action required

---

## Example state.yaml Snapshot (Build Phase)

```yaml
Current Phase: Build
Current Step: 3/8 (Implement database schema)
Artifacts:
  - SCOPE_LATEST.yaml ✓ (Problem: Add multi-tenant support)
  - state.yaml ✓ (survey: Postgres, SQLAlchemy ORM)
  - adr/0001-tenant-schema.yaml ✓ (Decision: Separate schemas per tenant)
  - epics/e01-multi-tenant.yaml ✓ (8 tasks total)
  - state.yaml handoff ✓ (2/8 tasks complete)

Decisions Locked:
  - Architecture: Separate schemas (not rows)
  - Migration strategy: Blue-green deploy
  - Rollback: 1-hour TTL on old schema

Risks Identified:
  - Concurrency: Need distributed locks (mitigate: use Redis)
  - Performance: Queries slower with schema prefix (monitor: add indexes)

Next Action: Run step 3 verify: command, then confirm before step 4
```

---

## Resuming an Interrupted Session

If a session is interrupted mid-story:

1. Run `/survey-context`
2. It reads `state.yaml epic_cycle` and `handoff.next_skill`
3. It resumes from the exact step where work stopped
4. No manual state reconstruction needed

---

## State Transitions by Phase

| Phase | state.yaml key set | Next action written |
|-------|-------------------|---------------------|
| After Discover | `active_epic_id`, `active_flow` | `handoff.next_skill: elaborate-spec` |
| After Elaborate | `tech_decisions_locked: true` | `handoff.next_skill: plan-work` |
| After Plan | `epic_cycle.story_bcps: N` | `handoff.next_skill: kickoff-branch` |
| After each Build step | `epic_cycle.current_step` | `handoff.next_skill: <next>` |
| After Verify | `uat_confirmed: true` | `handoff.next_skill: audit-code` |
| After Release | `metrics.story_end`, `metrics.cycle_minutes` | `handoff.next_skill: survey-context` |

---

## See Also

- `docs/references/orchestration.md` — 6-phase loop and per-phase DoD
- `docs/references/orchestration-modes.md` — Standard vs Fast-Track vs Ad-Hoc
- `docs/references/workflow-steps.md` — Per-step operational detail
