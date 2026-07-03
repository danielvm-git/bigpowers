STORY KEY: E32-S07
TITLE:     Create docs/references/ddd.md (bounded contexts, context mapping)
TYPE:      Story
PARENT:    e35
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Domain-Driven Design concepts — bounded contexts, context mapping, ubiquitous
language — directly inform the define-language and model-domain skills. These
skills currently invoke DDD concepts without citing a canonical source.
Creating docs/references/ddd.md provides the provenance link and defines how
bigpowers applies each DDD concept within its spec-driven methodology.

### 2. Value statement
As an agent defining a ubiquitous language or modeling a domain, I want to
cite DDD concepts from a canonical reference, so my modeling is grounded
in established methodology.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/ddd.md.
Precondition: none (new file).

### 5. Main flow and business logic
1. Research: Domain-Driven Design (Evans, 2003), key concepts.
2. Write provenance header: author (Eric Evans), publication, core concepts.
3. Define: bounded context, context mapping, ubiquitous language, aggregate, entity, value object.
4. Map each concept to bigpowers skills: define-language (ubiquitous language), model-domain (context mapping).

### 6-16. Not applicable (standard reference doc pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  Given no existing ddd.md
  When  the doc is created with provenance and key concepts
  Then  test -f docs/references/ddd.md exits 0
  And   grep -q 'bounded context|context map' docs/references/ddd.md exits 0

### 18. Out of scope
- Summarizing the entire DDD book.

### 19. Open questions
Not applicable.

### 20. References
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md.
- Domain-Driven Design (Eric Evans, 2003).
