---
bug_id: BUG-2026-07-03-codebase-wiki-venv-pollution
status: open
severity: medium
scope: specs
title: "OKF codebase-wiki concepts polluted with .venv/site-packages false-positive links from buggy trace run"
risk_level: medium
---

## Summary

The generated OKF concepts under `specs/codebase-wiki/` are polluted with
hundreds of false-positive `file_heuristic` links into `.venv/` and vendored
Python packages. `specs/codebase-wiki/e43s02.md` alone carries 567 links —
566 of them `file_heuristic` — pointing at files like
`.venv/lib/python3.12/site-packages/botocore/.../endpoint-rule-set-1.json.gz`
and `.venv/.../agent/render.py`. A showcase-repo story "matches" botocore data
files because the heuristic slug-matcher fires on incidental filename tokens.

This drowns the confidence-tiered traceability signal in medium-confidence
noise and makes `coverage_status: covered` verdicts meaningless.

## Root Cause

1. `scripts/lib/trace-stories.py` `EXCLUDE_DIRS` did not include `.venv`
   (it was added for `.git/node_modules/.cursor/.gemini/.pi` but not the Python
   virtualenv). The exclusion list is incomplete.
2. The polluted concept files were written by an earlier buggy run and committed;
   they cannot be regenerated cleanly until
   [[BUG-2026-07-03-trace-engine-vacuous-gate]] and the upstream YAML corruption
   are fixed.
3. Related: `.venv/` is not gitignored (see
   [[BUG-2026-07-03-venv-not-gitignored]]), so the walker sees it at all.

## Fix Approach

1. Add `.venv`, `venv`, `.tox`, `__pycache__`, `site-packages`, `.mypy_cache`
   to `EXCLUDE_DIRS` in `trace-stories.py` (defense in depth even once
   `.venv` is gitignored).
2. Regenerate `specs/codebase-wiki/` after the trace engine and YAML corruption
   are fixed, so the polluted concepts (e43s02, e42s04, ...) are rebuilt clean.
3. Consider capping links-per-story and logging truncation (no silent caps).

## Verify Steps

- [ ] `grep -rl 'site-packages\|\.venv' specs/codebase-wiki/ | wc -l` returns 0 after regen
- [ ] `python3 -c "import json; d=json.load(open('specs/traceability-matrix.json')); assert not any('.venv' in l['file'] for s in d['stories'] for l in s['links'])" && echo OK`
