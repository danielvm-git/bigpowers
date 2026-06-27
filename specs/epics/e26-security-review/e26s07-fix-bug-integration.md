# e26s07: fix-bug / validate-fix integration

**BCPs:** 1
**Status:** todo

## Problem

`fix-bug` → `investigate-bug` → `validate-fix` has no security dimension in its
RCA or hardening steps. A non-security bug might indicate a systemic security
issue (e.g., missing input validation that could be exploited). Security bugs and
non-security bugs get the same treatment.

## Proposed change

### investigate-bug (Step 1 of fix-bug flow)
Add a **security-impact assessment** to the RCA output:

```
Security impact: NONE / LOW / MEDIUM / HIGH / CRITICAL
  - If HIGH/CRITICAL: assign severity HIGH to the bug
  - If MEDIUM+: document exploit path in findings
  - If NONE/LOW: document "no security exploit path identified"
```

### validate-fix (Step 4 of fix-bug flow)
Add a **recurrence hardening check** to the hardening step:

```
Recurrence hardening:
  [ ] Security regression test added? (if security-impact ≥ MEDIUM)
  [ ] False-positive exclusion rule added? (if security-impact ≥ MEDIUM)
  [ ] Threat model updated? (if security-impact ≥ HIGH)
```

## Gherkin

```gherkin
Given a bug with a security exploit path
When investigate-bug runs RCA
Then the bug file includes a security-impact assessment with exploit path
And the bug severity is set to HIGH

Given a security bug (impact ≥ MEDIUM) has been fixed
When validate-fix runs hardening
Then it checks: regression test added, exclusion rule added
And if impact ≥ HIGH, checks that threat model is updated

Given a non-security bug (impact NONE/LOW)
When investigate-bug runs RCA
Then the bug file documents "no security exploit path identified"
And no additional security checks are required
```

## Acceptance Criteria

- [ ] `investigate-bug/SKILL.md` documents security-impact assessment in RCA
- [ ] `validate-fix/SKILL.md` documents recurrence hardening for security bugs
- [ ] Security-impact field in bug file frontmatter (optional, only when relevant)
- [ ] HIGH/CRITICAL impact automatically assigns HIGH bug severity

## Files to modify

- `.pi/skills/investigate-bug/SKILL.md`
- `.pi/skills/validate-fix/SKILL.md`

## Verify

```bash
grep -c "security-impact\|Security impact" investigate-bug/SKILL.md | awk '{if($1>=1) print "OK: security-impact in investigate-bug"; else print "FAIL"}'
grep -c "recurrence hardening\|security.*regression" validate-fix/SKILL.md | awk '{if($1>=1) print "OK: security hardening in validate-fix"; else print "FAIL"}'
```
