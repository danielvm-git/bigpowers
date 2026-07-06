STORY KEY: E36-S03
TITLE:     Remove F.I.R.S.T rubric restatement from enforce-first and audit-code SKILL.md; replace with CONVENTIONS.md pointer
TYPE:      Story
PARENT:    e36
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The F.I.R.S.T test quality rubric (Fast, Independent, Repeatable, Self-Validating,
Timely) is currently restated in both enforce-first/SKILL.md and audit-code/SKILL.md,
duplicating the canonical definition already present in CONVENTIONS.md. This violates
the DRY principle and creates a maintenance burden: any evolution of the F.I.R.S.T
rubric requires synchronized edits across 3 files. Replacing the restatements with a
provenance pointer to CONVENTIONS.md eliminates the duplication while preserving
discoverability.

### 2. Value statement
As a skill maintainer, I want a single source of truth for the F.I.R.S.T rubric,
so that changes propagate automatically and I don't need to hunt for restatements.

### 3. Actors and permissions
- Skill maintainer (internal) — edits SKILL.md files.
- sync-skills.sh (system) — regenerates artifacts after edit.

### 4. Trigger and preconditions
Trigger: manual edit of enforce-first/SKILL.md and audit-code/SKILL.md.
Precondition: CONVENTIONS.md contains the canonical F.I.R.S.T rubric definition.

### 5. Main flow and business logic
1. Identify all F.I.R.S.T restatements in enforce-first/SKILL.md and audit-code/SKILL.md.
2. Replace each restatement with a provenance pointer: "per CONVENTIONS.md §F.I.R.S.T".
3. Run sync-skills.sh to regenerate .cursor/rules and .gemini extensions.
4. Verify no residual F.I.R.S.T expansions remain in either skill.

### 6. Alternative flows and exceptions
6a. CONVENTIONS.md F.I.R.S.T section missing — create it first, then proceed.
6b. Other skills also restate F.I.R.S.T — flag for follow-up, keep scope to enforce-first + audit-code.

### 7. Interface elements
Context: existing (enforce-first/SKILL.md, audit-code/SKILL.md, CONVENTIONS.md).
Static elements: provenance pointer text "per CONVENTIONS.md §F.I.R.S.T".
Dynamic elements: none (static edit).

### 8. Domain model
Entities modified: skills/enforce-first/SKILL.md, skills/audit-code/SKILL.md.
Entities referenced: CONVENTIONS.md (canonical F.I.R.S.T definition).

### 9. Integrations and boundaries
- sync-skills.sh (direction: out) — regenerates artifacts after SKILL.md edits.
- enforce-first SKILL.md (direction: in/out) — remove restatement, add pointer.
- audit-code SKILL.md (direction: in/out) — remove restatement, add pointer.
- CONVENTIONS.md (direction: in) — canonical source.

### 10. Background processes
Not applicable — manual edit + sync-skills.sh invocation.

### 11. Notifications
Not applicable — no user-facing notification.

### 12. Audit and logging
Not applicable — git diff serves as the change record.

### 13. Solution variabilities
- Pointer format (config) — "per CONVENTIONS.md §F.I.R.S.T" or equivalent.
- Other skills with restatements (config) — address in follow-up if discovered.

### 14. Quality attributes *NFR*
- Completeness: grep for F.I.R.S.T expansions in enforce-first + audit-code returns ≤ 1 match (the pointer itself).
- Idempotency: running the edit twice does not create duplicate pointers.

### 15. Security and compliance *NFR*
- Edit-only operation — no new scripts, no secrets, no network access.
- Safe: no functional change to skill behavior or gating logic.

### 16. UX and accessibility *NFR*
Not applicable — internal skill maintainer edit.

### 17. Acceptance criteria
Scenario: Restatements replaced with pointers (happy path)
  Given enforce-first/SKILL.md and audit-code/SKILL.md contain F.I.R.S.T restatements
  When  the restatements are replaced with "per CONVENTIONS.md §F.I.R.S.T"
  And   sync-skills.sh is executed
  Then  grep -c 'Fast.*Independent.*Repeatable' skills/enforce-first/SKILL.md skills/audit-code/SKILL.md
        shows ≤ 1 total match (the pointer itself)
  And   the regenerated artifacts contain the pointer text

Scenario: CONVENTIONS.md missing F.I.R.S.T (6a)
  Given CONVENTIONS.md lacks an explicit F.I.R.S.T section
  When  the edit is attempted
  Then  a clear error is raised: "CONVENTIONS.md §F.I.R.S.T not found"

### 18. Out of scope
- Auditing other skills for F.I.R.S.T restatements (scope is enforce-first + audit-code only).
- Changing the canonical F.I.R.S.T definition in CONVENTIONS.md.
- Removing F.I.R.S.T entirely from the methodology.

### 19. Open questions
- Are there other rubric restatements (SOLID, INVEST) in skill bodies that should
  also be redirected to CONVENTIONS.md? This is a separate scoping conversation.

### 20. References
- CONVENTIONS.md (canonical F.I.R.S.T definition).
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.5 (dedup mandate).
- skills/enforce-first/SKILL.md (file under edit).
- skills/audit-code/SKILL.md (file under edit).
