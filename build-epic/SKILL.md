---
name: build-epic
model: sonnet
description: Eight-step epic build cycle — reads state.yaml, execution-status.yaml, and one epic capsule; updates status via bp-yaml-set or direct edit. Resume mode runs one step per invocation. Use instead of ad-hoc execute-plan for release work.
---

# Build Epic

Scope: one story. Called by orchestrate-project Phase 4. Not a replacement for orchestrate-project.

Orchestrates the **build** flow for a single epic: survey → plan tasks → kickoff → TDD → verify → audit → commit → release.

> **HARD GATE** — Set `specs/state.yaml` `active_flow: build_epic` and `active_epic: eNN` before starting.
>
> **HARD GATE** — Not on `main`/`master` before step 3 (kickoff-branch).

## Eight steps (`epic_cycle` in state.yaml)

| Step | Skill / action |
|------|----------------|
| 1 | `survey-context` — confirm epic + story |
| 2 | `plan-work` — flesh out story `tasks[]` in `specs/epics/eNN-slug/epic.yaml` |
| 3 | `kickoff-branch` — feature branch + clean baseline |
| 4 | `develop-tdd` — red-green per task |
| 5 | `verify-work` — UAT + mechanical gates |
| 6 | `audit-code` — **non-optional gate** (pass/fail; fail → loop back to step 4) |
| 7 | `commit-message` — Conventional Commits draft |
| 8 | `release-branch` — PR or solo land |

## Process

1. Read `specs/state.yaml`, `specs/execution-status.yaml`, `specs/release-plan.yaml`, active `specs/epics/eNN-slug/epic.yaml`.
2. **BCP Tracking (Step 2):** After `plan-work` completes, read the `bcps:` count (Business Complexity Points story size) from the epic capsule and carry it into `state.yaml` as `epic_cycle.story_bcps = N`.
3. If `epic_cycle.step` missing, set to `1`.
4. Run **only the current step** (resume mode) unless user asked for full auto-run.
5. After step verify passes, increment `epic_cycle.step` in `state.yaml` (or `bash scripts/bp-yaml-set.sh` if available).
6. On story complete, set `execution-status.yaml` story key to `done`; run `bash scripts/sync-status-from-epics.sh`.

### Step 6 — audit-code gate (non-optional)

After step 5 (verify-work) completes successfully, step 6 runs `audit-code` automatically in `--gate` mode:

1. **Run audit:** Invoke `audit-code --gate` on the complete diff for this story.
2. **Pass (exit 0):** All checklist sections pass → advance to step 7 (commit-message). Record `epic_cycle.audit_result: pass` in `state.yaml`.
3. **Fail (exit 1):** One or more checklist sections fail → **reset `epic_cycle.current_step` to `4`** (develop-tdd) and add the failing section IDs to `completed_steps` as `"1,2,3,4,5,6(fail: ...)"`. Record `epic_cycle.audit_result: fail` in `state.yaml`. Do NOT advance past step 6 until audit passes.
4. **Audit artifact:** Full audit report saved to `specs/verifications/AUDIT-<epic>-<story>.md` regardless of pass/fail, for reviewer traceability.

## Handoff

Write `handoff.next_skill` and `handoff.context` in `state.yaml` when pausing mid-epic.

## Verify

→ verify: `grep -q 'active_flow: build_epic' specs/state.yaml && test -f specs/epics/*/epic.yaml`
