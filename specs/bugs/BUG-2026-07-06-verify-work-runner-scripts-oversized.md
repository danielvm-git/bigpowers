---
bug_id: BUG-2026-07-06-verify-work-runner-scripts-oversized
status: fixed
severity: medium
scope: skills/verify-work
title: "verify-work: run-verification-gates.sh, validate-okf.sh, and run-golden-suite.sh exceed 300-line limit"
---

# BUG-2026-07-06-verify-work-runner-scripts-oversized

## Problem

Three key runner scripts exceeded the 300-line context window limit:
1. `scripts/run-verification-gates.sh` — 492 lines
2. `scripts/validate-okf.sh` — 381 lines
3. `scripts/run-golden-suite.sh` — 492 lines (duplicate of run-verification-gates.sh)

## Root Cause Analysis

Orchestration logic grew inline; `run-verification-gates.sh` and `run-golden-suite.sh` were full duplicates differing only in `generated_by` metadata.

## Resolution

**Fixed:** Extracted shared golden suite logic to `scripts/lib/golden-suite-{gates,agent,report,run}.sh`. Wrappers are 8 lines each. OKF validators moved to `scripts/lib/validate-okf-kinds.sh` (272 lines); `validate-okf.sh` is 65 lines. Also resolves `BUG-2026-07-06-run-evals-golden-suite-oversized`.

| File | Before | After |
|------|--------|-------|
| run-verification-gates.sh | 492 | 8 |
| run-golden-suite.sh | 492 | 8 |
| validate-okf.sh | 381 | 65 |

## Acceptance Criteria

- [x] All three entry scripts under 300 lines
- [x] `bash scripts/run-verification-gates.sh` — 9/9 PASS
- [x] `bash scripts/validate-okf.sh` — PASS
