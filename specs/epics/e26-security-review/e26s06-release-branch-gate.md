# e26s06: release-branch hard gate

**BCPs:** 2
**Status:** todo

## Problem

`release-branch` verifies coverage gates and creates the PR. It has no security
check. A feature branch that passes coverage but contains security vulnerabilities
can merge without anyone noticing.

## Proposed change

Add a **security gate** to `release-branch` that runs before the PR creation step:

1. Check if `specs/security/REVIEW.md` exists and is recent (not stale from a
   previous scan of different changes)
2. If missing or stale → run `security-review` inline
3. If REVIEW.md contains unresolved HIGH findings (confidence ≥ 8, no
   EXCEPTIONS.md entry) → **block the merge**
4. If findings exist but are all documented in EXCEPTIONS.md with sign-off
   rationale → warn but allow
5. No findings or MEDIUM/LOW only → pass

The gate is positioned after coverage verification and before `gh pr create`.

```
Steps:
1. Verify coverage gates
2. Security gate                                    ← NEW
3. Create PR / land branch
4. Clean up worktree
```

## Gherkin

```gherkin
Given a branch with unaddressed HIGH security findings and no EXCEPTIONS.md entry
When release-branch reaches the security gate
Then it blocks with "SECURITY GATE: unaddressed HIGH findings — fix or document in EXCEPTIONS.md"
And does not create the PR

Given a branch with HIGH findings documented in EXCEPTIONS.md
When release-branch reaches the security gate
Then it warns about documented findings
And proceeds to create the PR

Given a branch with no security findings
When release-branch reaches the security gate
Then it passes cleanly
And proceeds to create the PR
```

## Acceptance Criteria

- [ ] `release-branch/SKILL.md` has a security gate step
- [ ] Gate checks `specs/security/REVIEW.md` freshness
- [ ] Gate blocks on unresolved HIGH findings
- [ ] Gate allows with warning when EXCEPTIONS.md documents deviations
- [ ] Gate is positioned after coverage verification

## Files to modify

- `.pi/skills/release-branch/SKILL.md`

## Verify

```bash
grep -c "security gate\|SECURITY GATE" release-branch/SKILL.md | awk '{if($1>=1) print "OK: security gate in release-branch"; else print "FAIL"}'
grep -c "EXCEPTIONS" release-branch/SKILL.md | awk '{if($1>=1) print "OK: exceptions mechanism documented"; else print "FAIL"}'
```
