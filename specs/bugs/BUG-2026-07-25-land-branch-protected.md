---
bug_id: BUG-2026-07-25-land-branch-protected
status: fixed
severity: high
scope: scripts
title: "solo-git land-branch.sh fails ungracefully against protected-branch repos, leaving a stranded local commit"
security_impact: NONE
risk_level: medium
github_issue: 92
approach: "Option A — auto-fallback to recovery branch + gh pr create on protected-branch rejection"
files_changed: scripts/land-branch.sh, scripts/lib/land-branch-push.sh, tests/test-land-branch-protected.sh
---

## Summary

**Actual:** `scripts/land-branch.sh` squash-merges a feature branch to local `main`, then runs `git push origin main`. On repos with GitHub branch protection requiring PRs (GH006 / "Changes must be made through a pull request"), the push fails. The squash commit remains on local `main` only. The script exits without recovery guidance or fallback.

**Expected:** On protected-branch rejection, recover gracefully — Option A: branch at `LAND_SHA`, re-point local default to `origin`, push a recovery branch, run `gh pr create`, exit 0. If `gh` fails, print exact recovery commands and exit non-zero.

**GitHub:** [#92](https://github.com/danielvm-git/bigpowers/issues/92)

## Root Cause Analysis

Verified from `scripts/land-branch.sh` L151–154: push is unconditional with no error classification or fallback. The solo-git profile assumes direct-to-main pushes succeed. Branch protection is only discovered at push time via GH006.

No pre-flight `gh api .../protection` check in v1 (out of scope).

## TDD Fix Plan

1. **RED:** No lib helpers for push rejection detection.
   **GREEN:** Add `scripts/lib/land-branch-push.sh` with `is_protected_branch_rejection`, `land_fallback_to_pr`, `land_push_default_branch`.
   **verify:** `bash -n scripts/lib/land-branch-push.sh && grep -q 'is_protected_branch_rejection' scripts/lib/land-branch-push.sh`

2. **RED:** `land-branch.sh` does not source lib or handle GH006.
   **GREEN:** Wire lib into `scripts/land-branch.sh`; on protected rejection, run Option A fallback (recovery branch at `LAND_SHA` → reset local default to `origin` → push recovery branch → `gh pr create`).
   **verify:** `bash -n scripts/land-branch.sh && grep -q 'land-branch-push' scripts/land-branch.sh`

3. **RED:** No regression test for protected-branch push rejection.
   **GREEN:** Add `tests/test-land-branch-protected.sh` with detector unit fixtures and temp bare remote with rejecting `pre-receive` hook.
   **verify:** `bash tests/test-land-branch-protected.sh`

4. **RED:** Fallback failure path silent.
   **GREEN:** When `gh pr create` fails, print exact manual recovery commands; exit non-zero.
   **verify:** covered by test fixtures asserting stderr contains recovery commands.

**REFACTOR:** None beyond lib extraction.

## Acceptance Criteria

- [x] Protected-branch push rejection triggers Option A fallback automatically
- [x] Fallback failure prints exact recovery commands
- [x] `tests/test-land-branch-protected.sh` green with `# story:` tag
- [x] Preflight green in fix worktree
- [x] Closes GH #92 (PR #93)
