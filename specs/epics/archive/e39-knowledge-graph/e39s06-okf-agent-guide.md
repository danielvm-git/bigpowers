STORY KEY: E39-S06
TITLE:     OKF Phase 3b — decompose CLAUDE.md into specs/agent-guide/ for progressive disclosure
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
CLAUDE.md is ~300 lines covering commands, architecture, conventions, workflow,
token management, and "never-do" rules. An agent at session start reads all of it
even if it only needs the Commands table. Decomposing CLAUDE.md into
specs/agent-guide/ — one OKF concept per logical block with type: Guide and thin
pointers ("See: CLAUDE.md §Token Management") — enables token-efficient session
start: agent reads index.md → drills into the section relevant to its current task.
Token savings: ~90% at session start (~300 lines → ~30 lines for index.md + one
subsection).

### 2. Value statement
As an agent starting a session, I want to read only the CLAUDE.md sections
relevant to my task, so I save significant context window space for the actual work.

### 3. Actors and permissions
- scripts/generate-agent-guide.sh (system) — generates the OKF bundle.
- Agent (system) — queries agent-guide for task-relevant instructions.

### 4. Trigger and preconditions
Trigger: `bash scripts/generate-agent-guide.sh` (manual or CI).
Precondition: CLAUDE.md exists with section structure.

### 5. Main flow and business logic
1. Parse CLAUDE.md sections → one OKF concept per logical block.
2. Each concept: title, description (thin provenance pointer to CLAUDE.md §X), type: Guide.
3. Generate index.md as entry point.
4. CLAUDE.md stays as canonical — OKF is derived.

### 6-16. Not applicable (standard decomposition pattern)

### 17. Acceptance criteria
Scenario: Agent-guide generated
  GIVEN CLAUDE.md exists
  WHEN generate-agent-guide.sh runs
  THEN specs/agent-guide/index.md exists
  AND ≥ 6 type: Guide concepts exist
  AND each concept body is a thin pointer to CLAUDE.md §X
  AND CLAUDE.md line count is unchanged (canonical preserved)

### 18. Out of scope
- Auto-regenerating agent-guide when CLAUDE.md changes.

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md (canonical source).
- specs/IMPACT-e38-okf-adoption.md.
