---
bug_id: BUG-2026-07-07-compliance-record-cycle-time-oversized
status: fixed
severity: low
scope: ci
title: "Compliance akita file-size gate — record-cycle-time.sh exceeds 300 lines"
---

# BUG-2026-07-07-compliance-record-cycle-time-oversized

## Problem

Akita step `and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh` fails: `scripts/record-cycle-time.sh` is 301 lines.

## Fix

Extract helper functions to `scripts/lib/record-cycle-time-lib.sh`; keep main script as CLI entry under 300 lines.

## Verify

```bash
bash specs/verifications/steps/and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh && echo OK
bash scripts/record-cycle-time.sh report --range HEAD~5..HEAD 2>&1 | head -5
```
