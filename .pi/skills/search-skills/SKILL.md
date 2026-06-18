---
name: search-skills
description: "Find the right bigpowers skill from natural-language intent using a local lexical index over SKILL.md frontmatter. Use when unsure which skill to invoke, or at start of research-first.model: haiku"
---


# Search Skills
> **HARD GATE** — **HARD GATE** — Search results must be ranked by relevance. Do NOT return all matches without prioritization. Use skill metadata (phase, purpose, frequency) to rank.


Lexical search only — no embedding service (ADR: zero external dependency).

## Process

1. Run `bash scripts/build-skill-index.sh` if `specs/SKILL-SEARCH-INDEX.md` is stale.
2. Search index: `rg -i "<keywords>" specs/SKILL-SEARCH-INDEX.md`
3. Read top 3 matches' `description` and "Use when" triggers.
4. Recommend one skill with rationale; invoke via orchestrator or direct call.

## Verify

→ verify: `test -f specs/SKILL-SEARCH-INDEX.md && echo OK || (bash scripts/build-skill-index.sh && test -f specs/SKILL-SEARCH-INDEX.md && echo OK)`
