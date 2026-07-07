---
story_id: e12s01
title: "Pi skill generation — .pi/skills/<name>/SKILL.md"
status: done
bcps: 2
type: feat
context: infra
---

# Story e12s01: Pi skill generation

Generate pi-compatible Agent Skills directories from bigpowers SKILL.md sources.

## What was implemented

`scripts/sync-skills.sh` (lines 91-103) generates `.pi/skills/<skill-name>/SKILL.md`
for every bigpowers skill. Each directory contains a SKILL.md with the same
YAML frontmatter (name, description) and body as the source.

Pi implements the Agent Skills standard — the existing bigpowers SKILL.md
format is already compatible. Only the output directory path changes from
the existing Cursor/Gemini targets.

## Acceptance Criteria

- [x] 62 `.pi/skills/<name>/SKILL.md` files generated
- [x] Frontmatter fields (name, description) preserved exactly
- [x] Body content (markdown instructions) matches source
- [x] Skill count matches source count (62)

## Verification

```bash
find .pi/skills -name "SKILL.md" | wc -l
# Expect: 62

grep -q "^name: survey-context" .pi/skills/survey-context/SKILL.md && \
  grep -q "^# Survey Context" .pi/skills/survey-context/SKILL.md && \
  echo "OK: valid Agent Skills format" || echo "FAIL: invalid format"
```

## Implementation notes

- `PI_SKILLS` variable in sync-skills.sh line 12
- Generation loop lines 91-103
- Artifacts cleared and regenerated on each run (line 19)
