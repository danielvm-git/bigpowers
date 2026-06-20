---
story_id: e18s05
title: "Add auto-timing to critical-path skills for stocktake effectiveness"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e18s05: auto-timing

Add automatic timing instrumentation to every critical-path skill so `stocktake-skills`
can report which skills are effective and which are dead weight.

Current state: state.yaml has `metrics.bcps_per_hour` and `metrics.cycle_minutes` but
no skill populates it automatically. build-epic does it manually.

## Acceptance Criteria

- [ ] `specs/state.yaml` has `metrics.skill_timings` section
- [ ] At least 5 skills write timing data (survey-context, plan-work, develop-tdd, verify-work, release-branch)
- [ ] `stocktake-skills/SKILL.md` has effectiveness report generation from timing data
- [ ] `scripts/bp-timing.sh start|end <skill>` helper script exists

## Gherkin Scenarios

```gherkin
Given survey-context has been invoked 12 times
And develop-tdd has been invoked 30 times
When stocktake-skills --full runs
Then it reports: "Most-used: develop-tdd (30 calls, 90 min total)"
And it flags: "Zero calls: assess-impact, run-evals, simulate-agents"
```

## Verification

```bash
grep -c "skill_timings\|timing\|effectiveness" stocktake-skills/SKILL.md | awk '{if($1>=1) print "OK: timing in stocktake"; else print "FAIL: no timing awareness"}'
test -f scripts/bp-timing.sh && echo "OK: timing helper" || echo "WARN: no helper script"
```

## Implementation Notes

- Add `metrics.skill_timings` to state.yaml: per-skill calls, total_seconds, avg_seconds
- `scripts/bp-timing.sh start <skill>` / `scripts/bp-timing.sh end <skill>` helper
- Critical-path skills instrumented: survey-context, plan-work, develop-tdd, verify-work, release-branch
- stocktake-skills --full reads timing data and reports top/bottom performers
