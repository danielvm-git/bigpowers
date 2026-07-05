---
description: Agent-maintained OKF knowledge wiki — INGEST (sync all wikis from sources), LINT (validate cross-references and staleness), QUERY (search and synthesize). Use after modifying source specs or conventions, during build-epic Step 8, or when the user asks about wiki health.
---


# Maintain Wiki

> **HARD GATE** — Derived OKF bundles under `specs/` (skills-wiki, conventions-wiki, agent-guide, codebase-wiki, epics-wiki, adr-wiki) are regenerable. Never hand-edit them; always run INGEST to regenerate from canonical sources.

Three operations for maintaining the OKF knowledge wiki ecosystem.

## Operations

### INGEST — Sync all wikis from canonical sources

Regenerate all OKF bundles from their canonical source files. Run this after any source change that affects wiki content.

```
→ verify: bash scripts/sync-skills.sh --graph && bash scripts/decompose-conventions.sh && bash scripts/generate-agent-guide.sh && echo "OK: all wikis regenerated"
```

**Sources → Targets:**

| Source | Target | Generator |
|--------|--------|-----------|
| skills/*/SKILL.md | specs/skills-wiki/ | build-skill-graph.sh |
| CONVENTIONS.md | specs/conventions-wiki/ | decompose-conventions.sh |
| CLAUDE.md | specs/agent-guide/ | generate-agent-guide.sh |
| specs/traceability-matrix.json | specs/codebase-wiki/ | trace-stories.sh |
| specs/epics/*/epic.yaml | specs/epics-wiki/ | generate-epics-wiki.sh |
| specs/adr/*.md | specs/adr-wiki/ | generate-adr-wiki.sh |

### LINT — Validate OKF bundles

Check all OKF bundles for consistency:

1. **Cross-references:** Every `see:` link resolves to an existing concept
2. **Stale claims:** No concept references a source file modified after the concept was generated
3. **Orphans:** No concept without a parent index entry
4. **Frontmatter:** Every `.md` has required OKF fields (`type`, `name`, `source`)

```
→ verify: bash scripts/validate-okf.sh --dir specs/skills-wiki && bash scripts/validate-okf.sh --dir specs/conventions-wiki && bash scripts/validate-okf.sh --dir specs/agent-guide && echo "OK: lint passed"
```

**Lint severity:**
- ERROR: Missing required fields, broken cross-references → block merge
- WARNING: Stale claim (>source newer than concept) → flag in verify summary
- INFO: Orphan concept → surface as advisory

### QUERY — Search and synthesize

Search across all OKF bundles using the index files. Example queries:

- "Which skills enforce CONVENTIONS.md §Code Style?"
- "What's the handoff chain starting from survey-context?"
- "Which epics touch the traceability system?"
- "Show me all concepts tagged model: sonnet"

**Process:**
1. Search `specs/*/index.md` for matching concepts
2. Read top-N matching concept files
3. Synthesize findings into a concise answer
4. Cite source files for traceability

```
→ verify: grep -c 'type:' specs/skills-wiki/index.md specs/conventions-wiki/index.md specs/agent-guide/index.md 2>/dev/null && echo "OK: indexes readable"
```

## Integration

- **build-epic Step 8:** INGEST runs after story completion to update wikis (e39s08)
- **verify-work Phase 3:** LINT runs to surface stale/wrong OKF content
- **Manual:** `maintain-wiki INGEST` after any convention or spec change

## Pitfalls

- OKF bundles are derived — never hand-edit individual concept files
- Index files must stay in sync with concept count; INGEST regenerates both
- LINT runs on non-blocking warnings by default; use `--strict` for CI gates

## Verify

```bash
test -f skills/maintain-wiki/SKILL.md && grep -q 'INGEST\|LINT\|QUERY' skills/maintain-wiki/SKILL.md && echo OK
```
