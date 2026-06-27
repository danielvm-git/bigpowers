# e26s05: verify-work integration — Phase 5 security scan

**BCPs:** 4
**Status:** todo

## Problem

`verify-work` runs smoke tests, build, typecheck, lint, full test suite, manual
verification, and a gap-closure loop. There is no security scan. A merge can
pass all existing checks while introducing SQL injection, XSS, or hardcoded
secrets.

## Proposed change

Add **Phase 5 — Security Scan** to the verify-work multi-phase sequence,
positioned after build/typecheck/lint and before the manual UAT step:

```
Phase 1: Cold-start smoke
Phase 2: Build
Phase 3: Typecheck + lint
Phase 4: Full test suite
Phase 5: Security scan        ← NEW
Phase 6: Step-by-step manual verification
Phase 7: Gaps-closure loop
```

### Phase 5 behavior
1. Run `security-review` against the git diff (working tree vs merge-base)
2. Parse the findings report
3. If any HIGH findings with confidence ≥ 8 exist → **block the gate**
4. Findings go into `specs/security/REVIEW.md`
5. Allow documented exceptions via `specs/security/EXCEPTIONS.md` with
   explicit sign-off rationale
6. MEDIUM/LOW findings are advisory (warn, don't block)

### Gap-closure loop
Unaddressed HIGH findings from Phase 5 feed into Phase 7's gap-closure loop
alongside other quality gaps.

## Gherkin

```gherkin
Given verify-work is running and the diff contains a SQL injection vulnerability
When Phase 5 runs the security scan
Then a HIGH finding is reported with confidence ≥ 8
And verify-work blocks with "Phase 5: SECURITY BLOCK — unaddressed HIGH findings"
And findings are written to specs/security/REVIEW.md

Given verify-work is running with no security-relevant changes
When Phase 5 runs the security scan
Then it reports "No security findings"
And verify-work proceeds to Phase 6
```

## Acceptance Criteria

- [ ] `verify-work/SKILL.md` documents Phase 5 between lint and manual verification
- [ ] Phase 5 blocks on HIGH findings with confidence ≥ 8
- [ ] Phase 5 output written to `specs/security/REVIEW.md`
- [ ] EXCEPTIONS.md mechanism documented for intentional deviations
- [ ] MEDIUM/LOW findings warn but don't block
- [ ] Gap-closure loop integrates Phase 5 findings

## Files to modify

- `.pi/skills/verify-work/SKILL.md`

## Verify

```bash
grep -c "Phase 5" verify-work/SKILL.md | awk '{if($1>=1) print "OK: Phase 5 exists"; else print "FAIL"}'
grep -c "SECURITY BLOCK\|security.*block" verify-work/SKILL.md | awk '{if($1>=1) print "OK: blocking gate documented"; else print "FAIL"}'
```
