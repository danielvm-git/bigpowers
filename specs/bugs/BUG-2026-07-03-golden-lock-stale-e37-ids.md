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

## 4-Phase RCA (diagnose-root)

### Phase 1 — Reproduce
- Counted e37 references in lock file: 19 occurrences across workflow ID, workflow file name, runtime-import path, cache keys, and URL refs.
- Confirmed source `.md` has **zero** e37 references (clean — was correctly renamed).

### Phase 2 — Isolate
- All 19 e37 refs are in the compiled `.lock.yml` artifact only.
- The `.md` source is clean (already uses e42 naming).
- Bug is isolated to the lock file alone — no other artifacts carry stale e37 IDs.

### Phase 3 — Hypothesize
- The lock file is a generated artifact containing embedded workflow identifiers (GH_AW_WORKFLOW_ID, cache keys, runtime-import paths, URL refs).
- These internal IDs are set at compile time from the source `.md` filename.
- A file rename (git mv) only changes the filename on disk — it does NOT update the compiled internal identifiers.
- The correct fix is to recompile: `gh aw compile` reads the source `.md` and regenerates the `.lock.yml` with identifiers matching the current filename.

### Phase 4 — Verify
- Ran `gh aw compile` — successfully regenerated `e42-golden-deepseek.lock.yml`.
- Confirmed: `grep -c 'e37' .github/workflows/e42-golden-deepseek.lock.yml` → 0 matches.
- Confirmed: `grep -q 'GH_AW_WORKFLOW_ID: "e42-golden-deepseek"' .github/workflows/e42-golden-deepseek.lock.yml` → match found.
- All 19 stale e37 identifiers replaced with correct e42 identifiers.

## Fix Approach

1. Update `GH_AW_WORKFLOW_ID` and the workflow name/ref in
   `.github/workflows/e42-golden-deepseek.md`.
2. Recompile via gh-aw so the `.lock.yml` regenerates with e42 identifiers.
3. Confirm the e42s01 verify command's target matches the recompiled file.

## Verify Steps

- [ ] `grep -c 'e37' .github/workflows/e42-golden-deepseek.lock.yml | grep -q '^0$' && echo OK`
- [ ] `grep -q 'GH_AW_WORKFLOW_ID: "e42-golden-deepseek"' .github/workflows/e42-golden-deepseek.lock.yml && echo OK`
