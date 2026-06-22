---
story_id: e24s02
title: "scope-work and slice-tasks read planning-context.yaml"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e24s02: scope-work + slice-tasks consume planning-context.yaml

With `specs/planning-context.yaml` written by elaborate-spec, update
`scope-work` and `slice-tasks` to read it automatically at the start of
their process — eliminating re-derivation of feature name, constraints, and
out-of-scope decisions.

## Acceptance Criteria

- [ ] `scope-work/SKILL.md` reads `specs/planning-context.yaml` if present
- [ ] `slice-tasks/SKILL.md` reads `specs/planning-context.yaml` if present
- [ ] Both skills fall back gracefully if the file is absent (no blocking gate)
- [ ] When file is present, skills skip re-asking known facts

## Gherkin Scenarios

```gherkin
Given specs/planning-context.yaml exists with feature_name and constraints
When scope-work runs
Then it reads the context file first
And uses feature_name as the scope title
And pre-populates constraints into the out_of_scope analysis
And does not re-ask "what is this feature?" questions already answered

Given specs/planning-context.yaml is absent
When scope-work runs
Then it proceeds normally (no error, no gate)
And notes "No planning-context.yaml found — starting fresh"
```

## Verification

```bash
grep -c "planning-context\|planning.context" scope-work/SKILL.md | awk '{if($1>=1) print "OK: scope-work reads context"; else print "FAIL"}'
grep -c "planning-context\|planning.context" slice-tasks/SKILL.md | awk '{if($1>=1) print "OK: slice-tasks reads context"; else print "FAIL"}'
```

## Implementation Notes

- Read step is the FIRST step in both skills' Process sections
- Graceful fallback: `test -f specs/planning-context.yaml && echo "Context found" || echo "No context — starting fresh"`
- Pre-population does not lock the user in — they can override any pre-populated value
