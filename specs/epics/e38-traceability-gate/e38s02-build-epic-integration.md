STORY KEY: E38-S02
TITLE:     Integrate trace-stories.sh into build-epic Step 8 (verify phase)
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      XS

### 1. Business narrative
trace-stories.sh (e38s01) only delivers value if it runs at the right moments. The
build-epic skill's Step 8 is the verify phase every epic passes through, but today
it has no traceability check — an epic can complete with dark stories and nobody
notices until a later audit. Wiring the matrix builder into Step 8 makes trace
generation automatic on every epic completion.

### 2. Value statement
As a maintainer running build-epic, I want the trace matrix regenerated automatically
in Step 8, so that every epic completion produces fresh, auditable coverage evidence
before verify-work runs.

### 3. Actors and permissions
- build-epic skill (agent) — executes the script during Step 8.
- Maintainer (internal) — reviews the regenerated matrix during the verify phase.

### 4. Trigger and preconditions
Trigger: build-epic reaches Step 8 (verify phase) for the active epic.
Preconditions: scripts/trace-stories.sh exists (e38s01 done); active epic capsule
present in specs/epics/.

### 5. Main flow and business logic
1. Edit skills/build-epic/SKILL.md Step 8 to invoke
   `bash scripts/trace-stories.sh` before the verify-work handoff.
2. The step regenerates specs/traceability-matrix.json,
   specs/TRACEABILITY_LATEST.md, and the specs/codebase-wiki/ OKF bundle.
3. Step 8 instructions direct the agent to surface dark/orphan/stale findings for
   the just-built epic in its verify summary.
4. Run sync-skills.sh to regenerate Cursor/Gemini artifacts from the edited SKILL.md.
Interruption point: N/A (documentation edit; script runs to completion).

### 6. Alternative flows and exceptions
6a. trace-stories.sh missing or non-executable — Step 8 instructions say to report
    the failure and continue to verify-work with an explicit "trace skipped" note
    (traceability failure must be visible, not silent).
6b. Script exits non-zero — findings are surfaced in the verify summary; Step 8
    does not hard-block (blocking is gate-trace's job, e38s06).

### 7. Interface elements
Context: existing (skills/build-epic/SKILL.md, Step 8 section).
Static elements: new instruction block naming the script and its outputs.
Dynamic elements: none — the skill text is static; outputs vary per run.

### 8. Domain model
Entities written: skills/build-epic/SKILL.md (source of truth), regenerated
.cursor/rules and .gemini artifacts via sync-skills.sh.

### 9. Integrations and boundaries
- scripts/trace-stories.sh (e38s01, direction: in) — the command being wired.
- verify-work skill (perennial, direction: out) — runs after Step 8 with a fresh matrix.
- sync-skills.sh (perennial, direction: out) — regenerates artifacts after the edit.

### 10. Background processes
Not applicable — synchronous step inside the build-epic flow.

### 11. Notifications
Not applicable — findings appear in the build-epic verify summary text.

### 12. Audit and logging
Not applicable — the regenerated matrix itself is the audit artifact.

### 13. Solution variabilities
Not applicable — single invocation point, no configuration.

### 14. Quality attributes *NFR*
- The added step must not lengthen build-epic materially (< 5 seconds, per e38s01 NFR).

### 15. Security and compliance *NFR*
- SKILL.md edit only; never edit generated .cursor/.gemini artifacts directly
  (CLAUDE.md Never rule); sync-skills.sh regenerates them.

### 16. UX and accessibility *NFR*
Not applicable — skill documentation change.

### 17. Acceptance criteria
Scenario: Step 8 invokes the matrix builder
  Given skills/build-epic/SKILL.md after this story
  When  the Step 8 section is inspected
  Then  it contains an instruction to run scripts/trace-stories.sh
  And   `grep -q 'trace-stories.sh' skills/build-epic/SKILL.md` exits 0

Scenario: Ordering before verify-work
  Given the Step 8 text
  When  read in order
  Then  the trace-stories.sh invocation appears before the verify-work handoff

Scenario: Missing script handled visibly (6a)
  Given scripts/trace-stories.sh is absent
  When  an agent follows Step 8
  Then  the instructions direct it to note "trace skipped" rather than fail silently

Scenario: Artifacts regenerated
  Given the SKILL.md edit is complete
  When  sync-skills.sh is run
  Then  the Cursor and Gemini artifacts for build-epic contain the new step

### 18. Out of scope
- Blocking epic completion on trace results (gate-trace, e38s06/e38s07).
- CI integration (e38s03).
- Any change to trace-stories.sh itself.

### 19. Open questions
Not applicable — single insertion point defined by the epic description.

### 20. References
- specs/epics/e38-traceability-gate/epic.yaml (source description).
- skills/build-epic/SKILL.md (Step 8, verify phase).
- e38s01-trace-matrix-builder.md (the script being integrated).
