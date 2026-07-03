STORY KEY: E38-S08
TITLE:     Update CLAUDE.md and CONVENTIONS.md with traceability mandate
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The traceability machinery (matrix, blind-spots, gate) exists, but agents
operating outside the release pipeline have no mandate to tag stories. Adding
a Traceability Mandate to CONVENTIONS.md — "Every story MUST have at least one
// story: eNNsNN tag in its implementing code or test file" — and documenting
trace-stories.sh in CLAUDE.md's Commands table ensures every agent session
starts with the mandate visible and every agent knows the command to verify it.

### 2. Value statement
As a developer, I want the traceability mandate to be visible at session start
and the traceability command to be documented, so I can tag my stories without
hunting through epic capsules for the convention.

### 3. Actors and permissions
- Agent (system) — reads CLAUDE.md and CONVENTIONS.md at session start.

### 4. Trigger and preconditions
Trigger: agent session start (CLAUDE.md and CONVENTIONS.md are read).
Precondition: trace-stories.sh exists (e38s01 complete).

### 5. Main flow and business logic
1. Add Traceability Mandate to CONVENTIONS.md under "Agent Workflow Mandates":
   "Every story MUST have at least one // story: eNNsNN tag in its implementing
   code or test file. trace-stories.sh --strict runs in CI."
2. Add trace-stories.sh row to CLAUDE.md Commands table:
   "Traceability | trace-stories.sh --strict | grep for story tags".
3. Verify both files parse and the mandate is discoverable.

### 6-16. Not applicable (standard documentation edit pattern)

### 17. Acceptance criteria
Scenario: Traceability mandate visible
  GIVEN CONVENTIONS.md and CLAUDE.md exist
  WHEN the mandate and command are added
  THEN grep -q 'traceability' CONVENTIONS.md exits 0
  AND grep -q 'traceability' CLAUDE.md exits 0

### 18. Out of scope
- Adding traceability section to other docs (README, docs site).

### 19. Open questions
Not applicable.

### 20. References
- CONVENTIONS.md (target for mandate).
- CLAUDE.md (target for command).
- scripts/trace-stories.sh (e38s01).
