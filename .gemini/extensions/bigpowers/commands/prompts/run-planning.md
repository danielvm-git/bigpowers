
# Run Planning
> **HARD GATE** — **HARD GATE** — Before running planning skills, confirm the epic shard exists and the active story is clear. Planning without a target is noise.


Updates `specs/planning-status.yaml` as discover-phase skills complete.

## Workflows (default keys)

- `survey-context` → `scope-work` → `research-first` → `elaborate-spec` (optional) → `plan-release` → `slice-tasks`

## Process

1. Read `specs/planning-status.yaml` and `specs/state.yaml`.
2. Find first workflow with `status: pending` or `optional` not yet run.
3. Invoke the matching skill; on success set `status: done` for that workflow key.
4. Set `state.yaml` `active_flow: planning` while in this chain.

## Verify

→ verify: `test -f specs/planning-status.yaml && grep -c 'status: done' specs/planning-status.yaml | awk '{if($1>=3) print "OK"; else print "INCOMPLETE"}'`
