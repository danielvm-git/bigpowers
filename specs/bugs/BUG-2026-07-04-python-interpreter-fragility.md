---
bug_id: BUG-2026-07-04-python-interpreter-fragility
status: open
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

## Fix Plan (not yet applied — needs a design decision)

Options (pick one in a follow-up, likely via `setup-environment`):
- **A:** Scripts source a shared `scripts/lib/python-env.sh` that prefers
  `.venv/bin/python3` if present, else falls back to `python3`, and fails loudly
  if PyYAML is missing with a `pip install -r requirements.txt` hint.
- **B:** Shebang/pin the Python entry points to the `.venv` interpreter.
- **C:** A `setup-environment` step that guarantees `python3` on PATH has
  `requirements.txt` installed, documented as a prerequisite.

## Acceptance Criteria

- [ ] Compliance/sync scripts use an interpreter guaranteed to have PyYAML,
      regardless of shell resolution
- [ ] A missing-dependency failure prints an actionable `pip install` hint
- [ ] `npm run compliance` passes on a machine whose login `python3` differs
      from its interactive `python3`

## Resolution

**Open** — registered 2026-07-04 from map-codebase Signals. Deferred: the fix
is a small design choice (A/B/C above) best made with `setup-environment`, not
a blind script sweep.
