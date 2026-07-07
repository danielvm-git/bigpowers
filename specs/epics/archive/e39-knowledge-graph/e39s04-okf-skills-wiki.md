STORY KEY: E39-S04
TITLE:     OKF Phase 2 — sync-skills.sh generates specs/skills-wiki/ from 72 SKILL.md files
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The 72 bigpowers skills currently exist only as SKILL.md files with frontmatter.
The OKF (Open Knowledge Format) provides a vendor-neutral, agent-friendly way to
represent them as a browsable knowledge graph. Adding a `--okf` flag to
sync-skills.sh generates specs/skills-wiki/ — one OKF concept per skill with
frontmatter (name, model, description), cross-references from build-skill-graph.sh
(handoff chains, dependencies), and a progressive-disclosure index.md. The skill
catalog becomes browsable in any OKF consumer (Obsidian, viz.html, mkdocs), and
agents can query the skill graph without parsing 72 raw SKILL.md files.

### 2. Value statement
As an agent deciding which skill to invoke next, I want a machine-readable skill
graph with cross-references, so I can navigate handoff chains without reading
every SKILL.md frontmatter manually.

### 3. Actors and permissions
- Agent (system) — queries skills-wiki for handoff chains.
- sync-skills.sh (system) — generates the OKF bundle.

### 4. Trigger and preconditions
Trigger: `bash scripts/sync-skills.sh --okf` (manual or CI).
Precondition: 72 SKILL.md files exist with valid frontmatter.

### 5. Main flow and business logic
1. Parse all skills/*/SKILL.md frontmatter (name, model, description).
2. Generate one OKF concept per skill in specs/skills-wiki/skills/.
3. Run build-skill-graph.sh to compute cross-references (handoff chains, dependencies).
4. Add cross-references as OKF concept links.
5. Generate specs/skills-wiki/index.md with progressive disclosure.
6. Validate OKF conformance via validate-okf.sh.

### 6-16. Not applicable (standard script extension pattern)

### 17. Acceptance criteria
Scenario: Skills-wiki generated (happy path)
  GIVEN 72 SKILL.md files exist
  WHEN bash scripts/sync-skills.sh --okf executes
  THEN specs/skills-wiki/index.md is created
  AND specs/skills-wiki/skills/*.md contains ≥ 70 type: Skill concepts
  AND cross-references are present (build-skill-graph.sh output integrated)

### 18. Out of scope
- Generating OKF bundles for other domains (conventions, agent-guide — those are s05-s06).
- Making --okf the default (keep opt-in until validated).

### 19. Open questions
- Should CI block if --okf fails? Non-blocking initially; blocking after 3
  successful runs (per IMPACT assessment).

### 20. References
- scripts/sync-skills.sh (target script).
- scripts/build-skill-graph.sh (e39s01, cross-reference source).
- specs/IMPACT-e38-okf-adoption.md (OKF adoption assessment).
- GoogleCloudPlatform/knowledge-catalog SPEC.md (OKF v0.1 spec).
