---
bug_id: BUG-2026-07-24-bp-yaml-set-repo-root-unbound
status: fixed
severity: medium
scope: scripts
title: "bp-yaml-set.sh: REPO_ROOT unbound variable — every invocation fails"
discovered: manual (two separate invocations during a fix-bug session, both
  had to fall back to direct file edits)
created: 2026-07-24
---

## Summary

**Actual:** `bash scripts/bp-yaml-set.sh <file> <key> <value>` fails on every
invocation:

```
scripts/bp-yaml-set.sh: line 9: REPO_ROOT: unbound variable
```

**Expected:** Patches the dotted key in the target YAML file via
`scripts/yaml-tools.py`, per `CONVENTIONS.md`'s documented usage: "Patch
runtime keys: `bash scripts/bp-yaml-set.sh specs/state.yaml git.branch
feat/foo`."

**Reproduce:**

```bash
bash scripts/bp-yaml-set.sh specs/state.yaml bug_cycle.current_step 2
# → scripts/bp-yaml-set.sh: line 9: REPO_ROOT: unbound variable
```

## Root Cause Analysis

`scripts/bp-yaml-set.sh` sources `scripts/lib/python-env.sh` (line 5) to
resolve `$PYTHON`, then references `$REPO_ROOT` directly on line 9:

```bash
$PYTHON "$REPO_ROOT/scripts/yaml-tools.py" set "$FILE" "$KEY" "$VAL"
```

But `python-env.sh` only resolves `$PYTHON` — it does not set `$REPO_ROOT`.
`REPO_ROOT` is a separate concern owned by `scripts/lib/skill-common.sh`'s
`resolve_repo_root()` function, which `bp-yaml-set.sh` never sources or
calls. Under `set -euo pipefail` (nounset), the bare `$REPO_ROOT` reference
aborts immediately.

This is the same class of defect as the already-fixed
`BUG-2026-07-06T124600` (trace-stories.sh: "repository-root initialization
was removed... never replaced"), except here `bp-yaml-set.sh` appears to
have never had the init at all, rather than losing it in a refactor.

## TDD Fix Plan

1. **RED**: `bash scripts/bp-yaml-set.sh specs/state.yaml bug_id null` exits
   non-zero with "REPO_ROOT: unbound variable".
   **GREEN**: Source `scripts/lib/skill-common.sh` and call
   `resolve_repo_root` after argument parsing, matching the pattern already
   used by `trace-stories.sh` and other wrapper scripts.
   **verify**: `bash scripts/bp-yaml-set.sh specs/state.yaml bug_id null`
   exits 0 and the key is actually patched in the file.

2. **RED**: No smoke test guards this script from silently losing its
   repo-root init again.
   **GREEN**: Add a one-line assertion to `scripts/validate-doctrine.sh` (or
   a dedicated smoke test) that runs `bp-yaml-set.sh` against a throwaway
   copy of a small YAML fixture and expects exit 0 — matching the existing
   `trace-stories.sh --help` smoke guard.
   **verify**: the new assertion passes and fails if the `resolve_repo_root`
   call is removed.

**REFACTOR**: Audit other thin wrapper scripts under `scripts/` that
reference `$REPO_ROOT` under `set -u` for the same gap — grep audit, no
behavior change, per the REFACTOR note already logged in
`BUG-2026-07-06T124600`.

## Acceptance Criteria

- [x] `bash scripts/bp-yaml-set.sh <file> <key> <value>` exits 0 and patches
      the key
- [ ] Smoke assertion added so a future refactor cannot silently drop
      `resolve_repo_root` again (deferred — no test infra change bundled
      with this session's doc-audit pass)
- [x] `CONVENTIONS.md`'s documented usage example works as written

## Resolution

**Fixed:** 2026-07-24
**Fix applied:** Source `scripts/lib/skill-common.sh` and call
`resolve_repo_root` after sourcing `python-env.sh`, matching the pattern
already used by `trace-stories.sh`.
**Validated:** `bash scripts/bp-yaml-set.sh specs/state.yaml bug_id null`
exits 0 and correctly patches the key (verified against a live copy of
`specs/state.yaml`, then reverted).
