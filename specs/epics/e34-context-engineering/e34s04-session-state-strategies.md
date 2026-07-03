STORY KEY: E34-S04
TITLE:     Update session-state SKILL.md to name the four context-engineering strategies
TYPE:      Story
PARENT:    e34
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The session-state skill is bigpowers' flagship implementation of the "write"
strategy — it persists decisions to specs/state.yaml to prevent context rot —
yet its SKILL.md never says so. Naming the four strategies (write, select,
compress, isolate) inside the skill anchors the framework where agents
actually encounter it: session-state is invoked at the start of nearly every
session, making it the highest-leverage place to teach the vocabulary.

### 2. Value statement
As an AI agent invoking session-state, I want its SKILL.md to name the four
context-engineering strategies and position the skill within them, so that I
understand session-state as the "write" strategy and know where the other
three are implemented.

### 3. Actors and permissions
- Maintainer (internal) — edits skills/session-state/SKILL.md.
- AI agents (system) — read the skill at session start.
- sync-skills.sh (system) — regenerates .cursor/.gemini/.pi artifacts from
  the edited source.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e34 epic capsule.
Preconditions: docs/references/context-engineering.md exists (e34s01) so the
skill can cite it rather than redefine the framework.

### 5. Main flow and business logic
1. Edit skills/session-state/SKILL.md (the source of truth — never the
   generated artifacts) to name the four strategies: write, select, compress,
   isolate.
2. Position session-state explicitly as the "write" strategy (persisting
   state to specs/state.yaml).
3. Point to the sibling strategies' homes (select → survey-context,
   compress → terse-mode, isolate → dispatch-agents/delegate-task) and link
   docs/references/context-engineering.md for definitions.
4. Run `bash scripts/sync-skills.sh` to regenerate artifacts.
Interruption point: N/A — single-skill edit plus regeneration.

### 6. Alternative flows and exceptions
6a. The addition bloats the skill body — keep it to a short subsection; the
    reference document carries the full definitions.
6b. sync-skills.sh fails on the edited file — fix SKILL.md syntax before
    proceeding; never hand-edit generated artifacts.

### 7. Interface elements
Context: existing (body of skills/session-state/SKILL.md).
Static elements: the four strategy names; link to the reference document.
Dynamic elements: none — static skill documentation.

### 8. Domain model
Entities written: skills/session-state/SKILL.md.
Entities regenerated: .cursor/rules, .gemini/extensions/bigpowers, .pi
artifacts for session-state via sync-skills.sh.

### 9. Integrations and boundaries
- scripts/sync-skills.sh (perennial, direction: in/out) — regenerates the
  artifacts after the source edit.
- e34s01 reference document (direction: in) — canonical definitions cited
  instead of duplicated.

### 10. Background processes
Not applicable — static skill documentation, no runtime process.

### 11. Notifications
Not applicable — git history and regenerated artifacts are the only signals.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Placement (content) — the strategy naming may live in the skill intro or a
  dedicated subsection; either satisfies the story.

### 14. Quality attributes *NFR*
- SKILL.md frontmatter and structure must remain valid so sync-skills.sh
  exits 0.
- The skill's HARD GATE and existing workflow content must be preserved
  unchanged — this story adds framing, not behaviour.

### 15. Security and compliance *NFR*
Not applicable — documentation-only change to a skill body.

### 16. UX and accessibility *NFR*
- Strategy naming is concise (one short subsection) so the skill stays
  fast to read at session start.

### 17. Acceptance criteria
Scenario: session-state names the four strategies (happy path)
  Given skills/session-state/SKILL.md has been edited
  When  the skill body is read
  Then  it names write, select, compress, and isolate
  And   the epic verify command `grep -q 'write|select|compress|isolate' skills/session-state/SKILL.md && echo OK` prints OK

Scenario: session-state positioned as the write strategy
  Given the edited skill body
  When  an agent reads the strategy subsection
  Then  session-state is identified as the implementation of the write strategy
  And   the homes of the other three strategies are pointed at

Scenario: Reference document cited, not duplicated (6a)
  Given the edited skill body
  When  the strategy subsection is read
  Then  it links docs/references/context-engineering.md for full definitions
  And   it does not restate the full framework definitions

Scenario: Artifacts regenerated cleanly (6b)
  Given the SKILL.md edit is complete
  When  `bash scripts/sync-skills.sh` is executed
  Then  it exits 0
  And   the generated session-state artifacts contain the new strategy naming

### 18. Out of scope
- Editing any other skill's SKILL.md.
- Changing session-state behaviour, frontmatter contract, or HARD GATE.
- Hand-editing .cursor/rules, .gemini/extensions/, or .pi artifacts.

### 19. Open questions
- The epic verify grep treats '|' literally in basic grep; the edited text
  must satisfy the command as written, since story verify commands must not
  be changed.

### 20. References
- specs/epics/e34-context-engineering/epic.yaml (story definition and verify).
- skills/session-state/SKILL.md (edit target, source of truth).
- docs/references/context-engineering.md (e34s01 — canonical definitions).
- scripts/sync-skills.sh (artifact regeneration).
