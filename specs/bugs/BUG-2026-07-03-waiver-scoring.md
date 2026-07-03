# BUG-2026-07-03T133000: Waiver-list scoring hides regressions inside intentional FAIL denominator

## Problem

**Actual behavior:** `audit-compliance.sh` counts 85 PASS / 3 FAIL = 96%. The 3 FAILs are documented intentional (usage symbol convention, files >300, files >500), but they live INSIDE the denominator. At 85/88, exactly 2 new regressions can land undetected before the 94% threshold trips (83/88 = 94.3% — still passes).

**Expected behavior:** Move intentional FAILs into an explicit waiver file (step + reason + review date) that is excluded from the denominator. Result: score means "100% of unwaived checks pass" and a single new FAIL trips the gate immediately.

**How to reproduce:**
1. Run `bash scripts/audit-compliance.sh`
2. Observe score: 85 PASS / 3 FAIL = 96% (passes 94% threshold)
3. Introduce two new violations
4. Observe score: 83 PASS / 5 FAIL = 94.3% — still passes
5. The third violation is needed to trip the gate

## Root Cause Analysis

### Phase 1 — Reproduce

**Date:** 2026-07-03 16:20 UTC
**Environment:** macOS, bash 5.x, audit-compliance.sh binary judge mode

Current state: `bash scripts/audit-compliance.sh specs/verifications/features/` → 88 PASS / 0 FAIL = 100%. The vulnerability is latent — no intentional waivers currently inflate the denominator. But the scoring mechanism has no waiver concept:

```bash
# audit-compliance.sh lines 220-231
TOTAL_GLOBAL_ALL=$((TOTAL_GLOBAL_PASS + TOTAL_GLOBAL_FAIL))
SCORE=$(awk "BEGIN { printf \"%d\", $TOTAL_GLOBAL_PASS * 100 / $TOTAL_GLOBAL_ALL }")
if [[ $SCORE -ge 94 ]]; then
  echo "  GATE: PASS"
```

To reproduce the risk: if 3 waived steps entered the denominator (85/88 = 96%), two real regressions could land undetected (83/88 = 94.3% — still passes 94% threshold).

### Phase 2 — Isolate

**Module:** `scripts/audit-compliance.sh` — Global Audit Summary section (tail of file)
**Root cause boundary:** The scoring formula `PASS / (PASS + FAIL) * 100` has no term for waivers. Three structural gaps:

1. No waiver data source — no file to read intentional-OK failures from
2. No denominator subtraction — waived steps count against the score
3. No expiry mechanism — a waived step stays waived forever even if the rationale ages out

`process_step()` in the audit loop treats every step identically: run script → binary judge on exit code. There's no hook to check "is this step waived?" before counting the FAIL.

### Phase 3 — Hypothesize

**H1:** Any intentional waiver dilutes the denominator, creating "free slots" for real regressions.

**Falsification test:** Score formula analysis. Score delta from a single new FAIL = `PASS / [(PASS+FAIL)(PASS+FAIL+1)]`. As FAIL grows (from waivers), delta shrinks → gate becomes less sensitive to real violations. Mathematical proof: with 0 waivers, first violation drops score from 100% to `88/89 = 98%`. With 3 waivers, first real violation drops score from `85/88=96%` to `85/89=95.5%` — below the visibility horizon of the 94% threshold until the 3rd unmasked violation.

**H2:** An expired waiver should re-enter the denominator.

**Falsification test:** Add a waiver with past `review_date`, run audit — gate should FAIL that step.

### Phase 4 — Verify

**H1 verified** — the mathematical dilution is inescapable with the current formula. Every waived FAIL reduces the per-failure score delta, creating free slots for undetected regressions.

**H2 verified by design** — expiry check is a required part of the waiver mechanism.

**Verified root cause:** `audit-compliance.sh` has no waiver subsystem. Step results are counted uniformly: PASS increments one counter, non-zero exit increments another. The denominator is their sum, with no affordance for "this FAIL is documented and accepted."

**Risk level:** MEDIUM — does not cause incorrect behavior in skills, but erodes the safety net that catches regressions. Two real violations can land before the gate trips once 3 waivers exist.

## TDD Fix Plan

### 1. RED: Create waiver file format
**GREEN:** Define `specs/verifications/waivers.yaml` with schema: step_id, reason, review_date, reviewer.
**verify:** `test -f specs/verifications/waivers.yaml && grep -q 'step_id\|reason\|review_date' specs/verifications/waivers.yaml && echo OK`

### 2. RED: Move 3 documented FAILs to waivers
**GREEN:** Add entries for usage-symbol-convention, files-over-300, files-over-500 to waivers.yaml. Each carries the current rationale and a 90-day review date.
**verify:** `grep -c 'step_id:' specs/verifications/waivers.yaml | awk '{if($1==3) print "OK"; else print "FAIL: "$1}'`

### 3. RED: Update audit-compliance.sh to exclude waived steps from denominator
**GREEN:** Before computing score, load waivers.yaml subtract waived steps from total checks, re-compute as `PASS / (total - waived)`. If any unwaived step FAILs, score drops immediately.
**verify:** `bash scripts/audit-compliance.sh | grep -q '100%' && echo OK` (assuming no new regressions)

### 4. RED: Add waiver drift check — any expired waiver FAILs the gate
**GREEN:** On each run, check waivers.yaml for entries with `review_date` in the past. If any expired, emit "EXPIRED WAIVER: {step_id}" and count it as a FAIL (re-enters the denominator).
**verify:** Introduce an expired waiver fixture, run audit-compliance.sh, confirm it FAILs that step.

## Acceptance Criteria

- [ ] `specs/verifications/waivers.yaml` exists with schema
- [ ] 3 documented intentional FAILs moved to waivers, excluded from denominator
- [ ] Score reads "100% of unwaived checks pass" when only waived steps fail
- [ ] A single new unwaived FAIL drops score to <100% immediately
- [ ] Expired waivers FAIL the gate
- [ ] `audit-compliance.sh` still passes with existing codebase
- [ ] Waiver review dates auto-advance or alert on expiry

## Resolution

**Open** — registered 2026-07-03 from PLAN-AUDIT red-team gap list (P0 #1).
