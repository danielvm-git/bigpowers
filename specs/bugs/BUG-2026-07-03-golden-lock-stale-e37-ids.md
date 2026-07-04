---
bug_id: BUG-2026-07-03-golden-lock-stale-e37-ids
status: open
severity: low
scope: ci
title: "e42 golden workflow renamed from e37 but lock file internals still carry 19 e37 identifiers"
risk_level: low
---

## Summary

During the epic renumber, the golden-story workflow files were renamed
`e37-golden-deepseek.*` → `e42-golden-deepseek.*`, but the compiled lock file
`.github/workflows/e42-golden-deepseek.lock.yml` still contains **19 internal
`e37` references**, including `GH_AW_WORKFLOW_ID: "e37-golden-deepseek"`. The
filename now says e42 (Golden Stories) while e37 is BCP Plus Counting — the
internal IDs lie about which epic owns the workflow, and gh-aw telemetry/cache
keys will disagree with the filename.

## Root Cause

The `.md` and `.lock.yml` were renamed on disk (git mv) rather than the source
`.md` being edited and **recompiled** via gh-aw. The lock file is a generated
artifact; renaming it does not update its embedded IDs.

## Fix Approach

1. Update `GH_AW_WORKFLOW_ID` and the workflow name/ref in
   `.github/workflows/e42-golden-deepseek.md`.
2. Recompile via gh-aw so the `.lock.yml` regenerates with e42 identifiers.
3. Confirm the e42s01 verify command's target matches the recompiled file.

## Verify Steps

- [ ] `grep -c 'e37' .github/workflows/e42-golden-deepseek.lock.yml | grep -q '^0$' && echo OK`
- [ ] `grep -q 'GH_AW_WORKFLOW_ID: "e42-golden-deepseek"' .github/workflows/e42-golden-deepseek.lock.yml && echo OK`
