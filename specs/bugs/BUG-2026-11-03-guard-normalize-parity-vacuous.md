---
bug_id: BUG-2026-11-03-guard-normalize-parity-vacuous
status: fixed
severity: high
scope: hooks / guard-git / verification
title: "The guard-git parity gate asserted 'allow' for a push to protected main and only compared the destructive-argv rule against the whole hook, so CI went red and the gate was vacuous for the protected-branch rules"
files_changed: "specs/verifications/fixtures/guard-git-normalize.yaml, scripts/omp-guard-probe.ts, scripts/test-guard-git-normalize.sh, extensions/omp-hooks.ts, skills/guard-git/SKILL.md"
approach: "Probe the same pure function the tool_call handler calls (evaluateBashCall) instead of only dangerousGitCommand, fix the fixture row to the protected-branch verdict, and strip GIT_BIGPOWERS_LAND from the harness environment"
risk_level: medium
commit_message: "fix(hooks): judge the TS guard through evaluateBashCall so parity covers every rule"
---

# BUG-2026-11-03: parity gate vacuous for the protected-branch rules

Discovered gate failure — `verification-gates` red on PR #194
([run 41657748958](https://github.com/danielvm-git/bigpowers/actions/runs/41657748958),
job 125992499378), gate `guard-git-normalize`.

## Problem

- **Actual:** CI reported
  ```
  SHELL_FAIL expected=allow got=block :: git push --force-with-lease origin main
  PARITY_FAIL shell=block ts=allow :: git push --force-with-lease origin main
  FAIL (a) shell hook missed 1 of 29 rows
  PASS (b) TS extension matches all 29 fixture rows
  FAIL (c) shell and TS disagree on 1 of 29 rows
  ```
  On a developer machine the same gate was green.
- **Expected:** one verdict per row, identical from the shell hook and the TS
  extension, and the same verdict whether or not the developer's shell happens
  to export `GIT_BIGPOWERS_LAND`.

## Root Cause Analysis

1. **Reproduce.** Checked out the failing SHA (`fb716dab`) into a scratch
   worktree. The shell hook blocks the row when land mode is off:
   ```
   env -u GIT_BIGPOWERS_LAND bash hooks/pre-tool-use.sh <<< '{"command":"git push --force-with-lease origin main"}'
   → BLOCKED: Direct push to protected branch is forbidden.  (exit 2)
   ```
   With the ambient environment (`GIT_BIGPOWERS_LAND=1`, exported on this
   machine) it exits 0. CI has no land mode, so CI blocks — hence the
   local-green / CI-red split.
2. **Isolate.** Three independent defects, one per assertion:
   - **(a) the fixture row was wrong.** The row said `allow` for
     `git push --force-with-lease origin main`. `--force-with-lease` is allowed
     by the *force-push* rule; the *protected-branch* rule still blocks a push
     to `main`. The table pinned a rule combination the guard does not promise.
   - **(b) the TS probe was narrower than the hook it was compared against.**
     `scripts/omp-guard-probe.ts` called `dangerousGitCommand(command)` —
     destructive argv only. The shell hook it was compared to also enforces
     protected-branch push and Conventional Commits. "PASS (b) TS extension
     matches all 29 rows" therefore only proved that the argv table agrees with
     itself; those rules had **no** TS oracle at all.
   - **(c) the harness inherited `GIT_BIGPOWERS_LAND`.** Land mode disables the
     protected-branch block. A gate that reads the developer's shell can be
     green locally and red in CI for the same commit.
3. **Hypothesize.** Export the *decision function* rather than a sub-rule, feed
   it a synthetic branch, and run both sides with land mode stripped — then the
   table cannot disagree with the hook and cannot depend on the machine.
4. **Verify.** After the fix the gate reports 30/30 on (a), (b), (c), and (d)
   from a shell that still exports `GIT_BIGPOWERS_LAND=1`.

## Fix

- `extensions/omp-hooks.ts` — extract `evaluateBashCall(command, {landMode, hasRepo, branchFor})`,
  a pure function holding everything the `tool_call` handler decides
  (destructive argv, protected-branch push, Conventional Commits). The handler
  now only supplies process state. Behaviour is unchanged.
- `scripts/omp-guard-probe.ts` — probe `evaluateBashCall()` with a fixed
  synthetic branch (`fix/guard-git-normalize`) and `landMode: false`, and assert
  statically that the `tool_call` handler still calls it.
- `specs/verifications/fixtures/guard-git-normalize.yaml` — split the row:
  `--force-with-lease origin feature/x` → `allow`, `--force-with-lease origin main`
  → `block` (protected branch), each with the rule it pins.
- `scripts/test-guard-git-normalize.sh` — run both sides with
  `GIT_BIGPOWERS_LAND` removed from the environment.

## Regression guard

`guard-git-normalize` in `scripts/lib/golden-suite-gates.sh` (already wired).
The anti-vacuity property is now structural: (c) compares the same function the
handler calls, so a rule that exists only in the shell hook makes (a) and (c)
disagree.

## Evidence

```
=== test-guard-git-normalize.sh ===
  PASS (a) shell hook matches all 30 fixture rows
  PASS (b) TS extension matches all 30 fixture rows
  PASS (c) shell and TS agree on all 30 rows
  PASS (d) adjacent rules: commits, pushes, gemini JSON, pi fallback
4 passed, 0 failed
```

Run with `GIT_BIGPOWERS_LAND=1` exported (the state that hid the defect).
