---
story_id: e24s03
title: "run-planning tracks context lifecycle in planning-status.yaml"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e24s03: run-planning context lifecycle tracking

`run-planning` orchestrates the discover phase but `specs/planning-status.yaml`
doesn't track whether a planning-context.yaml exists or which phase last wrote
to it. Add context lifecycle tracking so `run-planning` can skip re-running
elaborate-spec if the context is fresh.

## Acceptance Criteria

- [ ] `run-planning/SKILL.md` checks `specs/planning-context.yaml` age before running elaborate-spec
- [ ] `specs/planning-status.yaml` gains a `context_capsule` key with `written_at` and `written_by`
- [ ] run-planning skips elaborate-spec if context is < 24h old and user confirms
- [ ] run-planning clears context on feature completion

## Gherkin Scenarios

```gherkin
Given specs/planning-context.yaml was written 2 hours ago by elaborate-spec
When run-planning advances to the elaborate phase
Then it reads planning-status.yaml context_capsule.written_at
And asks "Context from 2h ago exists. Re-run elaborate-spec? [y/N]"
And if N, skips elaborate-spec and advances to scope-work

Given run-planning completes plan-work (phase 6)
When the planning cycle ends
Then it deletes or archives specs/planning-context.yaml
And clears planning-status.yaml context_capsule
```

## Verification

```bash
grep -c "planning-context\|context_capsule\|context.*lifecycle\|written_at" run-planning/SKILL.md | awk '{if($1>=2) print "OK: lifecycle tracking"; else print "FAIL: only "$1" refs"}'
```

## Implementation Notes

- `planning-status.yaml` key: `context_capsule: {written_at: "2026-06-22T...", written_by: elaborate-spec, feature_name: "..."}`
- Age check: `written_at` within 24 hours → offer to skip; older → re-run without asking
- On cycle completion: `rm specs/planning-context.yaml` and clear the key
