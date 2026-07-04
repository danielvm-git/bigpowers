---
bug_id: BUG-2026-07-03-venv-not-gitignored
status: open
severity: low
scope: repo
title: ".venv/ exists at repo root and is not gitignored — one 'git add .' from committing the virtualenv"
risk_level: low
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

- [ ] `git check-ignore .venv && echo OK`
- [ ] `git status --porcelain | grep -c '\.venv' | grep -q '^0$' && echo OK`
