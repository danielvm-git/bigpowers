---
story_id: e12s04
title: "sync-skills.sh pi target"
status: done
bcps: 2
type: feat
context: infra
---

# Story e12s04: sync-skills.sh pi target

Wire pi output into `scripts/sync-skills.sh` alongside existing Cursor and Gemini CLI targets.

## What was implemented

`scripts/sync-skills.sh` was extended with:

- `PI_SKILLS`, `PI_PROMPTS`, `PI_PACKAGE_JSON` variables (lines 12-14)
- Skill generation loop (lines 91-103)
- Prompt template generation (lines 104-124)
- Package config generation (lines 126-150)
- Summary output reporting pi counts (lines 187-189)
- Artifact cleanup on each run (line 19 clears old `.pi/skills/` and `.pi/prompts/`)

Running twice produces idempotent output. Existing Cursor and Gemini targets unaffected.

## Acceptance Criteria

- [x] `bash scripts/sync-skills.sh` generates `.pi/skills/` and `.pi/prompts/`
- [x] Summary output reports pi skill count (62)
- [x] Running twice produces idempotent output
- [x] Existing Cursor and Gemini targets are unaffected

## Verification

```bash
bash scripts/sync-skills.sh 2>&1 | grep -q "→ .pi/skills/" && echo "OK: pi in summary"
grep -q '.pi/skills' scripts/sync-skills.sh && echo "OK: pi target in script"
```
