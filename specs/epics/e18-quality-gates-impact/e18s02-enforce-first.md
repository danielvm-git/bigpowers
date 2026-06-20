---
story_id: e18s02
title: "Wire enforce-first (F.I.R.S.T) into build-epic gate chain"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e18s02: enforce-first integration

Integrate `enforce-first` (F.I.R.S.T rubric) into the build-epic quality gate chain.

Current state: enforce-first exists as a skill but has zero recorded usage. BigBase had
64 test commits but no mechanical enforcement that tests are FAST, INDEPENDENT, and
SELF-VALIDATING.

## Acceptance Criteria

- [ ] `enforce-first/SKILL.md` has a `--quick` mode (checks Fast + Independent + Self-Validating)
- [ ] `build-epic/SKILL.md` step 6 invokes enforce-first after audit-code
- [ ] enforce-first violations appended to audit report

## Gherkin Scenarios

```gherkin
Given a test suite with 15 tests
And one test takes 2 seconds (violates Fast)
And two tests share a database fixture (violates Independent)
When enforce-first runs in --quick mode
Then it reports: "FAIL: 1 slow test (>100ms), 2 interdependent tests"
And the build-epic gate blocks progress until fixed
```

## Verification

```bash
grep -c "enforce-first" build-epic/SKILL.md | awk '{if($1>=1) print "OK: enforce-first in build-epic"; else print "FAIL: not integrated"}'
grep -c "quick\|--quick\|fast.mode" enforce-first/SKILL.md | awk '{if($1>=1) print "OK: quick mode"; else print "FAIL: no quick mode"}'
```

## Implementation Notes

- enforce-first runs as sub-check within build-epic step 6 (after audit-code)
- --quick mode checks F (Fast <100ms/test) + I (Independent, no shared state) + S (Self-Validating assertions)
- Violations appended to audit report file
