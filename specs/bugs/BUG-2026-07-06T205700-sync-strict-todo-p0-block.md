---
bug_id: BUG-2026-07-06T205700
status: fixed
severity: high
scope: ci
title: "Sync Skills on Push fails — --strict flags todo e45 P0 stories with 0% coverage"
security_impact: NONE
ci_run: https://github.com/danielvm-git/bigpowers/actions/runs/28822155555
---

# BUG-2026-07-06T205700: Sync Skills strict gate blocks on planned todo stories

## Problem

**Actual:** **Sync Skills on Push** fails on `main` after the e37 archive commit (`604c4b0e`). Run: [28822155555](https://github.com/danielvm-git/bigpowers/actions/runs/28822155555).

Failed step: **Traceability gate (--strict)**

```
trace-stories.sh: STRICT FAIL — P0 stories with 0% coverage: e45s03, e45s06, e45s20, e45s23, e45s27, e45s29, e45s30, e45s33, e45s36, e45s39
##[error]Process completed with exit code 2.
```

Steps 1–4 (checkout, stale-lock, sync-skills, validate-doctrine) pass; only the strict trace gate fails.

**Expected:** `--strict` blocks merges when **implemented** P0 stories lack code tags — not when **planned** (`todo`) stories in a future epic (e45) have no implementation yet.

**Reproduce:**

```bash
git checkout main && git pull
bash scripts/trace-stories.sh --strict --json
# exit 2, stderr lists e45s06,e45s20,... (e45s03 may appear if spurious tag absent)
gh run view 28822155555 --log-failed
```

**Security impact:** NONE — process-integrity gap only (CI red); no auth/data exposure.

## Root Cause Analysis

`scripts/lib/trace-stories.py` strict mode (§8) computes the top WSJF quartile as "P0" and fails when any P0 story has `len(links) == 0`, **excluding only `status == "backlog"`**.

After e37 landed, the release plan includes e45 (WSJF 5.0) with 40 `todo` stories. Many share the same WSJF, landing in the P0 quartile. They correctly have zero implementation links — but strict treats them as dark **implemented** stories.

Contributing factors:

- e45 is `planned` / stories `todo` in `execution-status.yaml` — not backlog, so the exclusion does not apply.
- Sync workflow runs `--strict` on every push; any push touching trace output re-exposes the false positive.
- e45s03 sometimes passes locally only due to a spurious `# story: e45s03` tag in `scripts/sync-bugs-registry.sh` (not real implementation).

**Risk level:** High — blocks all Sync Skills on Push runs until strict logic or e45 tagging changes.

## TDD Fix Plan

1. **RED:** `bash scripts/trace-stories.sh --strict --json` exits 2 on `main` listing e45 `todo` stories.
   **GREEN:** Extend strict P0 filter to skip stories where `status in ("backlog", "todo", "planned")` OR where parent epic `execution-status` is not `done`/in-progress. Prefer status-based skip to match gate intent.
   **verify:** `bash scripts/trace-stories.sh --strict --json; echo $?` → 0 on current main

2. **RED:** No regression test for todo exclusion.
   **GREEN:** Add headless test in `scripts/test-trace-strict.sh` (or extend golden suite) with fixture: one P0 `todo` story with 0 links must not fail strict.
   **verify:** `bash scripts/test-trace-strict.sh`

3. **RED:** Remove spurious e45s03 tag from `sync-bugs-registry.sh` if fix (1) makes it unnecessary for local green.
   **GREEN:** Tag only reflects actual story scope.
   **verify:** `grep -n e45s03 scripts/sync-bugs-registry.sh` → no `# story: e45s03` unless e45s03 is implemented

**REFACTOR:** Document strict semantics in `scripts/lib/trace-stories.py` docstring and `specs/tech-architecture/` trace section — P0 gate applies to active/done stories only.

## Acceptance Criteria

- [x] `bash scripts/trace-stories.sh --strict --json` exits 0 on `main`
- [ ] Sync Skills on Push green on fix branch (`gh run watch`)
- [x] Strict still fails when a **done** P0 story has zero links (negative test)
- [x] `todo` / `planned` e45 stories remain visible as dark in matrix output but do not block CI

## Resolution

**Fixed:** 2026-07-06
**Root cause confirmed:** Strict P0 gate treated `todo`/`planned` stories as implemented, failing on zero links for future e45 work.
**Fix applied:** Added `_STRICT_UNIMPLEMENTED_STATUSES` (`backlog`, `todo`, `planned`) filter in `scripts/lib/trace-stories.py` §8; removed spurious `# story: e45s03` from `scripts/sync-bugs-registry.sh`.
**Hardening added:** `scripts/test-trace-strict.sh` — integration + fixture tests for todo pass / done fail.
**Evidence:** `bash scripts/trace-stories.sh --strict --json` exit 0; `bash scripts/test-trace-strict.sh` PASS; `bash scripts/run-verification-gates.sh` 9/9 PASS
**Commit:** `fix(ci): skip unimplemented P0 stories in trace --strict gate`
