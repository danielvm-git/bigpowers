STORY KEY: E38-S07
TITLE:     Wire gate-trace into release-branch pre-PR gate
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
gate-trace (e38s06) makes a deterministic PASS/FAIL/CONCERNS decision, but it
must be invoked to matter. Wiring gate-trace into release-branch SKILL.md as a
pre-PR gate ensures every merge is gated on traceability: FAIL blocks the merge,
CONCERNS requires an explicit human override in state.yaml. This closes the
loop from detection → decision → enforcement, making traceability a hard gate
rather than an informational report.

### 2. Value statement
As a release engineer, I want traceability gating to be automatic at merge time,
so I don't have to remember to check coverage before opening a PR.

### 3. Actors and permissions
- Agent (system) — executes release-branch skill, which invokes gate-trace.

### 4. Trigger and preconditions
Trigger: release-branch execution (pre-PR step).
Precondition: gate-trace skill exists (e38s06 complete).

### 5. Main flow and business logic
1. release-branch executes pre-PR checks.
2. Invoke gate-trace skill.
3. On PASS → proceed with PR creation.
4. On FAIL → block merge, report gate-trace rationale.
5. On CONCERNS → require explicit human override in state.yaml before proceeding.
6. On WAIVED → skip gate (no matrix/blind-spots available).

### 6. Alternative flows and exceptions
6a. gate-trace skill not found — skip gate, warn.
6b. Human override format unclear — default to requiring a state.yaml handoff.context note.

### 7-16. Not applicable (standard skill integration pattern)

### 17. Acceptance criteria
Scenario: Gate blocks merge on FAIL
  GIVEN gate-trace returns FAIL
  WHEN release-branch pre-PR gate runs
  THEN merge is blocked
  AND the FAIL rationale is reported

Scenario: Gate allows merge on PASS
  GIVEN gate-trace returns PASS
  WHEN release-branch pre-PR gate runs
  THEN PR creation proceeds

### 18. Out of scope
- Changing the release-branch flow beyond adding the gate.
- Adding gate-trace to kickoff-branch (traceability is a release concern).

### 19. Open questions
- Should the human override for CONCERNS be documented in the traceability guide?
  Yes — add override instructions to docs/references/traceability-gate.md (e38s09).

### 20. References
- skills/release-branch/SKILL.md (target skill).
- skills/gate-trace/SKILL.md (e38s06).
- specs/execution-status.yaml (override target).
