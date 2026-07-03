STORY KEY: E31-S06
TITLE:     Mandate golden suite as pre-merge step
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      XS

### 1. Business narrative
The golden suite exists but is optional — nothing forces a maintainer to run it
before merging. An agent coding session that edits SKILL.md files could introduce
regressions that the suite would catch, but only if the agent knows to run it.
Embedding the command in CLAUDE.md and CONVENTIONS.md makes it a baked-in habit
for both human maintainers and AI agents.

### 2. Value statement
As a maintainer, I want the golden suite documented as a mandatory pre-merge step,
so that every agent and human runs it before opening a PR.

### 3. Actors and permissions
- Maintainer (internal) — runs the suite before merge.
- AI agent (system) — reads CLAUDE.md and executes the command.

### 4. Trigger and preconditions
Trigger: any change to skills/*/SKILL.md or scripts/sync-skills.sh.
Precondition: scripts/run-golden-suite.sh exists (e31s03).

### 5. Main flow and business logic
1. CLAUDE.md is updated to include `run-golden-suite.sh` in the pre-commit checklist.
2. CONVENTIONS.md is updated to mandate `run-golden-suite.sh` before any merge.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Golden suite script does not exist yet — document as "when available" with a note.

### 7. Interface elements
Context: existing (CLAUDE.md, CONVENTIONS.md).
Static elements: new command reference in both files.

### 8. Domain model
Not applicable — documentation change only.

### 9. Integrations and boundaries
Not applicable.

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
Not applicable.

### 13. Solution variabilities
Not applicable — single command reference.

### 14. Quality attributes *NFR*
Not applicable — documentation only.

### 15. Security and compliance *NFR*
Not applicable.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Both files reference the golden suite
  Given scripts/run-golden-suite.sh exists
  When  CLAUDE.md and CONVENTIONS.md are checked
  Then  both files contain a reference to run-golden-suite.sh
  And   the reference includes the command and when to run it

### 18. Out of scope
- Adding a git hook (that is hook-commits' domain).
- CI enforcement (the golden suite already runs in CI via publish.yml compliance gate).

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md (agent instructions).
- CONVENTIONS.md (project conventions).
- e31s03 (run-golden-suite.sh).
