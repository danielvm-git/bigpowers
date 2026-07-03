# BUG-2026-07-03T133500: Negative-path self-test — compliance step scripts have no proof they can fail

## Problem

**Actual behavior:** ~90 Gherkin step scripts in `specs/verifications/features/` are exercised only on passing codebases. There is zero evidence any of them can detect a violation and FAIL. `harness-smoke.feature` is a trivial pass-path smoke ("a skill exists → it should pass") — it does not test that steps can say no.

**Expected behavior:** A dedicated self-test (G-07 golden check or harness-smoke extension) that seeds a known violation in a fixture and asserts the corresponding step script FAILs. ~90 step scripts currently have zero proof they can detect violations — they may all pass vacuously.

**How to reproduce:**
1. Examine `harness-smoke.feature` — confirms skills pass, never tests failure
2. Run `grep -r "FAIL" specs/verifications/features/` — step scripts check for FAIL keywords, but nothing proves those checks actually fire on bad input
3. The GAP-1 bug (validate-okf.sh exit 0 on usage errors) is exactly this class: a validator that passes vacuously

## Root Cause Analysis

**This is the GAP-1 bug class applied to the entire compliance machinery.** GAP-1 demonstrated that a validator can exit 0 (success) even when it should fail because no test ever sends bad input. The compliance suite's 90 step scripts share this vulnerability: they are verified only on the clean bigpowers codebase. The `--judge gemini` option introduces a stochastic element but the default binary path has no negative-path proof.

**Existing hardening:** `harness-smoke.feature` (Scenario: Harness integrity check) confirms skills have verify commands and the feature directory exists. This is a structural sanity check — it does not test that step scripts can detect violations.

**Risk level:** HIGH — the same class of bug that caused GAP-1 (fail-open validator in CI) could exist in any of the 90 step scripts. The safety net has no proof it catches anything.

## TDD Fix Plan

### 1. RED: Create a fixture with a known violation
**GREEN:** Create `specs/verifications/fixtures/negative-path/` containing a minimal skill with a deliberate violation (e.g., SKILL.md with no verify command, or >150 lines without REFERENCE.md).
**verify:** `test -d specs/verifications/fixtures/negative-path/ && echo OK`

### 2. RED: Write a negative-path self-test feature
**GREEN:** Add `negative-path.feature` (or extend harness-smoke.feature) with scenarios that feed the fixture to step scripts and assert FAIL exit codes. At minimum: one scenario per feature category (cleancode, akita, conventions, etc.) proving at least one step in each can detect a violation.
**verify:** `bash scripts/audit-compliance.sh --negative-path-fixture specs/verifications/fixtures/negative-path/ 2>&1 | grep -q 'FAIL' && echo OK`

### 3. RED: Wire into CI as a pre-merge gate
**GREEN:** Add negative-path run to sync-skills.yml or a dedicated G-07 golden workflow. Gate on: all step scripts in the negative-path scenario produce FAIL on known-bad input.
**verify:** `grep -q 'negative-path' .github/workflows/sync-skills.yml && echo OK`

### 4. REFACTOR: Audit remaining step scripts for fail-open patterns
**GREEN:** Review the 90 step scripts for patterns like `|| true`, `2>/dev/null` on assertion commands, exit 0 on usage errors. Any found become individual bugs.
**verify:** Manual review — no mechanical test possible (this is the whole problem).

## Acceptance Criteria

- [ ] Fixture with deliberate violation exists and is validated as genuinely bad
- [ ] Negative-path self-test (feature file or golden workflow) runs step scripts against the fixture
- [ ] At least one step script per feature category is proven to FAIL on bad input
- [ ] CI gate runs the negative-path self-test
- [ ] No step script exits 0 when it should exit non-zero (the GAP-1 pattern is absent from the compliance suite)
- [ ] Audit of remaining 90 step scripts for fail-open patterns is tracked as a task

## Resolution

**Fixed** — 2026-07-03 by fix-bug orchestrator (fix-negative-path-self-test branch).

**Changes:**
- Created `specs/verifications/fixtures/negative-path/` with 5 deliberate violations across 4 feature categories (akita, cleancode, conventions, superpowers)
- Created `scripts/golden-g07-negative-path.sh` — standalone self-test that runs 5 step scripts against the fixture and asserts they exit non-zero
- Added G-07 to golden suite (`scripts/run-golden-suite.sh`) as a hard gate
- G-07 runs in CI via the golden suite workflow

**Verified:**
- 5/5 step scripts correctly detect violations on negative-path fixture
- Compliance (audit + doctrine): all checks pass
- Golden suite: G-07 PASS
