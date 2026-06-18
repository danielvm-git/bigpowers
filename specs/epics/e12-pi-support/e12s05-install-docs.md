---
story_id: e12s05
title: "Installation docs — document pi install process"
status: done
bcps: 1
type: docs
context: docs
---

# Story e12s05: Installation docs

Document how pi users install and use bigpowers in README.md.

## What was implemented

README.md §"pi Support" (line ~100) documents:

- `pi install .` from local path after cloning and running `sync-skills.sh`
- `pi install npm:bigpowers` for npm distribution
- What users get: 62 pi skills, 62 prompt templates, pi package manifest
- How skills load (available_skills XML block, progressive disclosure)
- How prompt templates work (slash commands with autocomplete)
- pi listed in Prerequisites section alongside other AI tools

## Acceptance Criteria

- [x] Installation instructions for pi are documented
- [x] Instructions cover both npm and local install paths
- [x] A pi user can follow the docs and get all 62 skills working

## Verification

```bash
grep -qi "pi install" README.md && echo "OK: pi install mentioned"
grep -q "pi-package" README.md && echo "OK: pi-package keyword"
grep -q "pi skills" README.md && echo "OK: pi skills mentioned"
```
