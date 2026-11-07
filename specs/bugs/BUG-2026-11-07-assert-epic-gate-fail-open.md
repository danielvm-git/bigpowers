---
bug_id: BUG-2026-11-07-assert-epic-gate-fail-open
status: open
severity: high
scope: release gate / scripts/lib/assert-epic-gate.sh
title: "assert-epic-gate.sh release passes on audit evidence from a different branch, so an unaudited 13-commit branch reports audit-code verified"
files_changed: "scripts/lib/assert-epic-gate.sh (proposed)"
approach: "Record the audited commit range in specs/AUDIT_LATEST.md and specs/security/REVIEW.md, and make the gate fail when the recorded range does not cover the current branch diff"
risk_level: medium
commit_message: "fix(gates): fail the release audit gate when the audit covers a different diff"
---

# BUG-2026-11-07: the release audit gate is fail-open on stale evidence

## Problem

- **Actual:** on `danielvm-git/epic-build-end-to-end-0a32fb` (15 commits), the release gate reported:
  ```
  PASS [release]: audit-code verified.
  ```
  while the artifacts it inspected described a different branch:

  - `specs/AUDIT_LATEST.md` — *"Target: `git diff main...HEAD` (2 commits, bugs
    BUG-2026-11-03-guard-git-flag-normalize, …)"* — PR #194.
  - `specs/security/REVIEW.md` — *"Branch `fix/guard-git-flag-normalize` vs `main` (2 commits, PR #194)"*.

  The branch under release had **never been audited**, and the gate said otherwise.
- **Expected:** the release gate fails when the audit evidence does not cover the diff being released.

## Root Cause

`assert-epic-gate.sh` asserts that `specs/AUDIT_LATEST.md` *exists* and contains a passing verdict.
It never compares the audited range against `git rev-list --count origin/main..HEAD`, so any
branch inherits the last branch's audit. The artifact name `AUDIT_LATEST.md` invites this: it is
a single shared file, overwritten by whoever ran `audit-code` most recently.

Same family as `BUG-2026-07-04-tautological-verify` and `BUG-2026-07-25-fail-open-skill-verify`:
the check confirms the artifact exists rather than that the claim is true.

## Impact

A branch can be marked release-ready without any human or agent review. The gate is the last
mechanical barrier before merge, so this weakens every `release-branch` invocation, not just
this one.

## Proposed Fix

1. Have `audit-code` / `security-review` write a machine-readable range:
   ```yaml
   audited_range: { base: <sha>, head: <sha>, commits: <n> }
   ```
2. In `assert-epic-gate.sh release`, fail unless `audited_range.head` is the current HEAD (or an
   ancestor of it) **and** `commits` matches `git rev-list --count base..HEAD`.
3. Print the mismatch explicitly: `audit covers <base>..<head> (2 commits); branch is <n> commits`.

## Acceptance

- With the e83 audit in place the gate passes.
- Reverting `specs/AUDIT_LATEST.md` to the PR #194 text makes the gate fail with a message naming
  the audited range and the current range.
- A self-test fixture covers the stale case, so the gate cannot regress to fail-open.

## Note

This recording does not block landing e83: a genuine audit and security review for the e83 diff
were written during release (`specs/AUDIT_LATEST.md`, `specs/security/REVIEW.md`). The defect is
that the gate would not have caught their absence.
