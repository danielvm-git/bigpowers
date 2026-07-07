STORY KEY: E37-S02
TITLE:     Create specs/benchmarks/fixtures/minimal-api/ fixture repo (createUser + failing-ready test harness)
TYPE:      Story
PARENT:    e42
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The agent-driven golden stories (G-01 build cycle, G-02 bug cycle) need a
stable, tiny target repo to operate on. Running them against the live
bigpowers repo would be slow, non-deterministic, and destructive. Without a
pinned fixture, every golden run starts from a different state and pass@k
scoring is meaningless. The e42s01 spike confirmed the harness (gh-aw +
DeepSeek v4) works; this story gives that harness something deterministic
to chew on: a minimal Node.js API with one function (createUser) and one
test file, per the G-01 fixture definition in QUALITY-GUARANTEE-STRATEGY.md.

### 2. Value statement
As a maintainer, I want a minimal, self-contained fixture repo with a
working createUser function and a test harness that is green at rest but
ready to express failing tests, so that agent-driven golden stories run
against a deterministic baseline and regressions are attributable to the
skills, not the fixture.

### 3. Actors and permissions
- Maintainer (internal) — creates and pins the fixture, runs `npm test` locally.
- Golden-story agent (system) — reads and mutates a throwaway copy of the fixture during G-01/G-02 runs.
- CI runner (system) — executes `npm test` inside the fixture as a gate.

### 4. Trigger and preconditions
Trigger: manual (`cd specs/benchmarks/fixtures/minimal-api && npm test`) or
invoked by the golden suite runner before an agent run.
Precondition: Node.js available on the runner (already required by repo CI).

### 5. Main flow and business logic
1. Fixture lives at specs/benchmarks/fixtures/minimal-api/ with its own package.json.
2. src/ contains a createUser function (single module, no framework).
3. test/ contains one test file exercising createUser's happy path.
4. `npm test` runs the test file and exits 0 on the pristine fixture.
5. The harness is "failing-ready": a golden story can add a new test that
   fails red (e.g. a validation rule not yet implemented) without any
   scaffolding work — test runner, script wiring, and directory layout
   already accept new test files.
Interruption point: N/A (fixture is static content; `npm test` runs to completion).

### 6. Alternative flows and exceptions
6a. `npm test` fails on the pristine fixture — fixture is broken; golden
    runs must abort before dispatching the agent.
6b. Dependencies missing (node_modules absent) — `npm test` must either
    work with zero external deps (node:test) or fail with a clear install hint.
6c. Golden run mutates the fixture in place — out of band; runner is
    responsible for copying to a scratch dir (see §18).

### 7. Interface elements
Context: new (standalone fixture directory).
Static elements: package.json (name, test script), src/createUser module,
one test file, README noting the fixture's purpose.
Dynamic elements: test runner output (pass/fail counts), exit code.

### 8. Domain model
Entities: User (created by createUser: input fields → user object).
Artifacts: package.json, src/*.js, test/*.js — all inside
specs/benchmarks/fixtures/minimal-api/.

### 9. Integrations and boundaries
- run-golden-suite.sh --agent (e42s04, direction: in) — copies/uses this fixture for G-01/G-02 runs.
- Golden story YAMLs (e42s03, direction: in) — reference this fixture path in their prompts/graders.
- Node.js built-in test runner (perennial, direction: out) — executes the tests; no external framework.

### 10. Background processes
Not applicable — fixture is static; tests run synchronously on demand.

### 11. Notifications
Not applicable — exit code and test-runner stdout are the only signalling.

### 12. Audit and logging
Not applicable — deterministic fixture, no persistent audit trail needed.

### 13. Solution variabilities
- Test runner (design) — prefer zero-dependency node:test so `npm test`
  needs no install step; swapping runners later only touches package.json.
- Fixture location (config) — path specs/benchmarks/fixtures/minimal-api/
  is referenced by e42s03 YAMLs and e42s04 runner; changing it is a
  coordinated rename.

### 14. Quality attributes *NFR*
- `npm test` completes in < 5 seconds on the pristine fixture.
- Zero network access at test time (no registry fetch required to run).
- Deterministic: same fixture → same test result, every run.

### 15. Security and compliance *NFR*
- No secrets, no network calls, no real user data — createUser handles
  synthetic input only.
- Fixture must not declare dependencies with install scripts.

### 16. UX and accessibility *NFR*
Not applicable — developer/CI fixture, no end-user interface.

### 17. Acceptance criteria
Scenario: Pristine fixture is green (happy path)
  Given the fixture at specs/benchmarks/fixtures/minimal-api/
  When  `npm test` is run from that directory
  Then  it exits 0
  And   at least one test for createUser passes

Scenario: createUser behaves as specified
  Given the pristine fixture
  When  createUser is called with valid input in the test file
  Then  it returns a user object echoing the input fields

Scenario: Failing-ready harness accepts a new red test (G-01 readiness)
  Given the pristine fixture
  When  a new test file asserting an unimplemented validation rule is added to test/
  And   `npm test` is run
  Then  the runner discovers and executes the new file
  And   `npm test` exits non-zero (red), with the failure attributed to the new test

Scenario: Broken fixture blocks golden runs (6a)
  Given the fixture's existing test is made to fail
  When  `npm test` is run
  Then  it exits non-zero
  And   the golden suite runner treats the fixture as unusable

### 18. Out of scope
- Copy-to-scratch / reset mechanics between golden runs (e42s04 runner concern).
- The G-02 bug fixture (off-by-one repo) — separate fixture, planned when G-02 wiring lands.
- Any Express/HTTP server — "minimal API" means one exported function, not a running service.
- Golden story YAML definitions (e42s03).

### 19. Open questions
Not applicable — fixture shape is fixed by the G-01 definition in
QUALITY-GUARANTEE-STRATEGY.md and the epic verify command.

### 20. References
- specs/QUALITY-GUARANTEE-STRATEGY.md (§7, Story G-01 fixture definition).
- specs/epics/e42-golden-stories/epic.yaml (e42s02 verify command).
- specs/PLAN-AUDIT_LATEST.md (2026-07-02 e31/e42 split rationale).
