---
bug_id: BUG-2026-07-06T124600
status: fixed
severity: high
scope: ci
title: "Sync Skills on Push fails — trace-stories.sh references unset REPO_ROOT"
security_impact: NONE
files_changed: "scripts/trace-stories.sh, scripts/validate-doctrine.sh"
approach: "Source skill-common.sh, call resolve_repo_root after CLI parsing; validate-doctrine smoke"
commit_message: "fix(ci): restore REPO_ROOT init in trace-stories wrapper"
---

# BUG-2026-07-06T124600: Sync Skills on Push fails — trace-stories.sh references unset REPO_ROOT

## Problem

**Actual:** The **Sync Skills on Push** GitHub Actions workflow fails on every push to `main`. The **Release** workflow on the same commit succeeds. Latest failing run: [28792302477](https://github.com/danielvm-git/bigpowers/actions/runs/28792302477).

Failed step: **Traceability gate (--strict)**

```
scripts/trace-stories.sh: line 20: REPO_ROOT: unbound variable
##[error]Process completed with exit code 1.
```

**Expected:** After sync-skills and validate-doctrine pass, the traceability gate runs `trace-stories.sh --strict --json`, builds the coverage matrix, and the workflow completes green.

**Reproduce:**

```bash
gh run list --workflow="Sync Skills on Push" --limit 5
gh run view 28792302477 --log-failed
git clone --depth 1 https://github.com/danielvm-git/bigpowers.git /tmp/bigpowers-ci-test
cd /tmp/bigpowers-ci-test
bash scripts/trace-stories.sh --help   # exits 1 before printing help
```

**Prior history:** Related to prior CI bugs in scope `ci` (BUG-2026-06-02T164500 sync-skills sed/lockfile; BUG-2026-07-03 trace-engine issues). This is a **regression** introduced by the e28 sync-pipeline refactor — not a recurrence of those bugs.

**Security impact:** NONE — no security exploit path identified. Failure is a shell initialization error; the traceability gate never runs, so coverage enforcement is bypassed in CI (process integrity gap, not an auth/data exposure).

## Root Cause Analysis

During the e28 sync-pipeline refactor (commit `2006f4b`, PR #54), the trace-stories bash wrapper was updated to delegate engine logic to a shared Python module. As part of deduplicating boilerplate across scripts, the wrapper's **repository-root initialization was removed** but never replaced with the shared-library equivalent used by sibling scripts (e.g. sync-skills sources the shared library and calls `resolve_repo_root`).

The wrapper still runs with `set -u` (nounset). It immediately expands `REPO_ROOT` to build path variables for the matrix JSON, trace markdown, release plan, and execution status **before** any argument parsing or Python handoff. Because `REPO_ROOT` is never assigned, bash aborts with "unbound variable" on the first reference.

Contributing factors:

- The sync step and validate-doctrine step succeed, so the failure is isolated to the traceability gate step added in e38.
- The `--help` flag cannot be reached because path variables are initialized before the flag loop — even help invocation fails.
- No smoke test exercises the wrapper standalone under nounset; CI is the first environment that catches the regression.

**Risk level:** High — blocks every push to `main` on the Sync Skills workflow; traceability enforcement is silently skipped whenever the script cannot start.

## TDD Fix Plan

1. **RED**: From a clean clone, invoking the trace-stories wrapper (with or without `--help`) exits non-zero and prints `REPO_ROOT: unbound variable`.
   **GREEN**: At the top of the wrapper (after `set -euo pipefail`), source the shared skill library and call `resolve_repo_root` — matching the pattern used by sync-skills and build-skill-index. Alternatively restore a one-line `REPO_ROOT="$(cd …/.. && pwd)"` assignment; prefer the shared library for e28 consistency.
   **verify**: `bash scripts/trace-stories.sh --help` exits 0 and prints usage

2. **RED**: With repo root resolved, `--strict --json` still fails because path variables are built before `--help` parsing (secondary defect visible only after fix 1).
   **GREEN**: Move path-variable initialization to after CLI flag parsing, or guard with a lazy assignment after `resolve_repo_root`.
   **verify**: `bash scripts/trace-stories.sh --strict --json` exits 0 and writes `specs/traceability-matrix.json`

3. **RED**: No automated guard prevents re-removing repo-root init from the wrapper.
   **GREEN**: Add a one-line smoke assertion to `scripts/validate-doctrine.sh` (or a dedicated `tests/run-trace-stories-smoke.sh`) that runs `bash scripts/trace-stories.sh --help` and expects exit 0.
   **verify**: `bash scripts/validate-doctrine.sh 2>&1 | grep -q 'trace-stories.*ok'` (or `bash tests/run-trace-stories-smoke.sh`)

**REFACTOR**: Confirm all bash wrappers that reference `REPO_ROOT` under `set -u` either source `skill-common.sh` + `resolve_repo_root` or set `REPO_ROOT` inline — grep audit, no behavior change.

## Acceptance Criteria

- [x] `bash scripts/trace-stories.sh --help` exits 0 locally and in CI
- [x] `bash scripts/trace-stories.sh --strict --json` runs without REPO_ROOT error (strict P0 gaps are a separate traceability issue)
- [x] Sync Skills on Push workflow green after fix (runs 28819196939, 28822033490 succeeded)
- [x] Smoke test added so future refactors cannot drop repo-root init silently
- [x] All existing tests still pass

## Resolution

**Fixed:** 2026-07-06
**Root cause confirmed:** e28 refactor removed `REPO_ROOT` assignment from the trace-stories wrapper while keeping `set -u`; path variables expanded before `resolve_repo_root`.
**Fix applied:** Commit `402a0362` — source `skill-common.sh`, defer path setup until after `--help` parsing, call `resolve_repo_root`.
**Hardening added:** `validate-doctrine.sh` smoke check — `trace-stories.sh --help` must exit 0 under nounset.
**Validated:**
- `bash scripts/trace-stories.sh --help` → exit 0
- `bash scripts/validate-doctrine.sh` → `ok: trace-stories.sh --help exits 0`
- Clean clone reproduce → exit 0
- CI: Sync Skills on Push green on commits after `402a0362` (e.g. run 28822033490)
