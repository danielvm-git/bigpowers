---
bug_id: BUG-2026-07-06-g06-migrate-version-golden
status: fixed
severity: medium
scope: scripts/migrate-version
title: G-06 golden test fails — bash bad substitution + pipefail SIGPIPE in validate check
---

# BUG-2026-07-06: G-06 migrate-version golden test failure

## Problem

**Actual:** `bash scripts/run-golden-suite.sh` fails on gate `g06-migrate-version`. Two symptoms:
1. `migrate-version.sh: line 650: ${#FAILED[@]:-0}: bad substitution` — script aborts under `set -euo pipefail` before completing the migration report.
2. Golden test 4 (v2.20 stamp-only migration) reports `validate-specs-yaml had parse errors` even when YAML is valid.

**Expected:** All 7 G-06 scenarios pass; migrate-version completes with exit 0; golden suite 9/9.

**Reproduce:**
```bash
bash scripts/run-golden-suite.sh
# or
bash tests/run-golden-migrate-version.sh
```

**Security impact:** NONE — test/CI infrastructure only; no exploit path.

## Root Cause Analysis

### Cause 1 — invalid bash array-length syntax

`migrate-version.sh` used `${#FAILED[@]:-0}` (and similar for SUCCEEDED, SKIPPED, STALE_FILES). The `:-default` parameter expansion is not valid on `${#array[@]}` length syntax. Bash errors with "bad substitution"; with `set -e`, the script exits before `exit 0`.

### Cause 2 — pipefail + grep -q SIGPIPE false negative

Golden test 4 checked validate output with:
```bash
bash validate-specs-yaml.sh "$tmp4/specs" 2>&1 | grep -qv 'PARSE ERROR'
```

Under `set -o pipefail`, `grep -q` exits as soon as the first non-matching line is found, closing the pipe. `validate-specs-yaml.sh` then receives SIGPIPE (exit 141) while writing remaining output. Pipefail propagates 141, making the `if` condition false even though validation succeeded.

Risk level: **Low** — CI gate only; no production data corruption.

## TDD Fix Plan

1. **RED:** G-06 stamp-only scenario fails despite valid YAML.
   **GREEN:** Replace grep pipeline with direct exit-code check: `bash "$VALIDATE_YAML" "$tmp4/specs" >/dev/null 2>&1`.
   **verify:** `bash tests/run-golden-migrate-version.sh`

2. **RED:** migrate-version aborts on report generation with bad substitution.
   **GREEN:** Replace `${#ARRAY[@]:-0}` with `${#ARRAY[@]}`; hoist array initializers to script top.
   **verify:** `bash tests/run-golden-migrate-version.sh && bash scripts/run-golden-suite.sh`

## Acceptance Criteria

- [x] G-06 golden test: 7/7 pass
- [x] Golden suite: 9/9 pass
- [x] migrate-version.sh completes without bash substitution errors
- [x] Existing tests still pass

## Resolution

Fixed in working tree:
- `scripts/migrate-version.sh` — valid array-length syntax; defensive array init at top
- `tests/run-golden-migrate-version.sh` — exit-code check instead of grep pipeline

Validated: `bash scripts/run-golden-suite.sh` → 9/9 PASS (2026-07-06).
