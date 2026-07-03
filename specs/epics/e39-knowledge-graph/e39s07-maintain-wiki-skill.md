STORY KEY: E39-S07
TITLE:     Create maintain-wiki skill — agent-maintained OKF ingest, lint, and query
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The OKF bundles (skills-wiki, conventions-wiki, agent-guide) are generated but
not maintained. As the codebase evolves — new skills, changed conventions,
updated CLAUDE.md — the wikis stale. The maintain-wiki skill gives agents the
ability to maintain the knowledge graph: INGEST (read source → write/update OKF
concepts), QUERY (search index.md → drill into concepts → synthesize answer with
citations), and LINT (check for contradictions, stale claims, orphan pages,
missing cross-references). This is the "Tier 0" codebase wiki — language-agnostic,
agent-maintained, providing semantic understanding without language-specific
static analyzers.

### 2. Value statement
As an agent maintaining the codebase, I want to update the knowledge graph as
I make changes, so the wiki stays current and I can query it for architectural
understanding without re-analyzing the entire codebase.

### 3. Actors and permissions
- Agent (system) — invokes maintain-wiki for ingest, lint, query.
- build-epic Step 8 (system) — invokes maintain-wiki INGEST after story completion.

### 4. Trigger and preconditions
Trigger: agent invocation (INGEST after code changes, QUERY before planning, LINT during verification).
Precondition: OKF bundles exist at specs/skills-wiki/, specs/conventions-wiki/, specs/agent-guide/.

### 5. Main flow and business logic
INGEST:
1. Agent reads source (code, spec, doc).
2. Writes or updates OKF concepts (concept page + cross-references in dependents + index.md + log.md).
3. Touches 5-15 pages per ingest.
QUERY:
1. Agent searches index.md for relevant concepts.
2. Drills into concept pages, follows cross-references.
3. Synthesizes answer with citations back to source files.
LINT:
1. Check for contradictions between concepts.
2. Check for stale claims (source file modified after concept).
3. Check for orphan pages (no incoming links).
4. Check for missing cross-references, data gaps, broken links.
5. Produce lint report.

### 6-16. Not applicable (standard skill creation pattern)

### 17. Acceptance criteria
Scenario: Maintain-wiki skill created
  GIVEN the skills directory
  WHEN the skill is created
  THEN test -f skills/maintain-wiki/SKILL.md exits 0
  AND the SKILL.md covers ingest, lint, and query operations
  AND grep -q 'ingest|lint|query' skills/maintain-wiki/SKILL.md exits 0

### 18. Out of scope
- Implementing maintain-wiki as a standalone CLI (it's a skill for agents).
- Creating a separate wiki for epics or ADRs (those are separate domains).

### 19. Open questions
- Should INGEST be auto-triggered on every story completion or opt-in?
  Integrated into build-epic Step 8 (e39s08), so auto-triggered.

### 20. References
- Karpathy LLM Wiki gist (inspiration for the ingest → query → lint pattern).
- specs/IMPACT-e38-okf-adoption.md.
- specs/skills-wiki/, specs/conventions-wiki/, specs/agent-guide/ (target wikis).
