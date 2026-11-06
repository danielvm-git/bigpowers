---
bug_id: BUG-2026-11-06-validator-yaml-strictness
status: fixed
severity: high
scope: "ci"
title: "validate-skill-yaml.py cannot detect the form that drops skills (#207)"
issue: https://github.com/danielvm-git/bigpowers/issues/207
files_changed: "scripts/validate-skill-yaml.py, tests/"
approach: "Detect duplicate keys via yaml.compose; reject '<!--' inside frontmatter; add a host-parser golden test"
risk_level: medium
commit_message: "fix(ci): make validate-skill-yaml reject forms pi cannot load (#207)"
fix_evidence: "PR #221 — validate-skill-yaml R4/R5 + skill-frontmatter-strict gate"
---

# BUG-2026-11-06-validator-yaml-strictness: validate-skill-yaml.py cannot detect the form that drops skills (#207)

## Problem

The validator uses yaml.safe_load (PyYAML) or scripts/lib/simple_yaml.py, both of which accept duplicate keys last-wins, and its docstring explicitly permits `<!-- story: -->` inside the fence. It reported PASS on 160/160 files while pi rejected 10 of them. R2 must detect duplicate keys; new rule R4 rejects HTML comments inside the block; a golden test pipes every SKILL.md through the same `yaml` package pi uses.

## Acceptance criteria

- The behaviour described above no longer reproduces on a fresh install.
- A regression test fails before the fix and passes after it.

## Verify

- `npm run compliance && bash scripts/run-verification-gates.sh`
- Issue-specific commands are listed on https://github.com/danielvm-git/bigpowers/issues/207.
