---
bug_id: BUG-2026-07-03-venv-not-gitignored
status: fixed
severity: low
scope: repo
title: ".venv/ exists at repo root and is not gitignored — one 'git add .' from committing the virtualenv"
risk_level: low
commit_message: "fix(repo): gitignore Python virtualenvs and bytecode"
---

## Summary

A Python virtualenv at `.venv/` exists at the repo root and is **not** matched
by `.gitignore` (`git check-ignore .venv` → not ignored). It is not yet tracked
(0 files committed), but a single `git add .` would commit thousands of
vendored files. It is also the source of the codebase-wiki pollution
(see [[BUG-2026-07-03-codebase-wiki-venv-pollution]]).

## Fix Approach

1. Add `.venv/`, `venv/`, `__pycache__/`, `*.pyc` to `.gitignore`.
2. Confirm `git status` no longer surfaces `.venv` contents.

## Verify Steps

- [x] `git check-ignore .venv && echo OK`
- [x] `git status --porcelain | grep -c '\.venv' | grep -q '^0$' && echo OK`

## Resolution

**Fixed:** 2026-07-03
**Root cause confirmed:** `.gitignore` had no Python virtualenv or bytecode patterns, so a local `.venv/` was visible to git and trace walkers.
**Fix applied:** Added `.venv/`, `venv/`, `__pycache__/`, `*.pyc` to `.gitignore`.
**Hardening added:** Golden gate `scripts/golden-g11-gitignore-venv.sh` (G-11) asserts required ignore patterns and `git check-ignore .venv`; registered in `run-golden-suite.sh`.
**Evidence:** `git check-ignore .venv` OK; no `.venv` in `git status`; `bash scripts/golden-g11-gitignore-venv.sh` pass; `npm run compliance` 100% GATE PASS.
**Commit:** `fix(repo): gitignore Python virtualenvs and bytecode`
