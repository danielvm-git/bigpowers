STORY KEY: E39-S09
TITLE:     Write docs/references/semantic-context-bridge.md — architecture and operator guide
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The e39 Semantic Context Bridge is a complex system spanning three pillars
(skill graph, agent coordination, spec drift) and four OKF bundle types
(skills-wiki, conventions-wiki, agent-guide, codebase-wiki). Without a
single architecture and operator guide, an operator encountering a lint
error or lock conflict has to trace through 10 story specs to understand
what to do. The semantic-context-bridge.md reference doc explains the full
system: architecture, OKF bundle types, maintain-wiki workflow, CI/CD
integration, and how to interpret/act on reports.

### 2. Value statement
As an operator responding to a maintain-wiki LINT error or agent lock conflict,
I want a single document explaining the system architecture and how to resolve
issues, so I can act without reading 10 story specs.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/semantic-context-bridge.md.
Precondition: all e39 components specified (s01-s10).

### 5. Main flow and business logic
1. Document three-pillar architecture: skill graph (s01) + agent coordination (s02) + spec drift (s03).
2. Document OKF bundle types: skills-wiki (s04), conventions-wiki (s05), agent-guide (s06), codebase-wiki (via maintain-wiki s07).
3. Document maintain-wiki workflow: INGEST → cross-reference → index → LINT.
4. Document CI/CD integration points: sync-skills.yml (validate-okf), build-epic (INGEST), verify-work (LINT).
5. Document how to interpret: lint reports, drift reports, lock conflicts.
6. Include provenance: Karpathy LLM Wiki, OKF v0.1, TEA traceability, "The Agentic Coding Stack" article.

### 6-16. Not applicable (standard reference doc creation pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  GIVEN no existing semantic-context-bridge.md
  WHEN the doc is created
  THEN test -f docs/references/semantic-context-bridge.md exits 0
  AND grep -q 'skill graph|agent locks|spec drift|OKF|maintain-wiki' docs/references/semantic-context-bridge.md exits 0
  AND the doc covers architecture, OKF bundles, maintain-wiki, CI/CD, and how to interpret reports

### 18. Out of scope
- Replacing individual skill reference docs (this is the system overview).

### 19. Open questions
Not applicable.

### 20. References
- scripts/build-skill-graph.sh (e39s01).
- specs/agent-locks.yaml (e39s02).
- scripts/check-spec-drift.sh (e39s03).
- skills/maintain-wiki/SKILL.md (e39s07).
- specs/IMPACT-e38-okf-adoption.md.
