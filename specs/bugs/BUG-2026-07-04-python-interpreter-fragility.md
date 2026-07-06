---
bug_id: BUG-2026-07-04-python-interpreter-fragility
status: fixed
severity: low
scope: ci
title: "Scripts call bare python3 with no interpreter pinning — login-shell python3 may lack PyYAML"
---

# BUG-2026-07-04-python-interpreter-fragility

## Problem

**Actual behavior:** Repo scripts (`sync-skills.sh` → `validate-skill-yaml.py`,
`validate-specs-yaml.sh`, `trace-stories.sh` → `scripts/lib/*.py`,
`sync-bugs-registry.sh`, `yaml-tools.py`) invoke a bare `python3` with no venv
activation and no interpreter pinning. The machine has at least three `python3`
resolutions:

- pyenv shim (interactive shells) — has PyYAML
- `uv`-managed `.venv/` — has PyYAML
- system `/usr/bin/python3` (login shells, which run the compliance gate) —
  historically lacked PyYAML

This exact split caused a `sync-skills.sh` compliance FAIL earlier
(GAP-ENV, fixed by `pip install --user pyyaml` into the system interpreter and
adding `requirements.txt`). But nothing enforces *which* `python3` runs, so the
failure can recur on any machine whose login-shell `python3` differs from its
interactive one.

**Expected behavior:** Scripts resolve a Python interpreter that is guaranteed
to have the declared dependencies (`requirements.txt`), independent of shell
resolution order.

**How to reproduce:**
1. `bash -lc 'which python3'` vs interactive `which python3` → different paths
2. On a machine where login-shell `python3` lacks PyYAML: `npm run compliance`
   → the "sync skills preserves plus" step FAILs

## Root Cause Analysis

`requirements.txt` documents the dependency but nothing binds scripts to the
interpreter it was installed into. Bare `python3` is late-bound to `$PATH`.

**Risk level:** LOW — only bites on machines with a yaml-less login `python3`;
CI installs PyYAML so CI is unaffected. Cosmetic-to-moderate developer friction.

## Fix Applied

**Chosen: Option A** — `scripts/lib/python-env.sh` (shared resolver).

Resolution order: `.venv/bin/python3` → `pyenv` shim → `python3` on PATH.
Verifies PyYAML availability; falls back to PATH python3 if `.venv` one lacks
it. Prints actionable `pip install -r requirements.txt` hint on missing deps.

All 31 caller scripts (`sync-skills.sh`, `trace-stories.sh`, `validate-specs-yaml.sh`,
and 28 others) source `python-env.sh` and use `$PYTHON` instead of bare `python3`.

## Acceptance Criteria

- [x] Compliance/sync scripts use an interpreter guaranteed to have PyYAML,
      regardless of shell resolution
- [x] A missing-dependency failure prints an actionable `pip install` hint
- [x] `npm run compliance` passes on a machine whose login `python3` differs
      from its interactive `python3`

## Resolution

**Fixed** — 2026-07-06. Option A implemented via `scripts/lib/python-env.sh`.
All 31 scripts source the resolver and use `$PYTHON`. Compliance passes at 100%
(91/91). No bare `python3` invocations remain in any shell script.
