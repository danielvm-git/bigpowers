---
bug_id: BUG-2026-07-07-compliance-error-messages
status: fixed
severity: medium
scope: ci
title: "Compliance akita step false-negative — error messages check scoped to audit-compliance.sh only"
---

# BUG-2026-07-07-compliance-error-messages

## Problem

`npm run compliance` scores 93% (below 94% gate). Akita step `and-error-messages-should-include-the-offending-value-and-expected-shape.sh` fails because it greps only `scripts/audit-compliance.sh`, but offending-value echoes live in `scripts/lib/audit-compliance-runner.sh`.

## Reproduce

```bash
bash specs/verifications/steps/and-error-messages-should-include-the-offending-value-and-expected-shape.sh
# exit 1: audit-compliance.sh error messages do not include offending values
```

## Root Cause

Thin-wrapper pattern: main script sources lib modules; verification step checks wrong file.

## Fix

Expand step grep scope to `scripts/audit-compliance.sh` and `scripts/lib/audit-compliance-*.sh`.

## Verify

```bash
bash specs/verifications/steps/and-error-messages-should-include-the-offending-value-and-expected-shape.sh && echo OK
npm run compliance 2>&1 | tail -5
```
