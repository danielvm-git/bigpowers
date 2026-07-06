---
bug_id: BUG-2026-07-06-gate-trace-matrix-oversized
status: open
severity: medium
scope: skills/gate-trace
title: "gate-trace: Underlying matrix compilation engine trace-matrix.py exceeds line limits"
---

# BUG-2026-07-06-gate-trace-matrix-oversized

## Problem

**Actual behavior:** The Python script `scripts/lib/trace-matrix.py` responsible for compiling and evaluating traceability metrics has grown to 523 lines. This violates both the 300-line context window limit and the 500-line newspaper metaphor limit.

**Expected behavior:** Shared python modules and engines should be small, cohesive, and remain under 300 lines of code.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled.
2. Note the failure under `akita.feature` (file size > 300) and `cleancode.feature` (file size > 500).

## Root Cause Analysis
The Python implementation of the traceability matrix compiler compiles file statistics, parses story references, and decides gate verdicts inside a single, tightly-coupled script.

## Proposed Resolution
Extract parsing routines and output rendering functions into separate files or utilities under `scripts/lib/` to reduce `trace-matrix.py` below the 300-line limit.
