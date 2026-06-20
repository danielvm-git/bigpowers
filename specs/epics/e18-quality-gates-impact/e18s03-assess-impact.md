---
story_id: e18s03
title: "Wire assess-impact into build-epic step 2 (plan-work)"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e18s03: assess-impact integration

Integrate `assess-impact` into `build-epic` to catch cross-module blast radius before coding.

In BigBase, late-stage bugs like "redeployment stale content" and "ghost running status"
came from component interactions that impact analysis might have caught.

## Acceptance Criteria

- [ ] `build-epic/SKILL.md` step 2 invokes assess-impact before writing tasks
- [ ] `assess-impact/SKILL.md` has `--lightweight` mode (fan-in/fan-out only, <10s)
- [ ] Impact report written to `specs/IMPACT-<epic>-<story>.md`
- [ ] Risk score > 7 gates a grill-me session

## Gherkin Scenarios

```gherkin
Given build-epic is at step 2 (plan-work)
And the story will modify dashboard/src/loaders/reader.js
When assess-impact --lightweight runs
Then it finds that reader.js is imported by 4 other modules
And reports: "CAUTION: touches reader.js (used by watcher.js, metrics.js, pipeline-map.js, gate-status.js)"
And the plan-work output includes a "Blast Radius" section
```

## Verification

```bash
grep -c "assess-impact" build-epic/SKILL.md | awk '{if($1>=1) print "OK: assess-impact in build-epic"; else print "FAIL: not integrated"}'
grep -c "lightweight\|--lightweight\|quick.mode" assess-impact/SKILL.md | awk '{if($1>=1) print "OK: lightweight mode"; else print "FAIL: no lightweight mode"}'
```

## Implementation Notes

- assess-impact runs as pre-check in build-epic step 2 before writing implementation tasks
- --lightweight mode: checks module fan-in/fan-out, skips full test coverage mapping
- Risk score > 7 → require grill-me session before proceeding
- Impact report: specs/IMPACT-<epic>-<story>.md with dependents, affected tests, risk score
