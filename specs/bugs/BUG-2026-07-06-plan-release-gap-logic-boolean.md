---
bug_id: BUG-2026-07-06-plan-release-gap-logic-boolean
status: open
severity: medium
scope: skills/plan-release
title: "plan-release: check-spec-version-gap.sh contains complex unencapsulated boolean logic (G28)"
---

# BUG-2026-07-06-plan-release-gap-logic-boolean

## Problem

**Actual behavior:** The version check logic in `scripts/check-spec-version-gap.sh` violates the G28 boolean encapsulation gate by writing multiple three-clause conditionals on a single line (Lines 87, 90, 106, 126).

**Expected behavior:** Complex conditionals should be encapsulated in named, intention-revealing functions.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure in `cleancode.feature` (complex boolean logic G28).

## Root Cause Analysis
Shell conditionals checking arrays and environment flags did not structure the boolean checks into clean function definitions, resulting in long conditional clauses.

## Proposed Resolution
Extract the complex conditionals into named shell functions with intention-revealing names.
