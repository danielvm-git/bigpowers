STORY KEY: E32-S03
TITLE:     Create docs/references/feathers.md (seams, characterization tests)
TYPE:      Story
PARENT:    e35
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
investigate-bug and develop-tdd operate on existing code where behavior must
be pinned down before change — exactly the territory of Michael Feathers'
"Working Effectively with Legacy Code" (seams, characterization tests) — yet
docs/references/ has no Feathers entry. Skills that tell agents to "write a
characterization test first" have no canonical in-repo source for the term,
weakening traceability from skills to their intellectual origins.

### 2. Value statement
As a maintainer, I want a canonical Michael Feathers reference doc under
docs/references/, so that legacy-code skills can credit and link seams and
characterization tests instead of restating them ad hoc.

### 3. Actors and permissions
- Maintainer (internal) — authors and reviews the doc.
- Agents/contributors (internal) — read the doc when changing legacy code.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e35 backlog.
Precondition: docs/references/ exists and docs/references/bcp.md is available
as the structural pattern to follow.

### 5. Main flow and business logic
1. Create docs/references/feathers.md following the reference-doc pattern
   (bcp.md): Purpose, Credit, core concepts, "How bigpowers uses", See Also.
2. Cover seams (points where behavior can be altered without editing the
   code) and characterization tests (pinning current behavior before change).
3. Map concepts to the bigpowers skills that embody them (e.g.
   investigate-bug, develop-tdd, diagnose-root).
4. Confirm the story verify passes: file exists and matches the epic.yaml
   grep pattern 'characterization|seam'.

### 6. Alternative flows and exceptions
6a. Concept overlaps an existing reference (e.g. tdd.md) — link to it in
    See Also rather than duplicating content.

### 7. Interface elements
Context: new (one Markdown file, docs/references/feathers.md).
Static elements: section headers per the bcp.md pattern.
Dynamic elements: none — static documentation.

### 8. Domain model
Entities read: docs/references/bcp.md (pattern), docs/PRINCIPLES.md
(crediting style). Entities created: docs/references/feathers.md.

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
- Doc follows the established docs/references/ pattern.
- Verify command is deterministic and runs in < 1 second.

### 15. Security and compliance *NFR*
- Credit the original author and works explicitly; no copied text beyond
  short attributed concepts.

### 16. UX and accessibility *NFR*
Not applicable — Markdown consumed by agents and maintainers.

### 17. Acceptance criteria
Scenario: Reference doc exists with seams/characterization coverage (happy path)
  Given the story is implemented
  When  `test -f docs/references/feathers.md && grep -q 'characterization|seam' docs/references/feathers.md && echo OK` is run from the repo root
  Then  it exits 0
  And   prints "OK"

Scenario: Doc follows the reference pattern
  Given docs/references/feathers.md exists
  When  the doc is inspected
  Then  it contains Purpose and Credit sections
  And   a section mapping concepts to bigpowers skills

### 18. Out of scope
- Editing PRINCIPLES.md to credit Feathers (that is e35s09).
- Editing skills/investigate-bug/SKILL.md to link this doc (that is e35s10).

### 19. Open questions
- The epic verify uses plain grep with 'characterization|seam'; plain grep
  treats '|' literally. The implementer should satisfy the intent (grep -E)
  or the literal command; epic.yaml is left unchanged per planning
  constraints.

### 20. References
- specs/epics/e35-historical-refs/epic.yaml (story definition and verify).
- docs/references/bcp.md (reference-doc structural pattern).
- docs/PRINCIPLES.md (crediting/link style for references).
