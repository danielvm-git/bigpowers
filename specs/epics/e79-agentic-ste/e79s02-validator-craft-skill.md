# e79s02 — Validator script + craft-skill HARD GATE

**Epic:** e79 | **Story:** e79s02 | **Status:** done | **BCPs:** 3

## Goal

Mechanical enforcement of AGENTIC-STE at skill authoring time.

## Scope

- `scripts/validate-agentic-ste.sh` — checks skill bodies against ruleset
- Extend `craft-skill` HARD GATE table for skill-body style (beyond YAML description)

## Depends on

e79s01 (ruleset doc is SoT)

## Verify

```bash
bash scripts/validate-agentic-ste.sh && grep -q 'AGENTIC-STE' skills/craft-skill/SKILL.md
```
