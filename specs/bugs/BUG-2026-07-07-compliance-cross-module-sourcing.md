---
bug_id: BUG-2026-07-07-compliance-cross-module-sourcing
status: fixed
severity: medium
scope: ci
title: "Compliance pocock step flags lib sources using variable paths without literal /lib/"
---

# BUG-2026-07-07-compliance-cross-module-sourcing

## Problem

Pocock step `and-information-should-be-hidden-within-modules-not-leaked.sh` fails on `sync-skills.sh` and `audit-compliance.sh` because `source "$_LIB_DIR/..."` lines lack the literal `/lib/` substring the step uses to whitelist modular sourcing.

## Reproduce

```bash
bash specs/verifications/steps/and-information-should-be-hidden-within-modules-not-leaked.sh
```

## Fix

Use literal `/lib/` in source paths: `source "$(dirname "${BASH_SOURCE[0]}")/lib/<module>.sh"`.

## Verify

```bash
bash specs/verifications/steps/and-information-should-be-hidden-within-modules-not-leaked.sh && echo OK
```
