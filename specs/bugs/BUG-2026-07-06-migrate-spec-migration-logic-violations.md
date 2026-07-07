---
bug_id: BUG-2026-07-06-migrate-spec-migration-logic-violations
status: fixed
severity: medium
scope: skills/migrate-spec
title: "migrate-spec: migrate-version.sh exceeds line limits (G28 in check-spec-version-gap fixed separately)"
---

# BUG-2026-07-06-migrate-spec-migration-logic-violations

## Problem

`scripts/migrate-version.sh` — 727 lines (exceeded 300/500 limits).

## Resolution

**Fixed:** Split into lib modules — `migrate-version-{common,plan,transforms,execute,post,run}.sh`. Entry script 727 → 55 lines. G-06 golden 7/7 PASS, golden suite 9/9 PASS.

| File | Lines |
|------|-------|
| migrate-version.sh | 55 |
| migrate-version-transforms.sh | 231 |
| migrate-version-post.sh | 170 |
| (other libs) | ≤119 each |
