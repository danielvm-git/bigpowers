# e26s03: plan-work / plan-release integration

**BCPs:** 3
**Status:** todo

## Problem

Story tasks in `plan-work` and WSJF scoring in `plan-release` have no security
dimension. A story touching auth tokens or user data gets the same treatment as
a story changing a README. Security-relevant work is invisible to prioritization
and task tracking.

## Proposed change

### plan-work
Each story `tasks[]` gains an optional `security:` field:
- `none` — no security concern (README, docs, cosmetic)
- `low` — defensive coding sufficient (input display, logging)
- `medium` — auth/z boundary, data validation, crypto
- `high` — credential handling, auth bypass surface, injection-prone paths

The field is auto-populated from the epic's THREAT_MODEL.md (e26s02).
When `medium` or `high`, the story's verify steps include "no new security
findings in affected paths."

### plan-release
WSJF scoring gets a **risk multiplier**: if an epic's THREAT_MODEL.md identifies
HIGH or CRITICAL risk, the epics WSJF numerator gets a +2 boost (BV + TC + RR + 2)
to reflect the urgency of addressing security concerns before they ship.

## Gherkin

```gherkin
Given a story tasks.yaml exists for a security-relevant story
When plan-work processes the tasks
Then each task has a security: field with the risk level
And tasks with security: medium or high include "no new findings" in verify

Given an epic with a THREAT_MODEL.md rating of HIGH or CRITICAL
When plan-release computes WSJF
Then the epic numerator gets +2 risk boost
And the rationale is noted in the release-plan.yaml entry
```

## Acceptance Criteria

- [ ] `plan-work/SKILL.md` documents the `security:` field in task structure
- [ ] `plan-release/SKILL.md` documents the +2 risk multiplier for high-risk epics
- [ ] Auto-population from THREAT_MODEL.md is documented in plan-work
- [ ] Verify step for medium/high security stories includes security scan

## Files to modify

- `.pi/skills/plan-work/SKILL.md`
- `.pi/skills/plan-release/SKILL.md`

## Verify

```bash
grep -c "security:" plan-work/SKILL.md | awk '{if($1>=1) print "OK: security field in plan-work"; else print "FAIL"}'
grep -c "risk multiplier" plan-release/SKILL.md | awk '{if($1>=1) print "OK: risk multiplier in plan-release"; else print "FAIL"}'
```
