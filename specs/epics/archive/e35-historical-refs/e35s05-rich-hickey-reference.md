STORY KEY: E32-S05
TITLE:     Create docs/references/rich-hickey.md (simple vs easy, complecting)
TYPE:      Story
PARENT:    e35
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Rich Hickey's distinction between "simple" and "easy" and the concept of
"complecting" (interleaving concerns) is foundational to several bigpowers
design principles. The deepen-architecture skill explicitly references these
concepts, and the design-interface skill invokes the "simple vs easy" trade-off.
Without a canonical reference doc, agents lack a citable source for these
distinctions.

### 2. Value statement
As an agent reasoning about architecture trade-offs, I want a canonical
reference for "simple vs easy" and "complecting", so my recommendations
are grounded in a well-known conceptual framework.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/rich-hickey.md.
Precondition: none (new file).

### 5. Main flow and business logic
1. Research key concepts: simple vs easy, complecting, design vs composition.
2. Write provenance header: author (Hickey), key talk ("Simple Made Easy", 2011).
3. Define each concept with original meaning and bigpowers application.
4. Add cross-references to skills that use these concepts.

### 6. Alternative flows and exceptions
Not applicable.

### 7. Interface elements
Context: new (docs/references/rich-hickey.md).

### 8. Domain model
Entity created: docs/references/rich-hickey.md.

### 9. Integrations and boundaries
- deepen-architecture SKILL.md (direction: out) — references simple vs easy.
- design-interface SKILL.md (direction: out) — references simple vs easy trade-off.

### 10. Background processes
Not applicable.

### 11-16. Not applicable (standard reference doc pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  Given no existing rich-hickey.md
  When  the doc is created with provenance and key concepts
  Then  test -f docs/references/rich-hickey.md exits 0
  And   grep -q 'simple.*easy|complect' docs/references/rich-hickey.md exits 0

### 18. Out of scope
- Transcribing the entire "Simple Made Easy" talk.

### 19. Open questions
Not applicable.

### 20. References
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md.
- "Simple Made Easy" (Rich Hickey, Strange Loop 2011).
