# e79s03 — seed-conventions applies Agentic STE

**Status:** stub (intake)  
**Epic:** e79  
**GitHub:** https://github.com/danielvm-git/bigpowers/issues/91  
**Requirement delta:** ADDED

## Goal

When `seed-conventions` generates CLAUDE.md / CONVENTIONS.md, instructional
lines follow AGENTIC-STE.md directive vocabulary and hedge bans.

## Verify

```bash
grep -Eq 'AGENTIC-STE|validate-agentic-ste|Agentic STE' skills/seed-conventions/SKILL.md
```
