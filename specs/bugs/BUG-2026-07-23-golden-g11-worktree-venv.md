---
bug_id: BUG-2026-07-23-golden-g11-worktree-venv
status: fixed
severity: medium
scope: ci
title: "G-11 gitignore-venv gate false-fails in fresh git worktrees before .venv exists"
security_impact: NONE
risk_level: low
commit_message: "fix(ci): make G-11 venv-ignore check independent of .venv's on-disk existence"
---

# BUG-2026-07-23: G-11 gitignore-venv gate false-fails in fresh worktrees

## Problem

**Actual:** `bash scripts/run-verification-gates.sh` (part of Preflight, invoked by
`kickoff-branch`) fails gate `g11-gitignore-venv` in a freshly created git worktree,
even though `.gitignore` is byte-identical to the primary checkout and correctly
lists `.venv/`.

**Expected:** The gate should pass whenever `.gitignore` correctly excludes `.venv/`,
regardless of whether a `.venv/` directory happens to exist on disk yet.

**Reproduce:**

```bash
git worktree add ../repro-g11 -b repro-g11
cd ../repro-g11
git check-ignore -v .venv   # exit 1, no output — NOT reported as ignored
bash scripts/golden-g11-gitignore-venv.sh   # FAIL: "git check-ignore .venv (path not ignored)"

# Compare: in the primary checkout, where .venv/ already exists on disk:
cd -; cd /path/to/primary/repo
git check-ignore -v .venv   # exit 0 — ".gitignore:34:.venv/	.venv"
```

**Security impact:** NONE — this is a false-positive CI gate failure, not a defect in
the actual `.gitignore` exclusion (verified: `*.pyc` glob pattern matches correctly
in the same worktree regardless of file existence — only the trailing-slash
directory-only patterns are affected).

## Root Cause Analysis

`git check-ignore` resolves a directory-only pattern (one ending in `/`, e.g.
`.venv/`) by checking whether the given path *is a directory*. When the path does
not exist on disk and is not in the index, git cannot confirm it would be a
directory, so it silently declines to match `.venv/`-style patterns against it and
reports the path as **not ignored** — even though the pattern is present and correct.

This is confirmed by a targeted differential test in the same worktree:

| Path checked | Exists on disk? | Pattern type | Result |
|---|---|---|---|
| `.venv` | No | trailing-slash (`.venv/`) | **not ignored** (false) |
| `venv` | No | trailing-slash (`venv/`) | **not ignored** (false) |
| `__pycache__` | No | trailing-slash (`__pycache__/`) | **not ignored** (false) |
| `foo.pyc` | No | glob (`*.pyc`) | ignored (correct) |
| `.venv` | Yes (`mkdir -p .venv`) | trailing-slash (`.venv/`) | ignored (correct) |

`scripts/golden-g11-gitignore-venv.sh` was written and validated only against the
primary bigpowers checkout, where a real `.venv/` already exists from local Python
setup (`setup-environment`). It was never exercised in a brand-new `kickoff-branch`
worktree, where `.venv/` has not been created yet — every such worktree will trip
this gate going forward, since `kickoff-branch`'s Preflight step runs before any
Python setup.

## Fix

Make the check independent of `.venv`'s on-disk state: create it as an empty
directory first if absent (removing it again afterward, only if this script
created it), so `git check-ignore` always has a real directory to test against.

`scripts/golden-g11-gitignore-venv.sh` — replace the single `git check-ignore -q
.venv` assertion with a create-check-cleanup sequence that doesn't disturb a
pre-existing `.venv/`.

## Verify

```bash
cd /tmp && rm -rf repro-g11 && git -C /Users/danielvm/Developer/bigpowers worktree add /tmp/repro-g11 -b repro-g11-verify 2>&1 | tail -1
bash /tmp/repro-g11/scripts/golden-g11-gitignore-venv.sh && echo "FIX VERIFIED"
git -C /Users/danielvm/Developer/bigpowers worktree remove /tmp/repro-g11 --force
git -C /Users/danielvm/Developer/bigpowers branch -D repro-g11-verify
```
