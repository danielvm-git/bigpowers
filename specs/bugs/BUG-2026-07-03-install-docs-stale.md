---
bug_id: BUG-2026-07-03-install-docs-stale
status: open
severity: medium
scope: docs
title: "README and docs reference removed npm lifecycle scripts (postinstall, npx)"
---

## Root Cause

Lifecycle scripts (`install`, `postinstall`) were removed from `package.json` to bypass
npm v10+ `allow-scripts` gate. Setup moved to `bigpowers setup` CLI command. But the
README, CLAUDE.md, GEMINI.md, using-bigpowers skill, and maintenance docs still
reference the old flow (`npx bigpowers`, `postinstall`, `npm run sync`).

## Fix

Update all install instructions to the new two-step flow:
```bash
npm install -g bigpowers
bigpowers setup
```

## Files to update

- [ ] README.md — Quick Start, From Source, Maintenance sections
- [ ] CLAUDE.md — Install row in command table
- [ ] GEMINI.md — Install row in command table
- [ ] skills/using-bigpowers/SKILL.md — Install command
- [ ] docs/using-bigpowers.md — Install command
- [ ] scripts/install.sh — Update message

## Verify

- [ ] `grep -rn "postinstall\|npx bigpowers" --include="*.md" . | grep -v node_modules | grep -v ".git/" | grep -v specs/bugs | grep -v specs/codebase-wiki | grep -v .venv` returns no results
- [ ] `npm run compliance && echo OK`
