---
bug_id: BUG-2026-07-04-stale-bak-features
status: fixed
severity: low
scope: specs
title: "Stale .bak file in features directory — karpathy.feature.bak"
source: GitHub issue #38, specs/DEEPEN-ARCHITECTURE-REVIEW.md §6 Bug 4 + §10
---

# BUG-2026-07-04-stale-bak-features: Stale .bak file in features directory

## Problem

A backup file `specs/verifications/features/karpathy.feature.bak` was left in the features directory. The compliance harness (`audit-compliance.sh`) iterates `.feature` files in a directory — if it picks up `.bak` files, it may produce false results (double-counting or parsing the wrong format).

- **Actual behavior**: A stale `.bak` copy of `karpathy.feature` sits alongside the real `.feature` file.
- **Expected behavior**: No non-`.feature` files in the features directory.
- **How to reproduce**: `ls specs/verifications/features/*.bak` shows the file.

## Root Cause Analysis

During development of the verification features suite, a text editor (or manual backup step) created `karpathy.feature.bak` as a copy of the working `.feature` file and was never cleaned up. The file was committed and persisted in the repo.

**Code path involved**: `audit-compliance.sh` globs for `.feature` files in the features directory. A `.bak` extension is not `.feature`, so the main compliance run would likely skip it (the glob `*.feature` would not match). However, any script or tool that iterates all files in the directory (rather than globbing by extension) could pick it up and produce false results.

**Contributing factor**: No pre-commit hook or CI check existed to warn or reject non-`.feature` files in the features directory.

**Risk level**: Low — the compliance harness uses `*.feature` globs, so false results were unlikely in practice. The primary risk was confusion for future developers unfamiliar with the file's purpose.

**Security impact**: NONE — no security exploit path identified.

## Fix Approach

**Minimal change**: Delete the `.bak` file.

| Aspect | Detail |
|--------|--------|
| Modules affected | `specs/verifications/features/` (directory cleanup) |
| Behaviors verified | File must not exist after cleanup |
| Risk level | Low — data-only change, no logic modification |
| Regression? | No — this is a stale artifact, not a regression |
| Fix type | Data cleanup |

## TDD Fix Plan

Since this is a data-only fix (delete a stale file), standard RED-GREEN cycles do not apply. The fix is a single file deletion:

1. **FIX**: Delete `specs/verifications/features/karpathy.feature.bak`
   **verify**: `test ! -f specs/verifications/features/karpathy.feature.bak && echo OK`

**REFACTOR**: None needed — the fix is a single file deletion.

## Acceptance Criteria

- [ ] `specs/verifications/features/karpathy.feature.bak` does not exist
- [ ] All existing `.feature` files remain intact
- [ ] No other files are affected

## Resolution

- **Status**: Fixed (file was already deleted in commit 21e85ec on main)
- **Verification**: `test ! -f specs/verifications/features/karpathy.feature.bak` → passes (file absent)
- **Registry entry**: Added to `specs/bugs/registry.yaml` (id: BUG-2026-07-04-stale-bak-features)
- **validate-fix result**: PASS — no stale .bak file found
