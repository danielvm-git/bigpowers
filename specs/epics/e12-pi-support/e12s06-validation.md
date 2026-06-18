---
story_id: e12s06
title: "Validation — test pi loads all skills correctly"
status: done
bcps: 1
type: test
context: infra
---

# Story e12s06: Validation

End-to-end validation that pi discovers and loads bigpowers skills.

## What was validated

- 62 skills appear in pi's system prompt `<available_skills>` XML block (confirmed in active pi session)
- `sync-skills.sh` generates all `.pi/skills/`, `.pi/prompts/`, and `.pi/package.json`
- Skills are loaded on-demand via progressive disclosure
- Prompt templates appear in pi's `/` autocomplete
- No validation warnings from pi's skill validator

## Acceptance Criteria

- [x] All 62 bigpowers skills are discoverable by pi
- [x] No pi validation warnings for any skill
- [x] Skill invocations work via `/skill:name`
- [x] Prompt template autocomplete shows all skills

## Verification (manual)

Run pi with bigpowers installed and confirm:
1. Skills appear in system prompt (`<available_skills>` XML block)
2. `/skill:survey-context` loads the full skill
3. `/survey-context` appears in autocomplete
4. No warnings in pi output on startup
