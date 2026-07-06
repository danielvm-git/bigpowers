---
bug_id: BUG-2026-07-06-plan-release-gap-logic-boolean
status: fixed
severity: medium
scope: skills/plan-release
title: "plan-release: check-spec-version-gap.sh contains complex unencapsulated boolean logic (G28)"
---

# BUG-2026-07-06-plan-release-gap-logic-boolean

## Problem

`scripts/check-spec-version-gap.sh` violated G28 by using multi-clause `&&` conditionals inline at lines 87, 90, 106, and 126.

## Resolution

**Fixed:** Extracted `yaml_value_set`, `on_feature_branch`, `is_protected_branch`, `has_dirty_specs`, and `is_blocking_active_flow` helpers. Call sites now use single intention-revealing predicates. Golden suite 9/9 PASS.
