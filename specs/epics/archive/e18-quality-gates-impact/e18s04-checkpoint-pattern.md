---
story_id: e18s04
title: "Universalize resume/checkpoint pattern to fix-bug and orchestrate-project"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e18s04: universal checkpoint pattern

Extend the `epic_cycle.step` checkpoint/resume pattern from build-epic to all multi-step flows.

build-epic's 8-step counter in `specs/state.yaml` (`epic_cycle.current_step`) is the backbone
that made 30-epic velocity possible. This same pattern should work for fix-bug and
orchestrate-project.

## Acceptance Criteria

- [ ] `fix-bug/SKILL.md` has 5 numbered steps with checkpoint on each
- [ ] `orchestrate-project/SKILL.md` has 6 numbered phases with checkpoint
- [ ] `specs/state.yaml` schema documents `bug_cycle` and `project_cycle`
- [ ] `session-state/SKILL.md` documents the universal checkpoint pattern

## Gherkin Scenarios

```gherkin
Given a fix-bug session is at step 3 (develop-tdd)
And the session ends mid-step
When the agent resumes with survey-context
Then state.yaml shows bug_cycle.current_step: 3
And fix-bug continues from step 3, not from step 1
```

## Verification

```bash
grep -c "current_step\|checkpoint\|resume" fix-bug/SKILL.md | awk '{if($1>=3) print "OK: checkpoint pattern in fix-bug"; else print "FAIL: only " $1 " refs"}'
grep -c "current_phase\|checkpoint\|resume" orchestrate-project/SKILL.md | awk '{if($1>=3) print "OK: checkpoint pattern in orchestrate-project"; else print "FAIL: only " $1 " refs"}'
```

## Implementation Notes

- fix-bug: 5 steps (investigate → diagnose → TDD → validate → release), tracked in `bug_cycle.current_step`
- orchestrate-project: 6 phases (discover → elaborate → plan → build → verify → release), tracked in `project_cycle.current_phase`
- state.yaml schema additions: `bug_cycle` and `project_cycle` alongside `epic_cycle`
- session-state documents: any flow with >3 steps gets a step counter
