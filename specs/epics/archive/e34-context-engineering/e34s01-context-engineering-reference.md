STORY KEY: E34-S01
TITLE:     Create docs/references/context-engineering.md (write/select/compress/isolate framework)
TYPE:      Story
PARENT:    e34
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
bigpowers already practices the four canonical context-engineering strategies
— write (persist state to specs/), select (survey-context reads only what is
needed), compress (terse-mode, sqz, token budgets), isolate (subagents via
dispatch-agents/delegate-task) — but nowhere names them. GSD Core's central
insight is that naming the strategies makes them teachable and auditable.
Without a reference document, contributors and skills cite the practices
inconsistently, and downstream stories (e34s03, e34s04) have no canonical
source to link to.

### 2. Value statement
As a bigpowers maintainer, I want a single reference document that names the
write/select/compress/isolate framework and maps each strategy to the existing
skills that implement it, so that all skills and docs can cite one canonical
vocabulary.

### 3. Actors and permissions
- Maintainer (internal) — authors and reviews the reference document.
- Skill authors (internal) — cite the document from SKILL.md files and CLAUDE.md.
- AI agents (system) — read the document when reasoning about token discipline.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e34 epic capsule.
Precondition: none beyond repo checkout; document is net-new
(docs/references/ may need to be created).

### 5. Main flow and business logic
1. Create docs/references/context-engineering.md.
2. Define the four strategies in order: write, select, compress, isolate —
   one section each with a one-paragraph definition.
3. For each strategy, map the bigpowers skills/mechanisms that already
   implement it (e.g. write → session-state/specs; select → survey-context;
   compress → terse-mode/sqz; isolate → dispatch-agents/delegate-task).
4. Credit the framework's origin (GSD Core insight) in the references section
   of the document.
Interruption point: N/A — single-document authoring task.

### 6. Alternative flows and exceptions
6a. docs/references/ directory does not exist — create it as part of this story.
6b. A strategy has no clear implementing skill — document the gap explicitly
    rather than inventing a mapping.

### 7. Interface elements
Context: new (standalone Markdown reference document).
Static elements: four strategy sections titled write, select, compress, isolate.
Dynamic elements: none — static documentation.

### 8. Domain model
Entities read: existing SKILL.md files (to ground the strategy-to-skill
mapping). Entities written: docs/references/context-engineering.md.

### 9. Integrations and boundaries
- e34s03 (CLAUDE.md vocabulary) and e34s04 (session-state SKILL.md) — direction:
  out — both cite this document as the canonical source.

### 10. Background processes
Not applicable — static documentation, no runtime behaviour.

### 11. Notifications
Not applicable — documentation change signalled only via git history.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Depth of skill mapping (content) — minimum is naming at least one
  implementing mechanism per strategy; exhaustive catalog mapping is optional.

### 14. Quality attributes *NFR*
- The four strategy names must appear in write/select/compress/isolate order
  so the epic verify grep ('write.*select.*compress.*isolate') passes.
- Document must be self-contained: readable without opening any SKILL.md.

### 15. Security and compliance *NFR*
Not applicable — public documentation, no secrets, no runtime surface.

### 16. UX and accessibility *NFR*
- Plain Markdown, heading hierarchy suitable for anchors/linking from other docs.

### 17. Acceptance criteria
Scenario: Reference document exists with the four strategies (happy path)
  Given the repository checkout at the project root
  When  the story is complete
  Then  docs/references/context-engineering.md exists
  And   `grep -q 'write.*select.*compress.*isolate' docs/references/context-engineering.md` exits 0

Scenario: Each strategy maps to existing bigpowers mechanisms
  Given docs/references/context-engineering.md exists
  When  a reader opens any of the four strategy sections
  Then  the section names at least one existing bigpowers skill or mechanism
        that implements the strategy

Scenario: Framework origin credited
  Given docs/references/context-engineering.md exists
  When  a reader checks the references section of the document
  Then  the GSD Core origin of the write/select/compress/isolate framing is credited

### 18. Out of scope
- Editing any SKILL.md or CLAUDE.md (e34s03 and e34s04 handle those).
- Adding effort frontmatter (e34s02).
- Regenerating sync artifacts — no SKILL.md changes in this story.

### 19. Open questions
Not applicable — scope is fully determined by the epic verify command.

### 20. References
- specs/epics/e34-context-engineering/epic.yaml (story definition and verify).
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md §4 Epic 4 (epic source).
- GSD Core — origin of the write/select/compress/isolate insight.
