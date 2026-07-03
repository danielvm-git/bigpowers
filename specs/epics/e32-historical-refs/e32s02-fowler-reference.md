STORY KEY: E32-S02
TITLE:     Create docs/references/fowler.md (refactoring catalog, code smells)
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
plan-refactor and deepen-architecture lean on Martin Fowler's refactoring
vocabulary — named refactorings like Extract Method and the code-smell
taxonomy — but docs/references/ has no Fowler entry. Without a canonical
in-repo source, skills restate refactoring terminology inconsistently and
contributors cannot trace "code smell" language to its origin the way
uncle-bob.md or ousterhout.md anchor their material.

### 2. Value statement
As a maintainer, I want a canonical Martin Fowler reference doc under
docs/references/, so that refactoring skills can credit and link the
refactoring catalog and code-smell taxonomy instead of restating them ad hoc.

### 3. Actors and permissions
- Maintainer (internal) — authors and reviews the doc.
- Agents/contributors (internal) — read the doc when planning refactors.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e32 backlog.
Precondition: docs/references/ exists and docs/references/bcp.md is available
as the structural pattern to follow.

### 5. Main flow and business logic
1. Create docs/references/fowler.md following the reference-doc pattern
   (bcp.md): Purpose, Credit, core concepts, "How bigpowers uses", See Also.
2. Cover the refactoring catalog (named refactorings, Extract Method as the
   flagship example) and the code-smell taxonomy.
3. Map concepts to the bigpowers skills that embody them (e.g. plan-refactor,
   deepen-architecture).
4. Confirm the story verify passes: file exists and matches the epic.yaml
   grep pattern 'Extract Method|code smell'.

### 6. Alternative flows and exceptions
6a. Concept overlaps an existing reference (e.g. uncle-bob.md on smells) —
    link to it in See Also rather than duplicating content.

### 7. Interface elements
Context: new (one Markdown file, docs/references/fowler.md).
Static elements: section headers per the bcp.md pattern.
Dynamic elements: none — static documentation.

### 8. Domain model
Entities read: docs/references/bcp.md (pattern), docs/PRINCIPLES.md
(crediting style). Entities created: docs/references/fowler.md.

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
  full catalog reproduction.

### 14. Quality attributes *NFR*
- Doc follows the established docs/references/ pattern.
- Verify command is deterministic and runs in < 1 second.

### 15. Security and compliance *NFR*
- Credit the original author and works explicitly; no copied text beyond
  short attributed concepts.

### 16. UX and accessibility *NFR*
Not applicable — Markdown consumed by agents and maintainers.

### 17. Acceptance criteria
Scenario: Reference doc exists with catalog/smell coverage (happy path)
  Given the story is implemented
  When  `test -f docs/references/fowler.md && grep -q 'Extract Method|code smell' docs/references/fowler.md && echo OK` is run from the repo root
  Then  it exits 0
  And   prints "OK"

Scenario: Doc follows the reference pattern
  Given docs/references/fowler.md exists
  When  the doc is inspected
  Then  it contains Purpose and Credit sections
  And   a section mapping concepts to bigpowers skills

### 18. Out of scope
- Editing PRINCIPLES.md to credit Fowler (that is e32s09).
- Editing skills/plan-refactor/SKILL.md to link this doc (that is e32s10).
- Beck's Tidy First? material (e32s01).

### 19. Open questions
- The epic verify uses plain grep with 'Extract Method|code smell'; plain
  grep treats '|' literally, so the doc must satisfy the command as written
  (e.g. contain the literal alternation string) or the epic verify should be
  read as intending grep -E. Flagged for the implementer; the epic.yaml
  verify is left unchanged per planning constraints.

### 20. References
- specs/epics/e32-historical-refs/epic.yaml (story definition and verify).
- docs/references/bcp.md (reference-doc structural pattern).
- docs/PRINCIPLES.md (crediting/link style for references).
