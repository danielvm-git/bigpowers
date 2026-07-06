---
bug_id: BUG-2026-07-06-trace-requirement-stories-oversized
status: open
severity: medium
scope: skills/trace-requirement
title: "trace-requirement: Underlying story trace script trace-stories.py exceeds 300-line limit"
---

# BUG-2026-07-06-trace-requirement-stories-oversized

## Problem

**Actual behavior:** The Python file `scripts/lib/trace-stories.py` responsible for scanning story requirements has grown to 301 lines, violating the 300-line context window limit.

**Expected behavior:** Python helper scripts should remain strictly under 300 lines of code.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure in `akita.feature` (file size > 300).

## Root Cause Analysis
During refactoring, core parsing logic from `trace-stories.sh` was migrated to Python. The resulting script is slightly over the cap (301 lines).

## Proposed Resolution
Trim utility helper functions or compact formatting inside `scripts/lib/trace-stories.py` to bring it under 300 lines.
