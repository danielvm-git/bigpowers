---
bug_id: BUG-2026-07-06-trace-requirement-stories-oversized
status: fixed
severity: medium
scope: skills/trace-requirement
title: "trace-requirement: Underlying story trace script trace-stories.py exceeds 300-line limit"
---

# BUG-2026-07-06-trace-requirement-stories-oversized

## Problem

**Actual behavior:** The Python file `scripts/lib/trace-stories.py` responsible for scanning story requirements has grown to 302 lines, violating the 300-line context window limit.

**Expected behavior:** Python helper scripts should remain strictly under 300 lines of code.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure in `akita.feature` (file size > 300).

## Root Cause Analysis
During refactoring, core parsing logic from `trace-stories.sh` was migrated to Python. The resulting script is slightly over the cap (302 lines).

## TDD Fix Plan

1. **GREEN:** Compact section dividers and module docstring in `trace-stories.py` to bring line count under 300 without changing behavior.
   **verify:** `wc -l scripts/lib/trace-stories.py | awk '{if($1<300) print "OK"; else print "FAIL: "$1}'`

2. **GREEN:** Trace engine still passes strict mode.
   **verify:** `bash scripts/trace-stories.sh --strict`

## Acceptance Criteria

- [x] `trace-stories.py` under 300 lines (283 after fix)
- [x] `trace-stories.sh --strict` passes
- [x] Golden suite 9/9 PASS

## Resolution

**Fixed:** Compacted section dividers and oracle-tier docstring in `scripts/lib/trace-stories.py` — 302 → 283 lines, zero behavior change. Verified `trace-stories.sh --strict` and full golden suite green.
