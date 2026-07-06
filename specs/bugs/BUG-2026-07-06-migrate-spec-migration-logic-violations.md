---
bug_id: BUG-2026-07-06-migrate-spec-migration-logic-violations
status: open
severity: medium
scope: skills/migrate-spec
title: "migrate-spec: migrate-version.sh and check-spec-version-gap.sh exceed line limits and violate boolean encapsulation (G28)"
---

# BUG-2026-07-06-migrate-spec-migration-logic-violations

## Problem

**Actual behavior:** The version migration engine and version gap check scripts fail multiple compliance gates:
1. `scripts/migrate-version.sh` — 727 lines (exceeds 300 and 500 lines limits, uses complex booleans at line 103, and has duplicate symbols).
2. `scripts/check-spec-version-gap.sh` — uses complex unencapsulated boolean logic chains (G28) at lines 87, 90, 106, 126.

**Expected behavior:** Version migration and gap check scripts should remain under 300 lines with encapsulated boolean expressions.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Observe the failures under `akita.feature` (file size > 300) and `cleancode.feature` (file size > 500, complex boolean G28).

## Root Cause Analysis
- `migrate-version.sh` grew excessively as version-specific migration rules were sequentially appended to it.
- Conditional checks for branch names and version flags inside both scripts did not encapsulate complex multi-clause boolean checks into named functions.

## Proposed Resolution
1. Partition `migrate-version.sh` migration steps into separate, dynamic rule scripts.
2. Extract multi-clause conditionals in both scripts into helper functions.
