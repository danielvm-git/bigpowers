# e26s04: audit-code / request-review integration

**BCPs:** 3
**Status:** todo

## Problem

`audit-code` and `request-review` have no security dimension. The pre-review
self-check and the independent reviewer both evaluate code quality but not
security posture. Security bugs bypass both gates.

## Proposed change

### audit-code
Add a security checklist item to the pass/fail checklist:

```
[ ] Security: diff scanned — no unaddressed HIGH findings
    (or deviations documented in specs/security/EXCEPTIONS.md)
```

If `specs/security/REVIEW.md` exists from a recent scan, check it. If not,
the checklist notes "no recent scan — run security-review first" as a warning
(not a block).

### request-review
The reviewer prompt gains a **security focus area** section that:
- Reads the epic's `specs/security/epics/<id>/THREAT_MODEL.md` if it exists
- Injects the relevant vulnerability categories as reviewer focal points
- Carries the false-positive exclusion rules so the reviewer doesn't waste
  context on known-safe patterns (React XSS, env var trust, UUID validity)
- Tags the review as `security-sensitive: true` if THREAT_MODEL risk is HIGH+

## Gherkin

```gherkin
Given audit-code is running against a codebase with unaddressed HIGH findings in REVIEW.md
When the checklist is generated
Then the security item shows "FAIL — unaddressed HIGH findings"
And deviations must be documented in EXCEPTIONS.md to pass

Given request-review is dispatching for an epic with HIGH+ threat model
When the reviewer prompt is built
Then it includes the vulnerability categories from the epic's THREAT_MODEL.md
And includes the false-positive exclusion rules
```

## Acceptance Criteria

- [ ] `audit-code/SKILL.md` has security checklist item in pass/fail section
- [ ] `request-review/SKILL.md` injects THREAT_MODEL categories into reviewer prompt
- [ ] False-positive exclusion rules carried into request-review
- [ ] Security-sensitive tag documented for HIGH+ risk epics

## Files to modify

- `.pi/skills/audit-code/SKILL.md`
- `.pi/skills/request-review/SKILL.md`

## Verify

```bash
grep -c "Security:" audit-code/SKILL.md | awk '{if($1>=1) print "OK: security item in audit-code"; else print "FAIL"}'
grep -c "THREAT_MODEL\|false-positive\|false.positive\|security.sensitive" request-review/SKILL.md | awk '{if($1>=1) print "OK: security in request-review"; else print "FAIL"}'
```
