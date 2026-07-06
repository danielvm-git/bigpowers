---
bug_id: BUG-2026-07-06-run-evals-golden-suite-oversized
status: open
severity: medium
scope: skills/run-evals
title: "run-evals: Underlying test suite runner run-golden-suite.sh exceeds 300-line context window limit"
---

# BUG-2026-07-06-run-evals-golden-suite-oversized

## Problem

**Actual behavior:** The core test runner script `scripts/run-golden-suite.sh` has grown to 492 lines, violating the 300-line context window limit.

**Expected behavior:** Orchestrator scripts should remain under 300 lines of code.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure in `akita.feature` (file size > 300).

## Root Cause Analysis
The test runner script manages setup, environment configuration, command-line arguments, and test execution details in a single file.

## Proposed Resolution
Move helper utilities and specific suite configurations into the `scripts/lib/` folder.
