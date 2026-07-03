STORY KEY: E32-S04
TITLE:     Create docs/references/pragmatic-programmer.md (DRY, broken windows, tracer bullets)
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Several bigpowers skills reference principles from The Pragmatic Programmer (DRY,
broken windows theory, tracer bullets, orthogonality) without a canonical reference
doc. The principles are invoked in plan-refactor, diagnose-root, and spike-prototype
but the agent has no authoritative source to cite. Creating docs/references/pragmatic-programmer.md
provides a provenance pointer — author, publication, key concepts with definitions,
and how bigpowers applies each concept.

### 2. Value statement
As an agent executing a skill that invokes a Hunt & Thomas principle, I want a
canonical reference doc to cite, so my reasoning is traceable to a known source.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/pragmatic-programmer.md.
Precondition: none (new file).

### 5. Main flow and business logic
1. Research key concepts: DRY, broken windows, tracer bullets, orthogonality, cat ate my source code.
2. Write provenance header: authors (Hunt & Thomas), publication year (1999), edition notes.
3. Define each concept with original meaning and bigpowers application.
4. Add cross-references to skills that use each concept.

### 6. Alternative flows and exceptions
Not applicable — straightforward reference doc creation.

### 7. Interface elements
Context: new (docs/references/pragmatic-programmer.md).
Static elements: provenance header, per-concept definitions.

### 8. Domain model
Entity created: docs/references/pragmatic-programmer.md.

### 9. Integrations and boundaries
- plan-refactor SKILL.md (direction: out) — may cross-reference for DRY.
- diagnose-root SKILL.md (direction: out) — may cross-reference for tracer bullets.
- spike-prototype SKILL.md (direction: out) — may cross-reference for tracer bullets.

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
Not applicable.

### 13. Solution variabilities
Not applicable.

### 14. Quality attributes *NFR*
- Accuracy: each concept definition matches the original source.
- Conciseness: ≤ 50 lines (provenance pointer, not a book summary).

### 15. Security and compliance *NFR*
Not applicable.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Reference doc created (happy path)
  Given no existing pragmatic-programmer.md
  When  the doc is created with provenance header and key concepts
  Then  test -f docs/references/pragmatic-programmer.md exits 0
  And   grep -q 'broken window|tracer bullet' docs/references/pragmatic-programmer.md exits 0

### 18. Out of scope
- Summarizing the entire book — this is a provenance pointer and concept reference.
- Updating all skills that use these principles (that is e32s10).

### 19. Open questions
Not applicable.

### 20. References
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md (parent planning doc).
- The Pragmatic Programmer (Hunt & Thomas, 1999).
