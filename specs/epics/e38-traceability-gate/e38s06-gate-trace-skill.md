STORY KEY: E38-S06
TITLE:     Create gate-trace skill — deterministic quality gate before release
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The traceability pipeline now has a coverage matrix (e38s01) and blind-spot
detector (e38s04), but there is no single gate that combines them into a
release-blocking decision. The gate-trace skill reads both artifacts, applies
deterministic decision rules (TEA-inspired PASS/CONCERNS/FAIL/WAIVED), and
applies oracle confidence downgrades — if >50% of trace links come from
heuristics rather than explicit story tags, the verdict is downgraded one level.
This makes the gate auditable and honest: the agent knows when it's guessing.

### 2. Value statement
As a release engineer, I want a single deterministic gate that combines coverage
and blind-spot data into a PASS/FAIL decision before release, so I don't have
to manually interpret two separate reports.

### 3. Actors and permissions
- Agent (system) — executes gate-trace skill.
- Release engineer (internal) — reviews gate decision and rationale.

### 4. Trigger and preconditions
Trigger: invocation before release (via release-branch).
Precondition: specs/traceability-matrix.json exists (e38s01).
Precondition: specs/blind-spots.json exists (e38s04).

### 5. Main flow and business logic
1. Read specs/traceability-matrix.json and specs/blind-spots.json.
2. Apply gate decision rules:
   - Any undone story with 0 code tags → FAIL.
   - Any story done but no verify → CONCERNS.
   - P0 story with 0% coverage → FAIL.
   - Overall coverage < 60% → CONCERNS.
   - Overall ≥ 80% + no critical gaps + all verify → PASS.
3. Apply oracle confidence downgrade:
   - > 50% trace links from heuristics (not explicit tags) → one level downgrade.
   - > 80% from heuristics → two levels (PASS→FAIL, CONCERNS→FAIL).
4. Output gate decision + rationale to stdout.
5. Update specs/execution-status.yaml with gate-trace result.

### 6. Alternative flows and exceptions
6a. Matrix or blind-spots.json missing — gate returns WAIVED with reason.
6b. execution-status.yaml has conflicts — report conflict, gate CONCERNS.

### 7. Interface elements
Context: new (skills/gate-trace/SKILL.md).
Static elements: gate decision rules, oracle confidence downgrade table.
Dynamic elements: PASS/CONCERNS/FAIL/WAIVED verdict per run.

### 8. Domain model
Entities read: specs/traceability-matrix.json, specs/blind-spots.json.
Entities written: specs/execution-status.yaml (gate-trace field).

### 9. Integrations and boundaries
- trace-stories.sh (direction: in) — produces traceability matrix.
- check-blind-spots.sh (direction: in) — produces blind-spots.json.
- release-branch SKILL.md (direction: out) — consumer of gate decision.
- sync-skills.yml (direction: out) — CI consumer.

### 10-16. Not applicable (standard skill creation pattern)

### 17. Acceptance criteria
Scenario: Clean codebase passes gate
  GIVEN overall ≥ 80% coverage, no critical gaps, all verify done
  WHEN gate-trace runs
  THEN it returns PASS
  AND output includes rationale citing coverage and blind-spot results

Scenario: P0 story untagged
  GIVEN a P0 story has 0% code coverage
  WHEN gate-trace runs
  THEN it returns FAIL
  AND rationale names the offending story

Scenario: Heuristic downgrade
  GIVEN > 50% of trace links come from file-name heuristics
  WHEN gate-trace runs with otherwise PASS
  THEN it returns CONCERNS
  AND rationale cites the heuristic link ratio

### 18. Out of scope
- Auto-remediating traceability gaps (gate-trace is decision-only).
- Replacing the human release decision (gate is advisory for CONCERNS).

### 19. Open questions
- Should WAIVED be a permanent state or require re-evaluation on next release?
  Re-evaluation: WAIVED means "cannot decide now," not "permanently excused."

### 20. References
- BMAD TEA traceability approach (market survey 2026-07-02).
- scripts/trace-stories.sh (e38s01).
- scripts/check-blind-spots.sh (e38s04).
- specs/execution-status.yaml (output target).
