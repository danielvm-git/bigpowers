---
bug_id: BUG-2026-07-06-migrate-spec-migration-logic-violations
status: open
severity: medium
scope: skills/migrate-spec
title: "migrate-spec: migrate-version.sh exceeds line limits (G28 in check-spec-version-gap fixed separately)"
---

# BUG-2026-07-06-migrate-spec-migration-logic-violations

## Problem

**Remaining:** `scripts/migrate-version.sh` — 727 lines (exceeds 300/500 limits).

**Fixed elsewhere:** G28 in `check-spec-version-gap.sh` — see `BUG-2026-07-06-plan-release-gap-logic-boolean`.

## Proposed Resolution

Partition `migrate-version.sh` migration steps into lib modules under 300 lines.
