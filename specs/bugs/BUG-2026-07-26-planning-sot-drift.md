---
bug_id: BUG-2026-07-26-planning-sot-drift
status: fixed
severity: high
scope: specs
title: "Planning SoT drifts silently — sync-status-from-epics.sh seeds but never reconciles story status"
security_impact: NONE
risk_level: high
---

# BUG-2026-07-26: Planning source of truth drifts silently in both directions

## Problem

`CONVENTIONS.md` § specs/ declares `specs/execution-status.yaml` the **sole SoT for story
state**. It is currently wrong, in both directions, and no gate detects it.

**Actual — work shipped, SoT says backlog:**

| Story | `epic.yaml` | `execution-status.yaml` | Code evidence |
|---|---|---|---|
| e80s01 | `done` | `backlog` | `skills/develop-tdd`, `enforce-first`, `gate-trace`, `validate-fix` carry `# story: e80s01` |
| e80s02 | `done` | `backlog` | `skills/smoke-test`, `skills/validate-contracts` carry `# story: e80s02` |
| e80s03 | `done` | `backlog` | `scripts/verify-tdd-red-commit.sh` |
| e80s04 | `done` | `backlog` | `scripts/verify-generalize-sweep.sh` |
| e80s05 | `done` | `backlog` | `scripts/verify-cwe-fixture-sync.sh` |

PR #105 (`fix(verify): repair two gates that could not fail (#97, #98)`) is **merged**.

**Actual — work complete, release-plan says open:**

| Epic | `release-plan.yaml` | Reality |
|---|---|---|
| e53 | `status: in_progress`, `capsule_dir: epics/e53-establish-migration-baseline` | All 4 stories `done`; capsule **archived** to `epics/archive/e53-establish-migration-baseline`. **The declared `capsule_dir` path does not exist.** |
| e55 | `status: scoped` | All 3 stories `done`; `constitution.md` shipped (e55s02) |

**Expected:** `execution-status.yaml` agrees with `epic.yaml`; `release-plan.yaml` epic status
and `capsule_dir` resolve to reality; any disagreement fails a gate.

## Root cause

`scripts/sync-status-from-epics.sh` is named as a reconciler and used as one, but is
implemented as a **seeder**. Its own header states the real contract:

```
# sync-status-from-epics.sh — seed execution-status.yaml keys from epic shards
```

Three facts combine into permanent, undetectable drift:

1. **`keys` is preloaded from the file it is about to write** (lines 46–51) — it re-reads
   `execution-status.yaml`'s current values into memory.
2. **`keys.setdefault(sid, "backlog")`** (line 142; line 119 for epics) writes only when the
   key is **absent**. An existing key keeps whatever the file already said.
3. **`epic.yaml`'s `stories[].status` is never read.** Line 146 emits `"status": keys[sid]` —
   the value that came from `execution-status.yaml` itself, never from the epic shard.

So `epic.yaml` `stories[].status` is **write-only data**: `build-epic` step 8 writes it, and
nothing in the repo ever consumes it. Once a story's status is set in the capsule but not
hand-mirrored into `execution-status.yaml`, the two can never re-converge, and no gate in
`run-verification-gates.sh` compares them.

**Verified non-fix:** running `bash scripts/sync-status-from-epics.sh` against the drifted
tree updates `tasks_passing` counters only and leaves all five `status: backlog` values
untouched. Reconciliation by running the existing script is not available.

## Blast radius

- `build-epic`'s Gatekeeper reads `execution-status.yaml` to decide whether the previous
  story is `done` before starting the next. Against a false `backlog` it can re-run
  completed work or stall.
- `change-request` (both modes) ends by calling this script, so the flow's own closing step
  does not do what the skill says it does.
- Any epic whose capsule is archived leaves a dangling `capsule_dir` in `release-plan.yaml`.
- 14/14 deterministic gates pass and compliance scores 94% while the SoT is wrong — the same
  vacuity class already fixed in #96, #97, #98 and #106, one layer up.

## TDD plan (RED first)

New gate script `scripts/golden-g12-status-consistency.sh`:

1. **RED** — with the tree as-is, the gate must **fail**, naming e80s01–e80s05 and the
   dangling `e53` `capsule_dir`. A gate that passes against known-bad input is vacuous
   (G-08 doctrine).
2. **GREEN** — reconcile the data:
   - `execution-status.yaml`: e80s01–e80s05 and e80 → `done`
   - `release-plan.yaml`: e53 → `done`, `capsule_dir` → `epics/archive/e53-establish-migration-baseline`
   - `release-plan.yaml`: e55 → `done`
3. **Self-test** — the gate must prove it can fail: a fixture that mutates one status in a
   temp copy has to be detected, mirroring `golden-g08-anti-vacuity.sh`.
4. **Wire** — add to `scripts/lib/golden-suite-gates.sh` so `run-verification-gates.sh` and
   `.github/workflows/golden-suite.yml` both run it.

## Verify

```
verify: bash scripts/golden-g12-status-consistency.sh
verify: bash scripts/golden-g12-status-consistency.sh --self-test
verify: bash scripts/run-verification-gates.sh
```

## Also closes

`BUG-2026-07-25-anti-vacuity-ci` is **stale-open** in `specs/bugs/registry.yaml`. Its fix
shipped: `.github/workflows/golden-suite.yml:39` runs `run-verification-gates.sh`, issue #99
is closed, PR #101 merged, and `CLAUDE.md`'s Preflight chain already ends on
`trace-stories.sh --strict` rather than the always-exit-0 `check-catalog-drift.sh`. G-08 and
G-10 both PASS. Registry status is corrected to `fixed` as part of this cycle — the registry
having no closing discipline tied to merge is the same defect class as the above.
