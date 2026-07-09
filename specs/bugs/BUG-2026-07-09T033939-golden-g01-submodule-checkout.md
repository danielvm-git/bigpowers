---
bug_id: BUG-2026-07-09T033939-golden-g01-submodule-checkout
status: fixed
severity: high
scope: ci
title: "Golden Story G-01 fails at checkout — orphan gitlink tests/fixtures/.tmp-v1.x"
security_impact: NONE
risk_level: low
commit_message: "fix(ci): remove embedded git repo tests/fixtures/.tmp-v1.x causing submodule checkout failures"
---

# BUG-2026-07-09T033939: Golden Story G-01 checkout fails on orphan gitlink

## Problem

**Actual:** Run [28782189517](https://github.com/danielvm-git/bigpowers/actions/runs/28782189517) — **Golden Story G-01: CI Gate Regression Test** failed in the `activation` job at step **Checkout .github and .agents folders**. All downstream jobs (`agent`, `detection`, `safe_outputs`, `conclusion`) were skipped.

Error from `actions/checkout` post-checkout cleanup:

```
fatal: No url found for submodule path 'tests/fixtures/.tmp-v1.x' in .gitmodules
The process '/usr/bin/git' failed with exit code 128
```

**Expected:** Sparse checkout of agent config folders completes; the golden workflow proceeds to run compliance gates.

**Reproduce:**

```bash
gh run view 28782189517 --log-failed
git ls-tree 77bfededdf4322d2ce480835d8043d56190c182e tests/fixtures/.tmp-v1.x
# → 160000 commit … (gitlink/submodule mode)
git submodule status   # fails with same error on affected SHAs
```

**Prior history:** Related to golden workflow scope (`BUG-2026-07-03-golden-lock-stale-e37-ids` — stale e37 IDs in lock file; different failure mode). **Novel** symptom: orphan gitlink without `.gitmodules` entry.

**Security impact:** NONE — no exploit path identified. Checkout failure prevents workflow execution; no credential or data exposure.

## Root Cause Analysis

### Phase 1 — Reproduce

- Confirmed failing step: `Checkout .github and .agents folders` in run 28782189517 at SHA `77bfeded` (release 2.68.0).
- At that SHA, `tests/fixtures/.tmp-v1.x` was indexed as mode `160000` (gitlink/submodule) pointing to commit `6ab8c849`.
- Repository has **no** `.gitmodules` file — git cannot resolve the submodule URL.
- `actions/checkout` v7 runs `git submodule foreach` during credential cleanup; git exits 128 when any gitlink lacks a `.gitmodules` URL.

### Phase 2 — Isolate

- Failure is **not** in gh-aw activation logic, secret validation, or sparse-checkout path list — checkout fetch and sparse-checkout succeed; failure occurs in post-checkout submodule cleanup.
- Only one orphan gitlink existed: `tests/fixtures/.tmp-v1.x`.
- The directory was a migrate-spec test fixture that had been accidentally committed as an embedded git repository (nested `.git`) rather than normal tree content.
- Same failure mode would affect any workflow using `actions/checkout` on affected SHAs (including `sync-skills.yml` per fix commit message).

### Phase 3 — Hypothesize

| # | Hypothesis | Falsification |
|---|------------|---------------|
| 1 | Orphan gitlink without `.gitmodules` breaks checkout submodule cleanup | **Confirmed** — `git ls-tree` shows 160000; no `.gitmodules`; error names exact path |
| 2 | Sparse-checkout cone mode omits fixture path but submodule index still triggers foreach | **Rejected** — error occurs after successful checkout of sparse paths; index still lists gitlink |
| 3 | gh-aw checkout step misconfigured | **Rejected** — standard `actions/checkout@v7`; failure is git index state, not workflow YAML |
| 4 | Missing `DEEPSEEK_API_KEY` caused early exit | **Rejected** — secret validation step succeeded; failure is two steps later at checkout |

### Phase 4 — Verify

- **Root cause confirmed:** embedded git repo at `tests/fixtures/.tmp-v1.x` committed as gitlink (160000) without `.gitmodules` entry.
- **Fix landed:** commit `288e20e` (2026-07-06) removed the gitlink and re-added fixture files as normal tree objects (`040000 tree`).
- **Timing:** scheduled run at 09:37 UTC predates fix push (~11:41 UTC local / after 08:41 -0300); run hit `main` at unfixed SHA `77bfeded`.
- **Current main verified:** `git ls-tree HEAD tests/fixtures/.tmp-v1.x` → `040000 tree`; `git submodule status` exits 0; no `.gitmodules`.

**Risk level:** Low — data/index defect, not runtime logic. Recurrence risk remains without a compliance gate detecting new orphan gitlinks.

## TDD Fix Plan

> **Note:** Data fix (cycles 1–2) already shipped in `288e20e`. Cycles 3–4 add regression prevention still outstanding.

1. **RED:** Index contains a gitlink (`160000`) at `tests/fixtures/.tmp-v1.x` with no `.gitmodules` URL — `git submodule status` exits 128.
   **GREEN:** Remove gitlink; commit fixture files as normal tree content (already done in `288e20e`).
   **verify:** `git ls-tree HEAD tests/fixtures/.tmp-v1.x | grep -q '^040000'`

2. **RED:** Golden G-01 activation job fails at checkout on affected SHA (observed run 28782189517).
   **GREEN:** Merge fix to `main`; re-run or wait for next scheduled G-01 — checkout step passes.
   **verify:** `gh run list --workflow e42-golden-deepseek.lock.yml --limit 3`

3. **RED:** No automated guard prevents re-introducing orphan gitlinks in tracked paths.
   **GREEN:** Add doctrine or compliance assertion: fail if any indexed path has mode `160000` while `.gitmodules` is absent or lacks matching URL.
   **verify:** `bash scripts/validate-doctrine.sh 2>&1 | grep -q 'no orphan gitlinks'`

4. **RED:** Regression test does not assert the guard rejects a synthetic gitlink scenario.
   **GREEN:** Add `tests/test-no-orphan-gitlinks.sh` that validates the check passes on clean tree and documents expected failure mode.
   **verify:** `bash tests/test-no-orphan-gitlinks.sh`

**REFACTOR:** None.

## Acceptance Criteria

- [x] `tests/fixtures/.tmp-v1.x` is tree content, not gitlink (288e20e)
- [x] `git submodule status` succeeds on current `main`
- [x] Doctrine/compliance gate detects orphan gitlinks
- [x] Regression test for gitlink guard passes
- [x] Existing tests still pass
- [ ] Golden G-01 workflow dispatch green post-merge

## Resolution

**Fixed** — data fix in `288e20e`; regression gate added in fix branch.

- Root cause: orphan gitlink at `tests/fixtures/.tmp-v1.x` without `.gitmodules` URL broke `actions/checkout` submodule cleanup.
- Prevention: `scripts/lib/check-orphan-gitlinks.sh` wired into `validate-doctrine.sh`; `tests/test-no-orphan-gitlinks.sh` covers clean tree + synthetic orphan.
- Verify: `bash tests/test-no-orphan-gitlinks.sh && bash scripts/validate-doctrine.sh`
