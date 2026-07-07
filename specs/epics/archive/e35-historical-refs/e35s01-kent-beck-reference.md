STORY KEY: E32-S01
TITLE:     Create docs/references/kent-beck.md (XP, TDD origins, Tidy First?)
TYPE:      Story
PARENT:    e35
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
bigpowers skills (develop-tdd, plan-refactor, enforce-first) rest on practices
Kent Beck originated — Extreme Programming, test-driven development, and the
"Tidy First?" structural-change discipline — yet docs/references/ has no Beck
entry. Agents and contributors citing "red-green-refactor" or "tidy first"
have no canonical in-repo source, unlike bcp.md or uncle-bob.md which anchor
their methodologies. The missing reference weakens traceability from skills to
their intellectual origins.

### 2. Value statement
As a maintainer, I want a canonical Kent Beck reference doc under
docs/references/, so that skills and PRINCIPLES.md can credit and link the
origins of XP, TDD, and Tidy First? instead of restating them ad hoc.

### 3. Actors and permissions
- Maintainer (internal) — authors and reviews the doc.
- Agents/contributors (internal) — read the doc when working on TDD or
  refactoring skills.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e35 backlog.
Precondition: docs/references/ exists and docs/references/bcp.md is available
as the structural pattern to follow.

### 5. Main flow and business logic
1. Create docs/references/kent-beck.md following the existing reference-doc
   pattern (bcp.md): Purpose, Credit, core concepts, "How bigpowers uses",
   See Also.
2. Cover XP origins, TDD (red-green-refactor) origins, and Tidy First?
   (structural vs behavioral changes).
3. Map each concept to the bigpowers skills that embody it (e.g. develop-tdd,
   plan-refactor).
4. Confirm the story verify passes: the file exists and mentions "Tidy First".

### 6. Alternative flows and exceptions
6a. Concept overlaps an existing reference (e.g. tdd.md, uncle-bob.md) —
    link to it in See Also rather than duplicating content.

### 7. Interface elements
Context: new (one Markdown file, docs/references/kent-beck.md).
Static elements: section headers per the bcp.md pattern.
Dynamic elements: none — static documentation.

### 8. Domain model
Entities read: docs/references/bcp.md (pattern), docs/PRINCIPLES.md
(crediting style). Entities created: docs/references/kent-beck.md.

### 9. Integrations and boundaries
Not applicable — plain Markdown, no external systems.

### 10. Background processes
Not applicable — static documentation, no runtime behavior.

### 11. Notifications
Not applicable — no signalling beyond git history.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Depth of coverage (content) — concise reference in the bcp.md style, not a
  book summary.

### 14. Quality attributes *NFR*
- Doc follows the established docs/references/ pattern so agents can parse it
  consistently.
- Verify command is deterministic and runs in < 1 second.

### 15. Security and compliance *NFR*
- Credit the original author and works explicitly; no copied text beyond
  short attributed concepts.

### 16. UX and accessibility *NFR*
Not applicable — Markdown consumed by agents and maintainers.

### 17. Acceptance criteria
Scenario: Reference doc exists with Tidy First coverage (happy path)
  Given the story is implemented
  When  `test -f docs/references/kent-beck.md && grep -q 'Tidy First' docs/references/kent-beck.md && echo OK` is run from the repo root
  Then  it exits 0
  And   prints "OK"

Scenario: Doc follows the reference pattern
  Given docs/references/kent-beck.md exists
  When  the doc is inspected
  Then  it contains Purpose and Credit sections
  And   a section mapping concepts to bigpowers skills

### 18. Out of scope
- Editing PRINCIPLES.md to credit Beck (that is e35s09).
- Editing any SKILL.md to link this doc (that is e35s10).
- Covering Fowler/Feathers material (separate stories).

### 19. Open questions
Not applicable — scope is fully defined by epic.yaml and the bcp.md pattern.

### 20. References
- specs/epics/e35-historical-refs/epic.yaml (story definition and verify).
- docs/references/bcp.md (reference-doc structural pattern).
- docs/PRINCIPLES.md (crediting/link style for references).
