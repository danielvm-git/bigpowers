STORY KEY: E37-S03
TITLE:     Author 4 golden story YAMLs (g-01, g-02, g-03, g-05) with code graders and pass@k 2-of-3 flake policy
TYPE:      Story
PARENT:    e42
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The e42s01 spike proved an agent (DeepSeek v4 via the gh-aw Claude engine)
can execute a golden story headlessly — G-01 is live as
.github/workflows/e42-golden-deepseek.lock.yml. But the stories themselves
exist only as prose in QUALITY-GUARANTEE-STRATEGY.md §7. Without
machine-readable definitions, the --agent runner (e42s04) has nothing to
iterate over, results cannot be graded by code, and flake tolerance is
undefined. G-04 is deliberately excluded: it is deterministic and already
shipped in e31 (scripts/golden-g04-selftest.sh, wired into
run-golden-suite.sh). The remaining four agent-driven chains — G-01 (build),
G-02 (bug), G-03 (plan), G-05 (discovery) — need YAML definitions with code
graders and an explicit pass@k 2-of-3 flake policy.

### 2. Value statement
As a maintainer, I want each agent-driven golden story defined as a YAML
file with a code grader and a pass@k 2-of-3 policy, so that the golden
suite runner can execute, grade, and flake-tolerate agent runs without
human judgement in the loop.

### 3. Actors and permissions
- Maintainer (internal) — authors and reviews the YAMLs.
- Golden suite runner (system, e42s04) — parses the YAMLs and executes stories per-epic.
- Code grader (system) — bash commands from the YAML; exit 0 = PASS, non-zero = FAIL.

### 4. Trigger and preconditions
Trigger: manual authoring now; consumed on each per-epic golden run later.
Preconditions: specs/benchmarks/SCHEMA.md schema exists (shipped);
minimal-api fixture exists for g-01 (e42s02); e31 deterministic gates
shipped in v2.50.0.

### 5. Main flow and business logic
1. Create specs/benchmarks/golden/ directory.
2. Author g-01.yaml — chain survey-context → plan-work → kickoff-branch →
   develop-tdd → verify-work → audit-code against the minimal-api fixture;
   code grader asserts expected artifacts (task file, implementation, test,
   state.yaml handoff).
3. Author g-02.yaml — chain investigate-bug → diagnose-root → develop-tdd →
   validate-fix → release-branch; code grader asserts BUG-*.md exists with
   4 RCA phases.
4. Author g-03.yaml — chain scope-work → slice-tasks → plan-work →
   plan-release from a 3-feature SCOPE_LATEST.yaml fixture; code grader
   asserts release-plan.yaml has epics with BCP values.
5. Author g-05.yaml — chain search-skills → survey-context →
   using-bigpowers from a mid-build state.yaml fixture; code grader asserts
   the agent identifies the correct next_skill.
6. Every YAML carries a pass_at_k block declaring the 2-of-3 policy:
   3 attempts maximum, story PASSES if at least 2 attempts pass.
Interruption point: N/A (authoring task; files are static definitions).

### 6. Alternative flows and exceptions
6a. Grader command references a missing fixture — grader must exit non-zero
    with a clear message, not false-PASS.
6b. YAML unparseable — runner (e42s04) must fail loudly; authoring gate here
    is a yaml.safe_load check per file.
6c. Story flakes 1 of 3 — pass@k 2-of-3 absorbs it; result recorded as PASS
    with flake count.
6d. Story fails 2+ of 3 — recorded as FAIL; regression vs baseline.

### 7. Interface elements
Context: new (four YAML files + one directory).
Static elements: story id, name, chain, prompt, grader.type: code,
grader.command, pass_at_k {k: 3, threshold: 2}.
Dynamic elements: none at authoring time — runtime results live in
specs/benchmarks/reports/ (e42s04).

### 8. Domain model
Entities: GoldenStory (id, chain, prompt, grader, pass_at_k), Grader
(type: code, command), FlakePolicy (k, threshold). Follows the
specs/benchmarks/SCHEMA.md scenario schema, extended with the pass_at_k
block and golden-story ids.

### 9. Integrations and boundaries
- specs/benchmarks/SCHEMA.md (perennial, direction: in) — base schema the golden YAMLs extend.
- specs/benchmarks/fixtures/minimal-api/ (e42s02, direction: in) — g-01 fixture target.
- scripts/run-golden-suite.sh --agent (e42s04, direction: out) — consumes these YAMLs.
- .github/workflows/e42-golden-deepseek.lock.yml (spike, direction: out) — G-01 workflow; the g-01.yaml definition becomes its source of truth.

### 10. Background processes
Not applicable — static definitions; execution scheduling is e42s04's concern.

### 11. Notifications
Not applicable — no runtime behaviour in this story.

### 12. Audit and logging
Not applicable — the YAMLs are version-controlled; run reports are e42s04 scope.

### 13. Solution variabilities
- pass@k parameters (config) — k: 3, threshold: 2 declared per story so a
  future policy change is a per-file edit, not a runner change.
- Grader commands (design) — plain bash so they run identically locally and
  in gh-aw workflows.

### 14. Quality attributes *NFR*
- Each YAML parses with yaml.safe_load (no anchors/tags trickery).
- Grader commands are deterministic given the fixture state and are
  side-effect-free reads (assert-only).

### 15. Security and compliance *NFR*
- No secrets in YAMLs; model endpoint config (ANTHROPIC_BASE_URL) stays in
  workflow/runner config, never in story definitions.
- Grader commands run read-only assertions; no network access.

### 16. UX and accessibility *NFR*
Not applicable — machine-consumed YAML definitions.

### 17. Acceptance criteria
Scenario: Four golden YAMLs exist (happy path)
  Given the specs/benchmarks/golden/ directory
  When  the files are listed
  Then  exactly 4 files match g-*.yaml
  And   their ids are g-01, g-02, g-03, g-05

Scenario: Every story declares the flake policy
  Given any file in specs/benchmarks/golden/
  When  it is parsed
  Then  it contains a pass_at_k block with k 3 and threshold 2

Scenario: Every story has a code grader
  Given any file in specs/benchmarks/golden/
  When  it is parsed
  Then  grader.type is code
  And   grader.command is a non-empty bash command

Scenario: g-01 targets the minimal-api fixture
  Given g-01.yaml
  When  its prompt and grader are inspected
  Then  they reference specs/benchmarks/fixtures/minimal-api/
  And   the grader asserts the G-01 artifacts (task file, implementation, test, state.yaml handoff)

Scenario: All YAMLs are parseable (6b)
  Given the 4 golden YAMLs
  When  each is loaded with yaml.safe_load
  Then  no file raises a parse error

### 18. Out of scope
- G-04 definition — deterministic, already shipped in e31 (scripts/golden-g04-selftest.sh).
- Executing the stories or computing pass@k at runtime (e42s04).
- The G-02 off-by-one bug fixture and G-03/G-05 fixture repos — graders must
  fail loudly if fixtures are absent (6a); fixture creation beyond
  minimal-api is deferred to e42s04 wiring.
- Cost/flake baselining (needs 3 weekly runs per spike verdict).

### 19. Open questions
Not applicable — story set, chains, and flake policy are fixed by
QUALITY-GUARANTEE-STRATEGY.md §7 and the epic note.

### 20. References
- specs/QUALITY-GUARANTEE-STRATEGY.md (§7, stories G-01/G-02/G-03/G-05 and "Why these 5").
- specs/benchmarks/SCHEMA.md (base benchmark YAML schema).
- specs/epics/e42-golden-stories/epic.yaml (e42s03 verify command, flake policy note).
- .github/workflows/e42-golden-deepseek.lock.yml (spike output for G-01).
