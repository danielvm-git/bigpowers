---
story_id: e23s03
title: "Wire evolve-skill to use run-benchmark output"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e23s03: evolve-skill → run-benchmark wiring

`evolve-skill/SKILL.md` says "consume bigpowers-benchmark report" but gives
no concrete instructions for how to locate or read it. Now that `run-benchmark`
and `specs/benchmarks/reports/` exist, update `evolve-skill` to reference the
actual paths and report schema.

## Acceptance Criteria

- [ ] `evolve-skill/SKILL.md` references `run-benchmark` by name
- [ ] Skill documents how to read `specs/benchmarks/reports/BENCHMARK-<skill>-*.yaml`
- [ ] Benchmark gate is explicit: pass@k must be ≥ pre-change baseline
- [ ] Skill documents what to do when no baseline report exists (run baseline first)

## Gherkin Scenarios

```gherkin
Given evolve-skill is invoked for survey-context
When it runs
Then step 1 is "run run-benchmark survey-context to get baseline pass@k"
And step 2 is "propose and apply skill change via plan-work + craft-skill"
And step 3 is "run run-benchmark survey-context again"
And step 4 is "compare pass@k — gate if regression"
And step 5 is "record ADR with before/after pass@k scores"

Given no baseline report exists for the target skill
When evolve-skill runs
Then it says "No baseline found — run run-benchmark <skill> first"
And blocks until a baseline is established
```

## Verification

```bash
grep -c "run-benchmark\|pass.at.k\|benchmark.*report\|BENCHMARK-" evolve-skill/SKILL.md | awk '{if($1>=2) print "OK: evolve-skill wired ("$1" refs)"; else print "FAIL: only "$1" refs"}'
```

## Implementation Notes

- Replace the vague "consume bigpowers-benchmark report" language with explicit steps
- Report path pattern: `specs/benchmarks/reports/BENCHMARK-<skill>-*.yaml` (glob for latest)
- Regression: new pass@k < baseline pass@k → block, loop back to plan-work
- Record decision in `specs/adr/` with before/after pass@k scores
