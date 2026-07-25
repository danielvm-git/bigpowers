# e79s04 — stocktake-skills STE scanner

**Status:** done  
**Epic:** e79  
**GitHub:** https://github.com/danielvm-git/bigpowers/issues/91  
**Requirement delta:** ADDED

## Goal

Extend `stocktake-skills` to flag hedge words and oversized instruction
sentences across the catalog. Report existing STE debt; do not rewrite the
full catalog in this epic.

## Verify

```bash
grep -Eq 'AGENTIC-STE|validate-agentic-ste|hedge' skills/stocktake-skills/SKILL.md
```
