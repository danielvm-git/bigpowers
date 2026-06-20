---
name: search-skills
description: Find the right bigpowers skill from natural-language intent using a local lexical index over SKILL.md frontmatter. Use when unsure which skill to invoke, or at start of research-first.
model: haiku
---

# Search Skills

> **HARD GATE** — Search results must be ranked by relevance. Do NOT return all matches without prioritization. Use skill metadata (phase, purpose, frequency) to rank.
>
> **HARD GATE** — Do NOT use external embedding APIs or AI-based semantic search. This is a lexical-only index (ADR: zero external dependency).

Lexical search only — no embedding service (ADR: zero external dependency). The index is a flat markdown file (`specs/SKILL-SEARCH-INDEX.md`) built from every SKILL.md's YAML frontmatter — name, description, and key phrases. No vector DB, no API calls, no network dependency.

## When to use

- You're unsure which skill to invoke for a user's request
- At the start of `research-first` to find pre-existing skills that might solve the problem
- When a user asks "is there a skill for X?"
- Before calling a skill by name, to confirm it's the right one

## Pre-flight

- [ ] Does `specs/SKILL-SEARCH-INDEX.md` exist? If not, run `bash scripts/build-skill-index.sh`.
- [ ] Is the index fresh? Check its timestamp — if > 24 hours old or after any SKILL.md change, regenerate.

## Process

1. **Refresh index if stale** — Run `bash scripts/build-skill-index.sh` if `specs/SKILL-SEARCH-INDEX.md` doesn't exist or was modified before the last SKILL.md change.

2. **Search the index** — Use ripgrep on the lexical index:
   ```
   rg -i "<keywords>" specs/SKILL-SEARCH-INDEX.md
   ```
   The index contains each skill's name, description, phase, and key use-case phrases, so natural language queries work well even without embeddings.

3. **Rank results** — Read the top 3 matches. Evaluate by:
   - **Exactness** — Does the description literally match the user's intent?
   - **Phase fit** — Is the skill designed for the current lifecycle phase?
   - **Trigger phrases** — Does the skill's "Use when" section match the situation?

4. **Recommend one skill** — Select the single best-matching skill. Provide:
   - The skill name
   - Why it's the best match (citing the description or trigger phrase)
   - What it produces (artifact, dialogue, or state change)

5. **Invoke** — Call the skill directly or through the orchestrator. If no match found, suggest the closest phase-appropriate skill or `using-bigpowers` as a general entry point.

## Index Format

`specs/SKILL-SEARCH-INDEX.md` contains one section per skill:
```markdown
## <skill-name>
- **Description:** <from frontmatter>
- **Phase:** <lifecycle phase>
- **Triggers:** <key phrases from description>
- **Keywords:** <extracted terms>
```

## Why Not Semantic Search?

- Zero network dependency — works fully offline
- Zero cost — no API keys, no usage limits
- Instant — ripgrep on a local file is sub-second
- Deterministic — same query always returns same results
- Auditable — you can read the full index

## Verify

→ verify: `test -f specs/SKILL-SEARCH-INDEX.md && echo OK || (bash scripts/build-skill-index.sh && test -f specs/SKILL-SEARCH-INDEX.md && echo OK)`
