---
bug_id: BUG-2026-11-03-wiki-indexes-ignored-reports
status: fixed
severity: low
scope: trace-stories / wiki
title: "Generated wikis link to gitignored verification reports, so every Preflight dirties the tree"
files_changed: "scripts/lib/trace-stories.py"
approach: "Exclude gitignored report prefixes (specs/verifications/reports/, allure-results/) from trace-stories.py indexing, then regenerate the wikis once"
risk_level: low
commit_message: "fix(trace): stop indexing gitignored verification reports"
---

# BUG-2026-11-03: generated wikis link to gitignored verification reports

## Problem

- **Expected:** running Preflight (`compliance`, `run-verification-gates.sh`,
  `sync-skills.sh`, `trace-stories.sh --strict`) leaves the working tree clean when
  nothing but generated artifacts changed.
- **Actual:** every gate run writes new timestamped reports under
  `specs/verifications/reports/` (gitignored, `.gitignore:9`). `scripts/lib/trace-stories.py`
  walks the whole tree with `EXCLUDE_PREFIXES = ("specs/archive/", "specs/codebase-wiki/")`
  and no report exclusion, so each new report becomes a `links:` entry in the committed
  wiki pages. Observed during e58s07: after one Preflight, seven `specs/codebase-wiki/*.md`
  files, `index.md`, `specs/traceability-matrix.json` and `specs/TRACEABILITY_LATEST.md`
  were dirty, and the diff contained only links to ignored report files.
- **Reach:** `rg -o 'specs/verifications/reports/[^"]*' specs/codebase-wiki/*.md | wc -l`
  reported **4054** such links already committed.

## Why it matters

The tree can never verify clean, so a real drift signal is indistinguishable from the
timestamp churn, and every commit is forced to carry generator noise. The wiki also
documents as "knowledge links" a set of files that do not exist in version control.

## Fix

Add `specs/verifications/reports/` to `EXCLUDE_PREFIXES` in `scripts/lib/trace-stories.py`
(and consider `.claude/`, `.agents/`, `allure-results/`, which are also gitignored).

Do it deliberately, not as a drive-by: excluding the prefix drops ~4054 existing links, so
the first regeneration rewrites most wiki pages. Verify the traceability gate still passes,
then commit the regeneration on its own so the diff is reviewable.

## Acceptance

```bash
bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh
bash scripts/trace-stories.sh --strict
git status --short    # only intentionally changed files
```

## Resolution

Fixed by `BUG-2026-11-03-trace-indexes-other-worktrees`. The two bugs have the same root
cause. `trace-stories.py` now indexes only the files that `git ls-files --cached --others
--exclude-standard` lists, so all gitignored trees (this reports prefix included) are
skipped without a hand-kept exclude list. The 1,793 reports that were committed before the
ignore rule are tracked, so they keep their links. Only new, untracked reports (37 files at
fix time) stopped being linked. Guard: `scripts/test-trace-ignored-paths.sh`.
