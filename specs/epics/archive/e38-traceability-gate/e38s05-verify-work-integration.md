STORY KEY: E38-S05
TITLE:     Integrate check-blind-spots.sh into verify-work Phase 3
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
check-blind-spots.sh (e38s04) detects structural quality gaps, but detection
without enforcement is noise. Integrating the script into verify-work Phase 3
(manual verification/UAT) ensures every story completion includes a blind-spot
scan. HIGH severity findings block the verify-work PASS gate, catching quality
gaps before they reach the release branch.

### 2. Value statement
As a release engineer, I want blind-spot checks to run automatically during
verification, so quality gaps are caught before merge, not after.

### 3. Actors and permissions
- Agent (system) — executes verify-work skill, which invokes check-blind-spots.sh.

### 4. Trigger and preconditions
Trigger: verify-work Phase 3 execution.
Precondition: check-blind-spots.sh exists (e38s04 complete).

### 5. Main flow and business logic
1. verify-work Phase 3 runs.
2. Execute: bash scripts/check-blind-spots.sh.
3. Surface findings in verify-work report.
4. If any HIGH severity findings → verify-work PASS gate blocked.
5. Agent must resolve HIGH findings before re-running verify-work.

### 6. Alternative flows and exceptions
6a. check-blind-spots.sh not found — skip check, warn in report.
6b. All findings LOW/MEDIUM — report but don't block.
6c. No findings — report "no blind spots detected."

### 7-16. Not applicable (standard skill integration pattern)

### 17. Acceptance criteria
Scenario: Blind-spot check integrated into verify-work
  GIVEN verify-work SKILL.md exists
  WHEN the Phase 3 section is updated
  THEN grep -q 'check-blind-spots.sh' skills/verify-work/SKILL.md exits 0
  AND HIGH severity findings block the PASS gate

### 18. Out of scope
- Adding blind-spot checks to other skills (build-epic, audit-code).
- Changing the verify-work Phase structure.

### 19. Open questions
- Should blind-spot checks also run in audit-code? Deferred — verify-work is
  the right gate because it runs after tests, which is when blind spots matter.

### 20. References
- skills/verify-work/SKILL.md (target skill).
- scripts/check-blind-spots.sh (e38s04).
