STORY KEY: E38-S04
TITLE:     Create scripts/check-blind-spots.sh — heuristic quality detector
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Percentage coverage alone is insufficient — a story can have 100% code tags but
zero test coverage, or a "done" story can have stale tags. The TEA traceability
approach (from the market survey) introduced heuristic blind-spot detection:
verify-gap (story done but no verify ran), test-gap (tagged code, no test files),
epic-orphan (task with no story tag), stale-tag (done story, tag still present),
double-tag (one file tagged with multiple stories), bootstrap-testless (new story
without test tag). These structural checks catch quality gaps that percentage
coverage cannot see.

### 2. Value statement
As a release engineer, I want heuristic blind-spot detection beyond percentage
coverage, so I can catch quality gaps like untested tagged code or stale tags
that percentage coverage would miss.

### 3. Actors and permissions
- Agent (system) — runs check-blind-spots.sh.
- CI runner (system) — executes in pipeline.

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/check-blind-spots.sh`) or CI (verify-work, sync-skills).
Precondition: specs/execution-status.yaml, specs/release-plan.yaml, and traceability matrix exist.

### 5. Main flow and business logic
1. Read specs/execution-status.yaml for story states (done/active/backlog).
2. Read traceability matrix for code-tag coverage.
3. Run six heuristic checks:
   a. verify-gap: story done but no verify command executed.
   b. test-gap: code tagged, no test file references.
   c. epic-orphan: task in capsule, no story tag anywhere.
   d. stale-tag: story done but tag still in code.
   e. double-tag: same file tagged with multiple stories.
   f. bootstrap-testless: new story without test tag.
4. Assign severity (HIGH/MEDIUM/LOW) to each finding.
5. Emit specs/blind-spots.json with findings + remediation hints.
6. Exit 0 on no HIGH findings; exit 1 if any HIGH findings.

### 6. Alternative flows and exceptions
6a. execution-status.yaml not found — exit 1, cannot check blind spots.
6b. No findings — emit empty blind-spots.json with validation timestamp.
6c. Partial data (e.g., no traceability matrix) — skip dependent checks, note limitations.

### 7-16. Not applicable (standard script creation pattern)

### 17. Acceptance criteria
Scenario: Blind spots detected and reported
  GIVEN a codebase with known quality gaps (stale tags, untested code)
  WHEN check-blind-spots.sh runs
  THEN specs/blind-spots.json is emitted with findings
  AND each finding has severity and remediation hint
  AND --help shows usage

Scenario: Clean codebase
  GIVEN all stories done with verify, all code tagged, no orphans
  WHEN check-blind-spots.sh runs
  THEN it exits 0
  AND blind-spots.json shows zero findings

### 18. Out of scope
- Auto-fixing blind spots (this is detection only).
- Blocking CI on LOW/MEDIUM findings (only HIGH blocks).

### 19. Open questions
- Should double-tag be HIGH or MEDIUM severity? MEDIUM — same file multiple
  stories is unusual but not necessarily wrong (e.g., shared utility).
- How to detect "no test file references" without a language-specific test
  runner? File-naming heuristics: spec/test files in matching directories.

### 20. References
- BMAD TEA traceability approach (market survey 2026-07-02).
- scripts/trace-stories.sh (e38s01, produces traceability matrix).
- specs/execution-status.yaml (story state source).
