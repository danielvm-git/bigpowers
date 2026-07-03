STORY KEY: E31-S02
TITLE:     Wire npm run compliance into CI as pre-release gate
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      S

### 1. Business narrative
semantic-release publishes to npm on every push to main. Currently no compliance
check runs before publication — a broken dependency, missing lockfile, or invalid
skill structure can ship unnoticed. The `npm run compliance` command already
exists locally but is not wired into CI. A pre-release gate prevents bad publishes.

### 2. Value statement
As a maintainer, I want `npm run compliance` to run before semantic-release in CI,
so that a failing compliance check blocks publication.

### 3. Actors and permissions
- CI runner (system) — executes compliance check in publish workflow.
- semantic-release (system) — publishes only if compliance passes.

### 4. Trigger and preconditions
Trigger: push to main branch triggers publish.yml.
Precondition: `npm run compliance` script is defined in package.json.

### 5. Main flow and business logic
1. CI checks out repository.
2. CI installs dependencies (`npm ci`).
3. CI runs `npm run compliance`.
4. If compliance exits 0, CI proceeds to semantic-release.
5. If compliance exits non-zero, CI fails the job before release.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. compliance script missing — CI fails with "script not found" before release.

### 7. Interface elements
Context: existing (publish.yml, release job).
Static elements: new step in release job before semantic-release.
Dynamic elements: compliance output on failure.

### 8. Domain model
Not applicable — CI configuration change only; no domain entities affected.

### 9. Integrations and boundaries
- npm scripts (perennial, direction: in) — `npm run compliance` is the gate.
- semantic-release (perennial, direction: out) — gated by compliance.

### 10. Background processes
Not applicable — synchronous CI step.

### 11. Notifications
- CI job failure (GitHub Actions) — maintainer notified on compliance failure.

### 12. Audit and logging
Not applicable — CI run log is the audit trail.

### 13. Solution variabilities
Not applicable — hardcoded step; no configuration variants.

### 14. Quality attributes *NFR*
- Gate wall-clock: < 5 seconds (compliance is a lint/validate pass, no network).
- Must not add > 10% to publish workflow duration.

### 15. Security and compliance *NFR*
- Runs with existing `contents: read` permissions — no escalation needed.
- Compliance script is trusted (same repo); no supply-chain risk.

### 16. UX and accessibility *NFR*
Not applicable — CI-only change.

### 17. Acceptance criteria
Scenario: Compliance passes (happy path)
  Given a push to main with all skills valid
  When  publish.yml runs the release job
  Then  `npm run compliance` exits 0
  And   semantic-release proceeds

Scenario: Compliance fails (6a)
  Given a push to main with a broken skill
  When  publish.yml runs the release job
  Then  `npm run compliance` exits non-zero
  And   the release job fails before semantic-release

### 18. Out of scope
- Adding new compliance checks (existing command only).
- Wiring compliance into sync-skills.yml (separate workflow).

### 19. Open questions
Not applicable.

### 20. References
- .github/workflows/publish.yml (release job).
- package.json (compliance script).
- e31s01 (G-04 self-test — compliance is one of the gates G-01 runs).
