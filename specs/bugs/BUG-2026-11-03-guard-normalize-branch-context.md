---
bug_id: BUG-2026-11-03-guard-normalize-branch-context
status: fixed
severity: high
scope: hooks / guard-git / verification
title: "The parity gate pinned the TS side to a feature branch and left the shell side on the real HEAD, so it passed on every PR and went red the moment the merge landed on main"
files_changed: "specs/verifications/fixtures/guard-git-normalize.yaml, scripts/omp-guard-probe.ts, scripts/test-guard-git-normalize.sh, skills/guard-git/SKILL.md"
approach: "Give each fixture row an explicit branch context and run both implementations in it — the probe through branchFor, the shell hook through a throwaway repo checked out on that branch"
risk_level: medium
commit_message: "fix(hooks): give each guard fixture row its own branch context"
---

# BUG-2026-11-03: parity gate green on the PR, red on main

Discovered gate failure — `verification-gates` red on `main` immediately after
merging PR #194 ([run 41667688664](https://github.com/danielvm-git/bigpowers/actions/runs/41667688664),
job 126027326238). The same gate was green on the PR ([run 41667347249](https://github.com/danielvm-git/bigpowers/actions/runs/41667347249)).

## Problem

- **Actual:** on `main`:
  ```
  SHELL_FAIL expected=allow got=block  :: git commit -m "fix(guard): normalize argv"
  PARITY_FAIL shell=block ts=allow     :: git commit -m "fix(guard): normalize argv"
  FAIL (a) shell hook missed 1 of 30 rows
  FAIL (c) shell and TS disagree on 1 of 30 rows
  FAIL (d) conventional commit allowed: rc=2 (want 0) — git commit -m "fix(scope): subject"
  ```
  On the PR the same 30 rows were 30/30 green.
- **Expected:** the same verdict for the same row, wherever the gate runs.

## Root Cause Analysis

1. **Reproduce.** A local clone with `HEAD -> main`, old harness:
   `2 passed, 3 failed` — byte-identical to CI. With the fixed harness: `4 passed`.
2. **Isolate.** The commit rows are **branch-dependent**: "direct commits to `main` are forbidden"
   fires from `CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)`. Two contexts disagreed:
   - probe → `branchFor: () => "fix/guard-git-normalize"`, hardcoded (pinned in `a7345487` so a
     verdict could not depend on the machine — correct instinct, incomplete execution);
   - shell hook → whatever the checkout is. On a PR that is `fix/…` (allow), on a push to `main` it
     is `main` (block). The gate could only ever pass off-branch, so the merge that fixed the
     previous defect created this one: the first run on `main` was the first honest run.
   The `(d)` adjacent assertion `conventional commit allowed` had the same shape and the same fate.
3. **Hypothesize.** The branch is an *input* to the rule, like `GIT_BIGPOWERS_LAND`. Make it explicit
   per row and give both implementations the same value: the probe through `branchFor`, the shell
   hook by running it in a throwaway repo checked out on that branch. No production env override —
   an override that pins the branch would be a bypass vector for real agents.
4. **Verify.** 31 rows green in a feature worktree *and* in a `main` checkout; the two commit rows
   are the same command text with opposite verdicts, which is the property that was untested.

## Fix

- `specs/verifications/fixtures/guard-git-normalize.yaml` — optional `branch:` per row (default: a
  feature branch). New row: `git commit -m "fix(guard): normalize argv"` on `main` → `block`, paired
  with the existing feature-branch `allow`. The pair fails if either side hardcodes a branch.
- `scripts/omp-guard-probe.ts` — accepts `[{command, branch}]`, so `branchFor` answers per row.
- `scripts/test-guard-git-normalize.sh` — creates one throwaway repo per distinct branch (`git init`
  + empty commit + checkout), runs each row's shell hook with that repo as cwd; the `(d)` block runs
  in a feature repo for the same reason.

## Regression guard

The pair of commit rows. A future change that pins either implementation to one branch makes (a) or
(c) fail in whichever context it is not pinned to — including CI's `main` run, where this defect
first surfaced.

## Evidence

```
# feature branch worktree
  PASS (a) shell hook matches all 31 fixture rows
  PASS (b) TS extension matches all 31 fixture rows
  PASS (c) shell and TS agree on all 31 rows
  PASS (d) adjacent rules: commits, pushes, gemini JSON, pi fallback
4 passed, 0 failed

# clone with HEAD -> main, old harness  → 2 passed, 3 failed (the CI failure)
# clone with HEAD -> main, fixed harness → 4 passed, 0 failed
```
