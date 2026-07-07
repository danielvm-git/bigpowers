---
bug_id: BUG-2026-07-07-compliance-boolean-chains-g28
status: fixed
severity: low
scope: ci
title: "Compliance cleancode G28 — unencapsulated 3-clause boolean chains"
---

# BUG-2026-07-07-compliance-boolean-chains-g28

## Problem

Cleancode step `and-complex-boolean-logic-should-be-encapsulated-in-named-functions-g28.sh` fails on:
- `scripts/lib/golden-suite-run.sh:35` — agent mode gh/gh-aw availability
- `scripts/lib/sync-post.sh:119` — gemini manifest version mismatch

## Fix

Extract named predicate helpers (`golden_agent_cli_available`, `sync_gemini_version_mismatch`).

## Verify

```bash
bash specs/verifications/steps/and-complex-boolean-logic-should-be-encapsulated-in-named-functions-g28.sh && echo OK
```
