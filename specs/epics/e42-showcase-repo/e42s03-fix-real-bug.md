STORY KEY: E42-S03
TITLE:     Fix one real bug via the investigate-bug → develop-tdd → validate-fix trail
TYPE:      Story
PARENT:    e42
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The showcase repo demonstrates bigpowers' full methodology — not just the happy
path of building features, but also the bug-fixing discipline that proves the
methodology handles real-world failure. A genuine defect in the showcase app,
fixed through the full investigate-bug → develop-tdd → validate-fix trail,
produces a specs/bugs/BUG-*.md trail showing investigation, root cause analysis,
and a regression test. This is the "bug half" of the methodology — the half that
turns "this methodology looks nice in theory" into "this methodology handled a
real failure transparently."

### 2. Value statement
As a prospective bigpowers adopter, I want to see how the methodology handles
bugs — not just planned features — so I can trust it won't fall apart when
something unexpected happens.

### 3. Actors and permissions
- Agent (system) — executes investigate-bug, develop-tdd, validate-fix in the showcase repo.
- Showcase repo (external) — target repository for the bug fix.

### 4. Trigger and preconditions
Trigger: a genuine defect exists or is introduced in the showcase app.
Precondition: showcase repo exists with a built feature (e42s02).
Precondition: the defect is real — not a trivial typo that bypasses the methodology.

### 5. Main flow and business logic
1. Identify or introduce a genuine defect in the showcase app.
2. Run investigate-bug: explore the codebase, identify root cause.
3. Write specs/bugs/BUG-<slug>.md documenting investigation and fix plan.
4. Run develop-tdd: write a failing regression test, implement the fix.
5. Run validate-fix: re-run the test suite, typecheck, lint, harden against recurrence.
6. Commit with full trail: BUG-*.md + regression test + fix.

### 6. Alternative flows and exceptions
6a. No genuine defect found — introduce a controlled defect (e.g., broken validation).
6b. Fix introduces regression — caught by validate-fix, iterate.
6c. Root cause unclear — escalate to diagnose-root before proceeding.

### 7. Interface elements
Context: new (BUG-*.md in showcase repo, regression test).
Static elements: BUG-*.md format (bigpowers standard bug report).
Dynamic elements: investigation findings, root cause, regression test.

### 8. Domain model
Entities written: specs/bugs/BUG-*.md (investigation + fix plan), test file (regression test).
Entities modified: source file(s) containing the defect.

### 9. Integrations and boundaries
- investigate-bug skill (direction: out) — investigation phase.
- develop-tdd skill (direction: out) — TDD fix implementation.
- validate-fix skill (direction: out) — verification phase.
- e42s02 built feature (direction: in) — the feature containing the defect.

### 10. Background processes
Not applicable — sequential skill execution.

### 11. Notifications
Not applicable — git history is the notification.

### 12. Audit and logging
- BUG-*.md serves as the audit trail (investigation, root cause, fix).
- Regression test serves as the reproducible evidence.
- Git history shows the complete fix timeline.

### 13. Solution variabilities
- Defect source (config) — naturally occurring or intentionally introduced.
- Bug severity (config) — should be non-trivial but bounded (fixable in one session).

### 14. Quality attributes *NFR*
- Investigation quality: root cause identified, not just symptom patched.
- Fix quality: regression test added, full suite passes post-fix.
- Trail completeness: BUG-*.md covers investigation, root cause, fix plan, and verification.

### 15. Security and compliance *NFR*
- If the defect involves user data, follow data-handling best practices.
- Showcase repo is public — no secrets, no real user data.

### 16. UX and accessibility *NFR*
Not applicable — internal methodology demonstration.

### 17. Acceptance criteria
Scenario: Bug fixed with full trail (happy path)
  GIVEN a genuine defect in the showcase app
  WHEN the fix-bug flow runs
  THEN specs/bugs/BUG-*.md documents investigation, root cause, and the fix
  AND a regression test is added that fails before the fix and passes after
  AND the full test suite passes post-fix
  AND the trail is committed to the showcase repo

Scenario: No defect exists (6a)
  GIVEN the showcase app has no known defects
  WHEN a controlled defect is introduced
  THEN the defect is realistic enough to demonstrate the methodology
  AND the fix trail is committed with an honest note ("defect introduced for demonstration")

### 18. Out of scope
- Fixing multiple bugs (one is sufficient for demonstration).
- Introducing a security vulnerability as the defect.
- Adding the showcase repo's bugs to bigpowers' bug registry.

### 19. Open questions
- What constitutes a "genuine" defect? Should it be naturally occurring (more
  authentic) or introduced (more controllable)? Leaning toward natural if one
  exists, controlled introduction if not.
- Should the bug be in the feature built in e42s02 or a separate area? Either
  is fine — the trail matters more than the location.

### 20. References
- specs/epics/e42-showcase-repo/epic.yaml (parent epic, bug trail story).
- skills/investigate-bug/SKILL.md (investigation skill).
- skills/develop-tdd/SKILL.md (TDD skill).
- skills/validate-fix/SKILL.md (verification skill).
