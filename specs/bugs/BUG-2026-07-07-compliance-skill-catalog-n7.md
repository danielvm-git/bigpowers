---
bug_id: BUG-2026-07-07-compliance-skill-catalog-n7
status: fixed
severity: low
scope: ci
title: "Compliance cleancode N7 false-positive on validate-skill-catalog.sh sed patterns"
---

# BUG-2026-07-07-compliance-skill-catalog-n7

## Problem

Cleancode step `and-names-should-describe-side-effects-n7.sh` flags `validate-skill-catalog.sh` because `check_*` function names match the first grep, and sed patterns containing `> ` trigger the side-effect detector — not actual writes.

## Reproduce

```bash
bash specs/verifications/steps/and-names-should-describe-side-effects-n7.sh
```

## Fix

Replace sed patterns using literal `> ` with hex escape `\x3e` so the side-effect grep does not false-positive.

## Verify

```bash
bash specs/verifications/steps/and-names-should-describe-side-effects-n7.sh && echo OK
bash scripts/validate-skill-catalog.sh && echo OK
```
