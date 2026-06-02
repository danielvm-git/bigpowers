
# Execute Plan

Execute tasks from the **active epic** (`specs/epics/eNN-*.yaml` story `tasks[]`) one at a time, showing evidence after each step before proceeding.

> **HARD GATE** — Do NOT proceed if on `main` or `master`. Run `kickoff-branch` first.
>
> **HARD GATE** — Active epic must exist with runnable `verify` on each task. If missing, run `plan-release` then `plan-work` or `build-epic`.

## Process

### 1. Read the plan

Read `specs/state.yaml` (`active_epic`, `active_story`) and the matching `specs/epics/*.yaml`. Parse `depends-on` in task descriptions for execution waves.

> **CONTEXT ISOLATION** — Spawn each skill with a **fresh context window**. Pass decisions only through `specs/state.yaml` `handoff` — never rely on prior chat history.

Confirm with the user: step count, skip/reorder, stop-after step.

### 2. Execute step by step

For each task in the active story:

**a. Announce** — task `desc` and `verify` command.

**b. Execute** — code or `delegate-task` / `dispatch-agents` for waves.

**c. Run verify** — must be green before advancing.

**d. Log** — non-obvious decisions in `specs/state.yaml` under `decisions[]` or `handoff` block.

**e. Checkpoint** — ask to proceed unless autonomous mode requested.

**f. Story UAT** — after last task, run manual verification script from story notes or `verify-work`.

On verify failure: fix and re-run; never advance on red.

Update `specs/execution-status.yaml` when a story/epic completes (`bash scripts/sync-status-from-epics.sh` or direct edit).

### 3. Blockers

Report blocker; ask skip/adapt/stop; update epic shard if plan changes.

### 4. Final report

Suggest: `verify-work` → `run-evals` → `audit-code` → `simulate-agents` → `commit-message` → `release-branch`
