---
bug_id: BUG-2026-11-07-spec-version-gap-blocked
status: logged
severity: low
scope: "tooling"
title: "check-spec-version-gap reports ACTIVE_WORK with state.yaml active_flow null"
files_changed: "scripts/check-spec-version-gap.sh, tests/test-spec-version-gap-trigger.sh"
approach: "Name the trigger in the JSON so the cause of the block is visible; keep the block semantics"
risk_level: low
commit_message: "fix(tooling): name the ACTIVE_WORK trigger in check-spec-version-gap (e83s05)"
fix_evidence: "tests/test-spec-version-gap-trigger.sh (red before, green after)"
---

# BUG-2026-11-07-spec-version-gap-blocked

## Reproduction

`bash scripts/check-spec-version-gap.sh` returned `{"gap":true,"blocked":true,"reason":"ACTIVE_WORK"}`
while `specs/state.yaml` had `active_flow: null`.

## Root cause

`check_active_work` has three triggers: (1) a non-main branch, (2) dirty `specs/`, (3) a blocking
`active_flow`. Run from a feature branch or a worktree, trigger 1 fires although `active_flow` is null.
The JSON gave one reason for all three, so the block looked false.
On `main` with a clean tree the same state returns `gap:false` (verified in a scratch repo).

## Resolution

The block is by design: a spec migration must not run mid-work. The defect was the missing diagnosis.
The JSON now carries `trigger` = `feature_branch | dirty_specs | active_flow`.
Status is `logged`, not `fixed`: whether a feature branch alone should block is a behaviour decision
and stays open for the owner. It changes no acceptance criteria of e83.
