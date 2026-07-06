---
bug_id: BUG-2026-07-06-audit-code-auditor-oversized
status: open
severity: medium
scope: skills/audit-code
title: "audit-code: Underlying auditor scripts exceed 300-line context window limit"
---

# BUG-2026-07-06-audit-code-auditor-oversized

## Problem

**Actual behavior:** The compliance audit engine script `scripts/audit-compliance.sh` has grown to 334 lines, violating the 300-line limit.

**Expected behavior:** Auditor scripts should remain under 300 lines of code.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure in `akita.feature` (file size > 300).

## Root Cause Analysis
The script manages feature parsing, environment checks, and reporting logic in a single file, resulting in expansion over time.

## Proposed Resolution
Extract feature file parsing or report generation logic into helper modules.
