---
bug_id: BUG-2026-11-03-trace-indexes-other-worktrees
status: fixed
severity: medium
scope: trace-stories / wiki
title: "trace-stories links files from other sessions' gitignored .claude/worktrees/ checkouts"
files_changed: "scripts/lib/trace-stories.py, scripts/test-trace-ignored-paths.sh (new), scripts/lib/golden-suite-gates.sh, specs/traceability-matrix.json, specs/TRACEABILITY_LATEST.md, specs/codebase-wiki/"
approach: "Build the file inventory from git ls-files --cached --others --exclude-standard (os.walk minus .claude/ outside a git repo), and use it for both the tag scan and the file heuristic"
risk_level: low
commit_message: "fix(trace): index only files git would track, never other worktrees"
---

# BUG-2026-11-03: trace-stories indexes other worktrees

## Problem

- **Actual:** after Preflight in the main checkout, `specs/traceability-matrix.json` had
  50,473 links to `.claude/worktrees/<other-session>/...` (for example
  `specs/codebase-wiki/e37s01.md` linked
  `.claude/worktrees/cps-manager-cockpit-visual-a472d6/docs/templates/AGENTS.md`).
  The links were not committed: they appeared in the main checkout's working tree only.
  Running the generator from a worktree instead dropped them, so the outputs depended on
  which checkout ran Preflight.
- **Expected:** the outputs depend only on the files in version control.

## Root Cause Analysis

1. **Reproduce:** `bash scripts/test-trace-ignored-paths.sh`. The fixture commits one tagged
   file and puts a copy under a gitignored `.claude/worktrees/other-session/`. Before the
   fix, all 51 fixture stories linked the copy.
2. **Isolate:** `scripts/lib/trace-stories.py` found files in two ways, and neither one
   read `.gitignore`. The tag scan was `grep -rn ... ROOT`, and the file heuristic was
   `os.walk(ROOT)` with a fixed `EXCLUDE_DIRS` list. `.claude/` is gitignored but was in
   neither list.
3. **Same cause:** `BUG-2026-11-03-wiki-indexes-ignored-reports`. New, untracked reports
   under the gitignored `specs/verifications/reports/` were linked in the same way, so each
   Preflight added links. Other gitignored trees were linked too: `.agents/`, `.hermes/`,
   `.mimocode/`, `.zcode/`, `website/src/content/`, `website/dist/`. The 1,793 reports that
   were committed before the ignore rule are tracked, so they keep their links.

## Fix

`_list_repo_files()` returns `git ls-files -z --cached --others --exclude-standard`, so it
includes tracked files and new untracked files, but no ignored files. Outside a git repo it
falls back to `os.walk` and skips `.claude/` too. The tag scan reads that list in Python
(same extensions and regex as the old `grep`). The heuristic uses the same list with the
existing `EXCLUDE_DIRS` / `EXCLUDE_PREFIXES` filter. The file order is now sorted, so it no
longer depends on `readdir`.

Regeneration dropped 108 linked files. `git check-ignore` matches all 108, so no tracked
link was lost. The oracle stats changed from 1062/2838/109 to 926/2748/109
(high/medium/low).

## Regression guard

`scripts/test-trace-ignored-paths.sh` (golden gate `trace-ignored-paths`):

- **Fixture:** gitignored `.claude/worktrees/` and `specs/verifications/reports/` copies
  give no links. The tracked original still links (anti-vacuity).
- **Committed outputs:** `git check-ignore` finds no linked path in
  `specs/traceability-matrix.json` (it skips tracked files), and the matrix and
  `specs/codebase-wiki/` have no `.claude/` links. This check fails on the matrix from
  before the fix.

## Verify

```bash
bash scripts/test-trace-ignored-paths.sh
bash scripts/test-trace-strict.sh
command npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict
```
