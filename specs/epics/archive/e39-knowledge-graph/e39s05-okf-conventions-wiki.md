STORY KEY: E39-S05
TITLE:     OKF Phase 3a — decompose CONVENTIONS.md into specs/conventions-wiki/
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
CONVENTIONS.md is ~300 lines of rules that every agent must know. Reading the
full file at session start is wasteful when the agent only needs a subset.
Decomposing CONVENTIONS.md into specs/conventions-wiki/ — one OKF concept per
top-level rule with type: Convention — enables progressive disclosure: agent
reads index.md, drills into the specific convention it needs, and follows
cross-references to skills that enforce that convention. CONVENTIONS.md stays
as the canonical single source; the OKF bundle is a derived, navigable view.

### 2. Value statement
As an agent starting a session, I want to read only the conventions relevant
to my current task, so I save ~90% of the token cost of reading the full
CONVENTIONS.md.

### 3. Actors and permissions
- scripts/decompose-conventions.sh (system) — generates the OKF bundle.
- Agent (system) — queries conventions-wiki for task-relevant rules.

### 4. Trigger and preconditions
Trigger: `bash scripts/decompose-conventions.sh` (manual or CI).
Precondition: CONVENTIONS.md exists with heading structure.

### 5. Main flow and business logic
1. Parse CONVENTIONS.md headings → one OKF concept per top-level rule.
2. Each concept carries: title, description (thin provenance pointer to CONVENTIONS.md §X), type: Convention.
3. Cross-reference: which skills enforce this convention? (from build-skill-graph.sh output).
4. Generate specs/conventions-wiki/index.md for progressive disclosure.
5. CONVENTIONS.md stays as canonical single source — OKF is derived.

### 6-16. Not applicable (standard decomposition pattern)

### 17. Acceptance criteria
Scenario: Conventions-wiki generated
  GIVEN CONVENTIONS.md exists
  WHEN decompose-conventions.sh runs
  THEN specs/conventions-wiki/index.md exists
  AND ≥ 10 type: Convention concepts exist
  AND each concept body is a thin pointer to CONVENTIONS.md §X
  AND CONVENTIONS.md line count is unchanged (canonical preserved)

### 18. Out of scope
- Auto-updating conventions-wiki when CONVENTIONS.md changes (manual regeneration initially).

### 19. Open questions
- Should conventions-wiki regenerate automatically on sync-skills.sh? Deferred
  — manual first, then CI integration after validation.

### 20. References
- CONVENTIONS.md (canonical source).
- scripts/build-skill-graph.sh (e39s01, cross-reference source).
- specs/IMPACT-e38-okf-adoption.md.
