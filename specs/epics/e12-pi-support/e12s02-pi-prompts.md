---
story_id: e12s02
title: "Pi prompt templates — .pi/prompts/<name>.md"
status: done
bcps: 1
type: feat
context: infra
---

# Story e12s02: Pi prompt templates

Generate pi prompt templates (slash commands) from bigpowers skills.

## What was implemented

`scripts/sync-skills.sh` (lines 104-124) generates `.pi/prompts/<skill-name>.md`
for every bigpowers skill. Each prompt template has YAML frontmatter with
the skill's description, followed by the full SKILL.md body as expanded content.

When a pi user types `/survey-context`, the prompt template expands to the
skill's full instructions.

## Acceptance Criteria

- [x] 62 `.pi/prompts/<name>.md` files generated
- [x] Frontmatter has `description` matching skill's description
- [x] Template content is the full SKILL.md body
- [x] Prompt templates appear in pi's `/` autocomplete

## Verification

```bash
find .pi/prompts -name "*.md" | wc -l
# Expect: 62

grep -q "^name:" .pi/prompts/survey-context.md && \
  echo "OK: frontmatter present" || echo "FAIL: no frontmatter"
```
