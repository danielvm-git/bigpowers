STORY KEY: E31-S07
TITLE:     Wire golden suite into evolve-skill regression checks
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      XS

### 1. Business narrative
evolve-skill currently uses run-benchmark for capability evaluations (measuring
whether a skill improved). It lacks a fast regression check — if a skill edit
breaks the sync pipeline or compliance, evolve-skill won't catch it until CI
runs. Wiring run-golden-suite.sh as a pre-benchmark regression gate catches
mechanical breakage before spending time on capability evals.

### 2. Value statement
As a skill author, I want evolve-skill to run the golden suite before benchmarking,
so that mechanical regressions are caught before measuring capability changes.

### 3. Actors and permissions
- Skill author (internal) — runs evolve-skill.
- evolve-skill (system) — invokes golden suite as a gate.

### 4. Trigger and preconditions
Trigger: evolve-skill is invoked (benchmark-gated evolution flow).
Precondition: scripts/run-golden-suite.sh exists (e31s03).

### 5. Main flow and business logic
1. evolve-skill's SKILL.md references run-golden-suite.sh as a pre-benchmark step.
2. Before running benchmarks, the agent executes run-golden-suite.sh.
3. If golden suite fails, evolve-skill aborts before benchmark.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Golden suite not yet implemented — reference as "when available" with a note.

### 7. Interface elements
Context: existing (skills/evolve-skill/SKILL.md).
Static elements: new process step referencing run-golden-suite.sh.

### 8. Domain model
Not applicable — documentation change only.

### 9. Integrations and boundaries
- run-golden-suite.sh (perennial, direction: in) — invoked by evolve-skill.
- run-benchmark (perennial, direction: out) — gated by golden suite.

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
Not applicable.

### 13. Solution variabilities
Not applicable.

### 14. Quality attributes *NFR*
Not applicable — documentation only.

### 15. Security and compliance *NFR*
Not applicable.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: evolve-skill references golden suite
  Given scripts/run-golden-suite.sh exists
  When  skills/evolve-skill/SKILL.md is read
  Then  it references run-golden-suite.sh for regression checks
  And   it preserves the run-benchmark step for capability evals

### 18. Out of scope
- Changing evolve-skill's benchmark flow.
- Adding golden suite to other skills.

### 19. Open questions
Not applicable.

### 20. References
- skills/evolve-skill/SKILL.md.
- e31s03 (run-golden-suite.sh).
- skills/run-benchmark/SKILL.md (capability evals).
