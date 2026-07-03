STORY KEY: E39-S01
TITLE:     Create scripts/build-skill-graph.sh — parse handoff chains and dependencies from 72 SKILL.md files
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The 72 skills under skills/ form an implicit dependency graph — handoff chains
("run X after Y"), hard gates ("HARD GATE: must run Z first"), convention
references ("per CONVENTIONS.md §X"), and model routing hints — but that graph
lives only in prose scattered across 72 SKILL.md files. No tool can answer
"what skills would break if I change develop-tdd?". This is the Layer 3
(Technical Context) gap identified in the stack-layer analysis: the skill
reference graph exists but is not machine-readable.

### 2. Value statement
As a maintainer, I want a script that parses all SKILL.md files into an
explicit dependency graph and OKF bundle, so that skill-to-skill impact
questions become queryable instead of requiring a manual read of 72 files.

### 3. Actors and permissions
- Maintainer (internal) — runs the script locally.
- CI runner (system) — may execute the script in workflows (via e39s04).
- Agent (system) — consumes specs/skill-graph.json to answer impact queries.

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/build-skill-graph.sh`) or invoked by
sync-skills.sh --okf (e39s04).
Precondition: skills/*/SKILL.md files exist with valid frontmatter.

### 5. Main flow and business logic
1. Script iterates over all skills/*/SKILL.md files (frontmatter + prose).
2. Extracts from each skill:
   - handoff.next_skill references ("run X after Y", "HARD GATE: must run Z first")
   - Convention references ("per CONVENTIONS.md §X", naming rules)
   - Model routing hints (model: sonnet/haiku)
   - Dependency keywords ("depends on", "requires", "reads", "writes to")
3. Emits specs/skill-graph.json — machine-readable dependency graph
   (nodes = skills, edges = depends_on/referenced_by/handoff_to).
4. Emits specs/skills-wiki/ as an OKF bundle with cross-references
   between skill concepts.
5. Exits 0 on success; non-zero with an error message on parse failure.
Interruption point: N/A (batch script runs to completion).

### 6. Alternative flows and exceptions
6a. SKILL.md with unparseable frontmatter — report file path, skip node, exit 1.
6b. Reference to a non-existent skill — record as dangling edge, warn on stdout.
6c. skills/ directory empty or missing — report and exit 1.
6d. --help flag — print usage and exit 0.

### 7. Interface elements
Context: new (standalone bash script).
Static elements: --help usage text, exit codes (0/1).
Dynamic elements: node/edge counts on stdout, dangling-edge warnings.

### 8. Domain model
Entities read: skills/*/SKILL.md (frontmatter + prose).
Entities written: specs/skill-graph.json (nodes, edges with edge types
depends_on/referenced_by/handoff_to), specs/skills-wiki/ OKF concepts
(one per skill, type: Skill) with cross-reference links.

### 9. Integrations and boundaries
- skills/ catalog (perennial, direction: in) — source of truth being parsed.
- e39s04 sync-skills.sh --okf (planned, direction: out) — invokes this script
  as step 3 of OKF bundle generation.
- e39s10 validate-okf.sh conformance (planned, direction: out) — the emitted
  skills-wiki bundle must pass OKF v0.1 conformance.
- IMPACT-e38-okf-adoption.md frontmatter extensions (reference) — edges use
  the custom fields handoff_next, depends_on, gates defined there.

### 10. Background processes
Not applicable — invoked synchronously by maintainer or sync pipeline.

### 11. Notifications
Not applicable — exit code and stdout are the only signalling mechanism.

### 12. Audit and logging
Not applicable — outputs are regenerable derived artifacts under git.

### 13. Solution variabilities
- Extraction patterns (config) — dependency keyword list is a script-local
  array, extensible without structural change.
- Output paths (config) — specs/skill-graph.json and specs/skills-wiki/
  hardcoded initially.

### 14. Quality attributes *NFR*
- Wall-clock: seconds, not minutes (text parsing over ~72 files, no network).
- Deterministic: same SKILL.md inputs → identical graph output, every run.
- Idempotent: safe to re-run; outputs are fully regenerated.

### 15. Security and compliance *NFR*
- Reads only project files; writes only under specs/. No secrets, no network.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by maintainers, agents, and CI.

### 17. Acceptance criteria
Scenario: Graph generated from full catalog (happy path)
  Given all 72 skills/*/SKILL.md files have valid frontmatter
  When  build-skill-graph.sh is executed
  Then  it exits 0
  And   specs/skill-graph.json contains one node per skill
  And   edges carry types depends_on, referenced_by, or handoff_to
  And   specs/skills-wiki/ contains one OKF concept per skill

Scenario: Impact query is answerable
  Given specs/skill-graph.json has been generated
  When  the edges pointing at "develop-tdd" are filtered from the JSON
  Then  every skill that references develop-tdd appears as a referenced_by edge

Scenario: Unparseable frontmatter (6a)
  Given one SKILL.md has invalid frontmatter
  When  build-skill-graph.sh is executed
  Then  it exits 1
  And   reports the offending file path

Scenario: Dangling reference (6b)
  Given a SKILL.md references a skill that does not exist
  When  build-skill-graph.sh is executed
  Then  the edge is recorded as dangling
  And   a warning naming the missing target is printed

Scenario: Help flag (6d)
  Given the script exists
  When  build-skill-graph.sh --help is executed
  Then  it prints usage and exits 0

### 18. Out of scope
- Generating the skills-wiki index.md and CI wiring (e39s04).
- OKF conformance validation logic itself (e39s10).
- Visualizing the graph (visual-dashboard / viz.html are future companions).

### 19. Open questions
- Edge-extraction precision: prose patterns like "run X after Y" are heuristic;
  acceptable false-negative rate to be settled during implementation review.

### 20. References
- specs/epics/e39-knowledge-graph/epic.yaml (e39s01 description).
- specs/IMPACT-e38-okf-adoption.md (OKF findings, custom type/field taxonomy).
- skills/*/SKILL.md (72 source files being parsed).
