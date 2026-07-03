STORY KEY: E34-S02
TITLE:     Add optional effort: heavy|light frontmatter to all 72 skills
TYPE:      Story
PARENT:    e34
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
Every skill's SKILL.md carries YAML frontmatter (name, model, description),
but nothing signals how much context a skill consumes when invoked. GSD Core's
central insight is that declaring effort up front lets an orchestrator budget
context before dispatch. Adding an optional `effort: heavy|light` key gives
agents and orchestration skills (build-epic, orchestrate-project,
dispatch-agents) a machine-readable signal to decide whether a skill should
run inline (light) or be isolated in a subagent (heavy).

### 2. Value statement
As an AI agent orchestrating bigpowers skills, I want each SKILL.md to declare
an effort level in its frontmatter, so that I can budget context and choose
inline execution versus subagent isolation before invoking the skill.

### 3. Actors and permissions
- Maintainer (internal) — classifies each skill and edits the frontmatter.
- AI agents (system) — read the effort key when planning skill invocation.
- sync-skills.sh (system) — must continue to parse frontmatter and regenerate
  artifacts after the change.

### 4. Trigger and preconditions
Trigger: manual — story picked up from the e34 epic capsule.
Preconditions: e34s01's reference document defines the vocabulary the
classification leans on; the full skill catalog exists under skills/*/SKILL.md.

### 5. Main flow and business logic
1. Define the classification rule: `effort: heavy` for skills that read or
   write large context (multi-file planning, orchestration, codebase scans);
   `effort: light` for narrow single-artifact skills.
2. For each skill directory under skills/, add one `effort: heavy` or
   `effort: light` line inside the existing YAML frontmatter block of SKILL.md.
3. The key is optional by contract — consumers must tolerate its absence —
   but this story populates it across the catalog (all 72 skills).
4. Run `bash scripts/sync-skills.sh` to regenerate .cursor/.gemini/.pi
   artifacts from the edited sources.
Interruption point: after any subset of skills is annotated the repo remains
valid (the key is optional), so work can land incrementally.

### 6. Alternative flows and exceptions
6a. A skill's effort is ambiguous — default to `effort: heavy` (safe
    over-budgeting) and note it for review.
6b. sync-skills.sh rejects an edited frontmatter block — fix the YAML in
    SKILL.md before proceeding; never patch generated artifacts.
6c. A frontmatter block uses non-standard delimiters — align it to the
    standard `---` fenced block before inserting the key.

### 7. Interface elements
Context: existing (YAML frontmatter of every skills/*/SKILL.md).
Static elements: `effort` key with the closed value set heavy | light.
Dynamic elements: none — declarative metadata.

### 8. Domain model
Entities written: skills/*/SKILL.md frontmatter (new optional `effort` key).
Entities regenerated: .cursor/rules, .gemini/extensions/bigpowers, .pi
artifacts via sync-skills.sh.

### 9. Integrations and boundaries
- scripts/sync-skills.sh (perennial, direction: in/out) — parses the edited
  frontmatter and regenerates all artifacts.
- e34s01 reference document (direction: in) — supplies the vocabulary that
  motivates the heavy/light split.

### 10. Background processes
Not applicable — static metadata; no runtime process.

### 11. Notifications
Not applicable — git history and regenerated artifacts are the only signals.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Value set (config) — fixed to heavy | light for this story; finer grades
  (e.g. medium) are a future extension.
- Optionality (contract) — the key is optional; tooling must not fail on
  skills that omit it.

### 14. Quality attributes *NFR*
- Frontmatter must remain valid YAML in every edited SKILL.md.
- sync-skills.sh must exit 0 after the change (it is the lint gate).
- The epic verify threshold is at least 10 annotated skills; the story goal
  is full catalog coverage.

### 15. Security and compliance *NFR*
Not applicable — metadata-only change, no secrets, no runtime surface.

### 16. UX and accessibility *NFR*
- Key placement is consistent (within the existing frontmatter block) so
  human readers find it in the same place in every skill.

### 17. Acceptance criteria
Scenario: Effort key present across the catalog (happy path)
  Given all skills/*/SKILL.md files have been annotated
  When  `grep -rl 'effort:' skills/*/SKILL.md | wc -l` is evaluated
  Then  the count is at least 10 (epic verify threshold)
  And   the story-level goal of all 72 skills annotated is met

Scenario: Only the closed value set is used
  Given the annotation pass is complete
  When  every `effort:` line in skills/*/SKILL.md is inspected
  Then  each value is exactly heavy or light

Scenario: Sync pipeline still passes (6b)
  Given all frontmatter edits are in place
  When  `bash scripts/sync-skills.sh` is executed
  Then  it exits 0
  And   regenerated artifacts reflect the edited sources

Scenario: Key remains optional for consumers
  Given a hypothetical skill without an effort key
  When  tooling that reads frontmatter processes it
  Then  processing succeeds without error (absence is tolerated)

### 18. Out of scope
- Making any consumer (orchestration skill, script) act on the effort value —
  this story only declares the metadata.
- Adding effort to generated artifacts by hand (sync-skills.sh owns those).
- Renaming or restructuring any skill.

### 19. Open questions
- The epic verify accepts >= 10 annotated skills while the title says all 72;
  treat 72 as the goal and 10 as the machine-checkable floor.

### 20. References
- specs/epics/e34-context-engineering/epic.yaml (story definition and verify).
- docs/references/context-engineering.md (e34s01 — vocabulary source).
- scripts/sync-skills.sh (frontmatter lint and artifact regeneration).
- GSD Core — origin of the effort-declaration insight.
