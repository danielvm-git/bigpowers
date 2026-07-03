STORY KEY: E34-S03
TITLE:     Update CLAUDE.md Token Management to use context-engineering vocabulary
TYPE:      Story
PARENT:    e34
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
CLAUDE.md's Token Management section describes context discipline in ad-hoc
terms (Auto-Terse, Context Compaction, Minimal Output, Stream Stability)
without connecting them to the write/select/compress/isolate framework the
project actually implements. Once e34s01 lands the canonical reference, the
project's own agent instructions should speak the same vocabulary — otherwise
the framework exists on paper but the operating instructions ignore it.

### 2. Value statement
As an AI agent reading CLAUDE.md at session start, I want the Token Management
section phrased in the write/select/compress/isolate vocabulary and aware of
the effort frontmatter, so that my context discipline follows the same named
strategies the rest of the project uses.

### 3. Actors and permissions
- Maintainer (internal) — edits CLAUDE.md.
- AI agents (system) — consume the section on every session start.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e34 epic capsule.
Preconditions: docs/references/context-engineering.md exists (e34s01) so the
section can cite it; effort frontmatter convention defined by e34s02.

### 5. Main flow and business logic
1. Rewrite the Token Management section of CLAUDE.md so each existing rule is
   framed by its strategy: write (persist state), select (read only what is
   needed), compress (terse-mode/compaction), isolate (subagent dispatch).
2. Mention the `effort:` frontmatter key as the per-skill signal for
   choosing inline execution versus isolation.
3. Link to docs/references/context-engineering.md as the canonical definition.
4. Preserve the section's existing operational rules — this is a re-framing,
   not a policy change.
Interruption point: N/A — single-section edit.

### 6. Alternative flows and exceptions
6a. An existing Token Management rule fits no strategy — keep it verbatim and
    leave it outside the four-strategy framing rather than distorting it.
6b. e34s01 has not landed yet — the edit can still name the four strategies
    but the reference link is added once the document exists.

### 7. Interface elements
Context: existing (Token Management section of CLAUDE.md).
Static elements: the four strategy names; mention of the effort key; link to
the reference document.
Dynamic elements: none — static instructions.

### 8. Domain model
Entities written: CLAUDE.md (Token Management section only).
Entities referenced: docs/references/context-engineering.md.

### 9. Integrations and boundaries
- e34s01 reference document (direction: in) — canonical definitions cited.
- e34s02 effort frontmatter (direction: in) — the key the section points at.

### 10. Background processes
Not applicable — static documentation, no runtime behaviour.

### 11. Notifications
Not applicable — git history is the only signal.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Depth of rewrite (content) — minimum is naming the four strategies and the
  effort key; a full restructure of the section is optional.

### 14. Quality attributes *NFR*
- The section must satisfy the epic verify grep, i.e. contain the literal
  pattern matched by `grep -q 'write.*select.*compress.*isolate|effort:' CLAUDE.md`.
- No other CLAUDE.md section may be modified (blast radius = one section).

### 15. Security and compliance *NFR*
Not applicable — documentation-only change.

### 16. UX and accessibility *NFR*
- Section stays scannable: strategy names bolded or listed so an agent can
  parse the four strategies at a glance.

### 17. Acceptance criteria
Scenario: Token Management speaks the framework vocabulary (happy path)
  Given CLAUDE.md has been edited
  When  the Token Management section is read
  Then  it names the write, select, compress, and isolate strategies
  And   the epic verify command `grep -q 'write.*select.*compress.*isolate|effort:' CLAUDE.md && echo OK` prints OK

Scenario: Effort frontmatter referenced
  Given CLAUDE.md has been edited
  When  the Token Management section is read
  Then  it mentions the per-skill `effort:` frontmatter key as an isolation signal

Scenario: Existing rules preserved (6a)
  Given the pre-edit Token Management rules (terse-mode trigger, compaction
        cadence, minimal output, stream stability)
  When  the section is re-read after the edit
  Then  each pre-existing operational rule is still present in substance

Scenario: Blast radius limited to one section
  Given the edit is complete
  When  CLAUDE.md is diffed against its previous version
  Then  only the Token Management section differs

### 18. Out of scope
- Editing any other CLAUDE.md section (Commands, Architecture, Never, etc.).
- Editing SKILL.md files (e34s04 handles session-state).
- Changing token-management policy — wording and framing only.

### 19. Open questions
- The epic verify grep treats '|' literally in basic grep; the edited text
  must satisfy the command as written, since story verify commands must not
  be changed.

### 20. References
- specs/epics/e34-context-engineering/epic.yaml (story definition and verify).
- CLAUDE.md Token Management section (edit target).
- docs/references/context-engineering.md (e34s01 — canonical definitions).
