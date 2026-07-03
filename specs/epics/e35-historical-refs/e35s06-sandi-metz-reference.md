STORY KEY: E32-S06
TITLE:     Create docs/references/sandi-metz.md (SOLID in practice, message-level testing)
TYPE:      Story
PARENT:    e35
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Sandi Metz's practical application of SOLID principles and her message-level
testing approach (test the messages objects send, not their internals) directly
informs bigpowers' testing skills: develop-tdd, enforce-first, and audit-code.
These skills invoke "test behavior, not implementation" and SOLID principles
without citing a source. Creating docs/references/sandi-metz.md provides the
provenance link.

### 2. Value statement
As an agent writing tests, I want to cite Sandi Metz's message-level testing
approach from a canonical reference, so my test design rationale is traceable.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/sandi-metz.md.
Precondition: none (new file).

### 5. Main flow and business logic
1. Research: POODR (Practical Object-Oriented Design in Ruby), 99 Bottles of OOP.
2. Write provenance header: author (Metz), key works, core concepts.
3. Define: SOLID in practice, message-level testing, duck typing, composition over inheritance.
4. Cross-reference to bigpowers testing skills.

### 6-16. Not applicable (standard reference doc pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  Given no existing sandi-metz.md
  When  the doc is created with provenance and key concepts
  Then  test -f docs/references/sandi-metz.md exits 0
  And   grep -q 'SOLID|message' docs/references/sandi-metz.md exits 0

### 18. Out of scope
Not applicable.

### 19. Open questions
Not applicable.

### 20. References
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md.
- POODR (Sandi Metz, 2012).
- 99 Bottles of OOP (Sandi Metz & Katrina Owen, 2016).
