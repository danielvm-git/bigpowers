STORY KEY: E32-S09
TITLE:     Update PRINCIPLES.md to credit Beck, Fowler, Feathers, Hunt & Thomas
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
bigpowers' methodology is built on decades of software engineering thought
leadership — Beck's XP/TDD, Fowler's refactoring, Feathers' legacy code
techniques, Hunt & Thomas' pragmatic principles. Currently PRINCIPLES.md
states principles without crediting their origins. Adding an attribution
section acknowledges the intellectual lineage and cross-references the new
docs/references/ files created in e32s01-s08, making the provenance chain
complete.

### 2. Value statement
As a reader of bigpowers' principles, I want to know where each principle
comes from, so I can trace the intellectual lineage and explore primary sources.

### 3. Actors and permissions
- Documentation maintainer (internal) — edits PRINCIPLES.md.

### 4. Trigger and preconditions
Trigger: manual edit of docs/PRINCIPLES.md.
Precondition: reference docs exist (e32s01-s08 complete).

### 5. Main flow and business logic
1. Audit current PRINCIPLES.md for principles traceable to Beck, Fowler, Feathers, Hunt & Thomas.
2. Add an "Attribution" section at the bottom with per-principle credits.
3. Link each credit to the corresponding docs/references/ file.
4. Run sync-skills.sh to regenerate artifacts if PRINCIPLES.md is referenced by any generated file.

### 6. Alternative flows and exceptions
6a. PRINCIPLES.md missing — create a minimal version with attribution section.
6b. Principle maps to multiple sources — credit all, note the primary.

### 7. Interface elements
Context: existing (docs/PRINCIPLES.md).
Static elements: attribution section, reference links.

### 8. Domain model
Entity modified: docs/PRINCIPLES.md.

### 9. Integrations and boundaries
- docs/references/ files (direction: in) — the documents being credited.
- sync-skills.sh (direction: out) — if PRINCIPLES.md is referenced by generated files.

### 10-16. Not applicable (standard doc edit pattern)

### 17. Acceptance criteria
Scenario: Attribution added to PRINCIPLES.md
  Given docs/PRINCIPLES.md exists
  When  the attribution section is added
  Then  grep -q 'Beck|Fowler|Feathers|Hunt' docs/PRINCIPLES.md exits 0
  And   the section includes links to docs/references/ files

### 18. Out of scope
- Rewriting PRINCIPLES.md principles — this is additive credit only.

### 19. Open questions
Not applicable.

### 20. References
- docs/PRINCIPLES.md (target file).
- docs/references/kent-beck.md, fowler.md, feathers.md, pragmatic-programmer.md.
