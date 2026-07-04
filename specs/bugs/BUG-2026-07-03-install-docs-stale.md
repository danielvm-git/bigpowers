---
bug_id: BUG-2026-07-03-install-docs-stale
status: fixed
severity: medium
scope: docs
title: "README and docs reference removed npm lifecycle scripts (postinstall, npx)"
commit_message: "docs: update all install instructions for postinstall-free flow"
---

## Root Cause

Lifecycle scripts (`install`, `postinstall`) were removed from `package.json` to bypass
npm v10+ `allow-scripts` gate. Setup moved to `bigpowers setup` CLI command. But the
README, CLAUDE.md, GEMINI.md, using-bigpowers skill, and maintenance docs still
reference the old flow (`postinstall`, `npm run sync` as the primary install path).

## Fix

Update all install instructions to the new two-step flow:
```bash
npm install -g bigpowers
bigpowers setup
```

`npx bigpowers setup` remains documented as an intentional one-shot alternative (not a
lifecycle script).

## Files to update

- [x] README.md — Quick Start, From Source, Maintenance sections
- [x] CLAUDE.md — Install row in command table
- [x] GEMINI.md — Install row in command table
- [x] skills/using-bigpowers/SKILL.md — Install command
- [x] docs/using-bigpowers.md — Install command
- [x] scripts/install.sh — Update message

## Verify

- [x] User-facing install docs no longer reference `postinstall` (archive specs and historical bug files excluded)
- [x] `npm run compliance && echo OK`

## Resolution

**Fixed:** 2026-07-03 (commit `8d8fb01`)
**Evidence:** `grep -rn postinstall --include='*.md' .` hits only archive specs, security threat model, and other bug files — not README, CLAUDE.md, GEMINI.md, or using-bigpowers. Install table in CLAUDE.md reads `npm install -g bigpowers && bigpowers setup`. `package.json` has no lifecycle scripts.
