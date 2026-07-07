---
bug_id: BUG-2026-07-06-audit-code-auditor-oversized
status: fixed
severity: medium
scope: skills/audit-code
title: "audit-code: Underlying auditor scripts exceed 300-line context window limit"
---

# BUG-2026-07-06-audit-code-auditor-oversized

## Problem

`scripts/audit-compliance.sh` — 334 lines (exceeded 300-line cap).

## Resolution

**Fixed:** Split into `audit-compliance-{judge,runner,report}.sh` libs. Entry script 334 → 64 lines. Compliance + golden suite 9/9 PASS.

| File | Lines |
|------|-------|
| audit-compliance.sh | 64 |
| audit-compliance-runner.sh | 121 |
| audit-compliance-report.sh | 75 |
| audit-compliance-judge.sh | 51 |
