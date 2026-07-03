STORY KEY: E32-S10
TITLE:     Cross-reference new docs from SKILL.md bodies
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The new reference docs (e32s01-s08) exist but skills that use the underlying
concepts don't yet cite them. Without cross-references, the agent has no
navigable path from a skill's reasoning to the canonical reference — the docs
exist in isolation. Adding cross-references (at minimum: fowler in plan-refactor,
feathers in investigate-bug) makes the provenance chain navigable for agents
and humans alike.

### 2. Value statement
As an agent executing a skill, I want navigable links from the skill's principles
to their canonical reference docs, so I can ground my reasoning without guessing.

### 3. Actors and permissions
- Skill maintainer (internal) — edits SKILL.md files.
- sync-skills.sh (system) — regenerates artifacts after edits.

### 4. Trigger and preconditions
Trigger: manual edit of affected SKILL.md files.
Precondition: reference docs exist (e32s01-s08 complete).

### 5. Main flow and business logic
1. Audit skills that use principles from the new reference docs.
2. For each skill, add a "See: docs/references/<name>.md" note in the relevant section.
3. Target minimum: plan-refactor (Fowler, refactoring catalog), investigate-bug (Feathers, characterization tests).
4. Run sync-skills.sh to regenerate artifacts.
5. Verify references resolve to existing files.

### 6. Alternative flows and exceptions
6a. Skill doesn't have an obvious place for a cross-reference — add to §20 References.
6b. Reference doc doesn't exist yet — skip, flag for later.

### 7. Interface elements
Context: existing (multiple SKILL.md files).

### 8. Domain model
Entities modified: skills/plan-refactor/SKILL.md, skills/investigate-bug/SKILL.md, potentially others.

### 9. Integrations and boundaries
- docs/references/ files (direction: in) — the documents being cross-referenced.
- sync-skills.sh (direction: out) — regenerates .cursor/rules and .gemini extensions.

### 10-16. Not applicable (standard cross-referencing edit)

### 17. Acceptance criteria
Scenario: Cross-references added to minimum targets
  Given plan-refactor and investigate-bug SKILL.md files exist
  When  cross-references are added
  Then  grep -q 'fowler' skills/plan-refactor/SKILL.md exits 0
  And   grep -q 'feathers|characterization' skills/investigate-bug/SKILL.md exits 0

### 18. Out of scope
- Cross-referencing every skill that could use these docs — minimum viable: plan-refactor + investigate-bug.
- Updating skill content beyond adding reference links.

### 19. Open questions
- Should cross-references use a standard format (e.g., "See: docs/references/...")?
  Yes — adopt "See: docs/references/<name>.md" as the standard format.

### 20. References
- docs/references/fowler.md, feathers.md, kent-beck.md, pragmatic-programmer.md.
- skills/plan-refactor/SKILL.md, skills/investigate-bug/SKILL.md.
