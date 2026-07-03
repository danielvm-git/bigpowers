STORY KEY: E38-S03
TITLE:     Add trace-stories.sh --strict to CI gate (sync-skills.yml)
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
trace-stories.sh (e38s01) produces a deterministic coverage matrix, but without
CI enforcement, untagged stories can land silently. Adding `--strict` mode to the
sync-skills CI workflow ensures every push is gated: if P0-priority stories have
zero code coverage tags, CI fails. The traceability matrix is also uploaded as an
artifact, making the coverage state inspectable without running the script locally.

### 2. Value statement
As a maintainer, I want CI to block merges that introduce untagged stories, so
traceability is enforced automatically rather than remembered manually.

### 3. Actors and permissions
- CI runner (system) — executes trace-stories.sh in GitHub Actions.
- Release engineer (internal) — configures the workflow.

### 4. Trigger and preconditions
Trigger: push to main or PR (sync-skills.yml workflow).
Precondition: scripts/trace-stories.sh exists (e38s01 complete).

### 5. Main flow and business logic
1. sync-skills.yml workflow runs on push.
2. Execute: bash scripts/trace-stories.sh --strict --json.
3. If any P0 story has 0% code coverage → exit non-zero, CI fails.
4. Upload specs/traceability-matrix.json as a build artifact.
5. Upload specs/TRACEABILITY_LATEST.md as a human-readable artifact.

### 6. Alternative flows and exceptions
6a. trace-stories.sh not found — CI fails with clear error.
6b. No P0 stories in scope — --strict mode passes (no violations to flag).
6c. Artifact upload fails — warn but don't fail the build.

### 7-16. Not applicable (standard CI wiring pattern)

### 17. Acceptance criteria
Scenario: CI blocks untagged P0 story (happy path)
  GIVEN a push that introduces a P0 story with no code tags
  WHEN sync-skills CI runs trace-stories.sh --strict
  THEN CI fails
  AND the traceability matrix shows the untagged story

Scenario: All P0 stories tagged
  GIVEN all P0 stories have code coverage tags
  WHEN CI runs
  THEN trace-stories.sh --strict passes
  AND the matrix artifact is uploaded

### 18. Out of scope
- Adding traceability checks to other CI workflows (docs-site, publish).
- Auto-commenting on PRs with traceability gaps.

### 19. Open questions
- What determines P0 priority? Deferred to e38s01 story tag heuristics.
- Should --strict be the default or opt-in? Default in CI, opt-in locally.

### 20. References
- scripts/trace-stories.sh (e38s01).
- .github/workflows/sync-skills.yml (target workflow).
- specs/epics/e38-traceability-gate/epic.yaml (parent epic).
