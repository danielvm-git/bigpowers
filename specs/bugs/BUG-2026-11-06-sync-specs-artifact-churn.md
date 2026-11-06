---
bug_id: BUG-2026-11-06-sync-specs-artifact-churn
status: open
severity: low
scope: "ci / specs"
title: "sync-skills rewrites committed traceability artifacts with worktree paths (local finding)"
files_changed: "scripts/trace-stories.sh, scripts/lib/*wiki*, specs/codebase-wiki, specs/traceability-matrix.json"
approach: "Exclude .claude/worktrees from traceability generation; make the artifacts idempotent"
risk_level: medium
---

# BUG-2026-11-06-sync-specs-artifact-churn: sync-skills rewrites committed traceability artifacts with worktree paths (local finding)

## Problem

Running scripts/sync-skills.sh on a clean main produces 162 changed files (506k deletions) because the committed artifacts were generated with .claude/worktrees present: links list .claude/worktrees/<name>/... paths and story counts differ (138 vs 137). Any preflight that runs sync-skills therefore dirties the tree, so the generated artifacts must be regenerated without worktree paths.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on the epic tracker.
