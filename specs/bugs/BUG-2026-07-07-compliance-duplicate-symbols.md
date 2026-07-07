---
bug_id: BUG-2026-07-07-compliance-duplicate-symbols
status: fixed
severity: medium
scope: ci
title: "Compliance akita grep uniqueness — duplicate function names across scripts/"
---

# BUG-2026-07-07-compliance-duplicate-symbols

## Problem

Akita step `then-public-symbols-should-be-unique-enough-to-be-searched-with-grep-5-results.sh` fails with duplicate function names across `scripts/`:
`assign_tier`, `cleanup`, `deny`, `emit_json`, `fail`, `pass`, `render_skill`, `show_help`, `usage`, `wire_context`, `yaml_get`.

## Root Cause

Copy-paste test helpers and adapter stubs share generic names instead of prefixed lib helpers.

## Fix

Extract shared helpers to `scripts/lib/test-assertions.sh` and `scripts/lib/adapter-skill.sh`; rename per-script duplicates with file-specific prefixes.

## Verify

```bash
bash specs/verifications/steps/then-public-symbols-should-be-unique-enough-to-be-searched-with-grep-5-results.sh && echo OK
npm run compliance 2>&1 | grep -E 'SCORE|GATE'
```
