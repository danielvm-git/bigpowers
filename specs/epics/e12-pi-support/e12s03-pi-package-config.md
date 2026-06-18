---
story_id: e12s03
title: "Pi package config — package.json with pi manifest"
status: done
bcps: 1
type: feat
context: infra
---

# Story e12s03: Pi package config

Create `.pi/package.json` with pi manifest for npm/git distribution.

## What was implemented

`scripts/sync-skills.sh` (lines 126-150) generates `.pi/package.json` with:

- `pi.skills: ["./skills"]` — points to the skills directory
- `pi.prompts: ["./prompts"]` — points to the prompts directory
- `keywords: ["pi-package"]` — for discoverability in pi's package gallery

This enables `pi install npm:bigpowers` and `pi install git:github.com/user/bigpowers`.

## Acceptance Criteria

- [x] `.pi/package.json` has `pi.skills` and `pi.prompts` keys
- [x] Package has `"keywords": ["pi-package"]`
- [x] `pi install` (local path) discovers skills

## Verification

```bash
jq -e '.pi.skills and .pi.prompts' .pi/package.json && echo "OK: pi manifest"
jq -e '.keywords | contains(["pi-package"])' .pi/package.json && echo "OK: pi-package keyword"
```
