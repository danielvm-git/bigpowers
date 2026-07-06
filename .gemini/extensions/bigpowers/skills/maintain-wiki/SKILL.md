---
name: maintain-wiki
description: "\"Agent-maintained OKF wiki — INGEST source docs, LINT for issues, QUERY across concept pages. Run as part of build-epic Step 8 and verify-work Phase 3.\""
---


# Maintain Wiki

Three operations for keeping the OKF wiki bundle consistent with its source docs.

## INGEST

Read source doc (CLAUDE.md, CONVENTIONS.md, or SKILL.md) and write/update OKF concept pages:

```bash
# Regenerate skills-wiki from SKILL.md files
bash scripts/sync-skills.sh --okf

# Regenerate conventions-wiki from CONVENTIONS.md
bash scripts/decompose-conventions.sh

# Regenerate agent-guide from CLAUDE.md
bash scripts/generate-agent-guide.sh
```

## LINT

Check for common OKF issues:

1. **Stale concepts** — source file mtime vs concept page mtime. If source is newer, concept is stale.
2. **Orphan concepts** — concept page exists but source doc section no longer exists.
3. **Missing cross-references** — skill concept pages with no `enforced_by` or `references` links.
4. **Contradictions** — two concept pages that make opposite claims about the same topic.
5. **Broken links** — internal OKF links that point to non-existent concept pages.

```bash
# Quick stale check: compare source vs concept mtimes
for page in specs/skills-wiki/skills/*.md; do
  skill=$(basename "$page" .md)
  source="skills/$skill/SKILL.md"
  if [ -f "$source" ] && [ "$page" -ot "$source" ]; then
    echo "STALE: $skill (SKILL.md newer than concept page)"
  fi
done
```

## QUERY

Search across OKF concept pages to answer questions:

```bash
# Find all concepts about a topic
grep -rl "topic" specs/skills-wiki/ specs/conventions-wiki/ specs/agent-guide/

# Trace a convention → enforcing skills
grep -A1 "enforced_by" specs/conventions-wiki/*.md

# Find skill by description keyword
grep -ril "keyword" specs/skills-wiki/skills/*.md
```

## Verify

→ verify: `test -d specs/skills-wiki && test -d specs/conventions-wiki && test -d specs/agent-guide && echo "OKF wiki present" || echo "FAIL"`
