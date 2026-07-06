---
bug_id: BUG-2026-07-06-verify-work-runner-scripts-oversized
status: open
severity: medium
scope: skills/verify-work
title: "verify-work: run-verification-gates.sh, validate-okf.sh, and run-golden-suite.sh exceed 300-line limit"
---

# BUG-2026-07-06-verify-work-runner-scripts-oversized

## Problem

**Actual behavior:** Three key runner scripts used by the verification gate fail the 300-line context window limit:
1. `scripts/run-verification-gates.sh` — 492 lines
2. `scripts/validate-okf.sh` — 381 lines
3. `scripts/run-golden-suite.sh` — 492 lines

**Expected behavior:** All scripts must remain under 300 lines.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failures in `akita.feature` (file size > 300).

## Root Cause Analysis
These orchestration and validation scripts grew as new test suites, OKF formats, and verification loops were integrated into the core pipeline.

## Proposed Resolution
Factor out subcommands, JSON generation, and report parsing logic into modular libraries under `scripts/lib/` or separate Python helper scripts.
