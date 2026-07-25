# e79s01 — AGENTIC-STE ruleset document

**Epic:** e79 | **Story:** e79s01 | **Status:** done | **BCPs:** 2

## Goal

Commit `docs/AGENTIC-STE.md` with concrete, numeric rules adapted from ASD-STE100 for bigpowers instructional prose.

## Scope

- Controlled vocabulary (MUST, MUST NOT, NEVER, ALWAYS, DO, DO NOT)
- Banned ambiguous modals (should, might, could, may, consider, try, generally, typically)
- Sentence cap (~20 words), imperative mood, active voice
- Explicit scope boundary vs `terse-mode` (input precision ≠ output compression)

## Out of scope

- Validator script (e79s02)
- Skill edits (e79s02–s04)

## Verify

```bash
test -f docs/AGENTIC-STE.md && grep -q 'terse-mode' docs/AGENTIC-STE.md
```
