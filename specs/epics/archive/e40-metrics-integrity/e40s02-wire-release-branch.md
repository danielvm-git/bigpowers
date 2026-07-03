STORY KEY: E40-S02
TITLE:     Wire record-cycle-time.sh append into release-branch; deprecate story_start/story_end hand-arithmetic in survey-context + release-branch
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The current cycle-time metric is agent-self-reported via survey-context
(story_start) and release-branch (story_end + hand-arithmetic). This is the
root cause of the unreliable data in cycle-times.yaml — agents fabricating
timestamps, mis-subtracting, or copy-pasting. record-cycle-time.sh (e40s01)
derives honest, additive effort from git commit history. Wiring it into
release-branch replaces the agent from the measurement loop: the script reads
git, the agent just invokes it. survey-context's story_start remains but is
demoted to informational only — a human-facing progress marker, not a
measurement input.

### 2. Value statement
As a maintainer, I want cycle-time metrics derived from git history, not agent
self-reporting, so I can trust the velocity ledger without auditing every row.

### 3. Actors and permissions
- release-branch skill (system) — invokes record-cycle-time.sh at merge.
- survey-context skill (system) — marks story_start as informational.

### 4. Trigger and preconditions
Trigger: release-branch execution at merge.
Precondition: record-cycle-time.sh exists with append subcommand (e40s01 complete).

### 5. Main flow and business logic
1. release-branch executes pre-merge steps.
2. Invoke: bash scripts/record-cycle-time.sh append <story_id> <commit_range>.
3. Script derives effort and lead_time from git; appends OKF bundle to specs/metrics/.
4. Update release-branch REFERENCE.md: remove hand-arithmetic cycle_minutes formula.
5. Update survey-context SKILL.md: mark story_start as "informational progress marker only."

### 6. Alternative flows and exceptions
6a. record-cycle-time.sh not found — skip, warn, do not block merge.
6b. commit_range unresolvable — script reports error, merge proceeds without metrics.
6c. Additivity self-check fails — script exits non-zero, metrics skipped, merge proceeds.

### 7-16. Not applicable (standard integration pattern)

### 17. Acceptance criteria
Scenario: Metrics recorded at merge
  GIVEN release-branch is executing
  WHEN record-cycle-time.sh append is called
  THEN a per-story OKF metrics bundle is emitted
  AND the bundle source is "measured" (not "estimated" or "backfilled")
  AND grep -q 'record-cycle-time' skills/release-branch/SKILL.md exits 0
  AND release-branch REFERENCE.md no longer contains hand-arithmetic

### 18. Out of scope
- Removing story_start from survey-context entirely (it remains as informational).
- Backfilling historical metrics (quarantine is e40s07).

### 19. Open questions
- What happens if the agent manually tampers with record-cycle-time.sh output?
  validate-okf.sh (e40s06) gates on generator provenance and commit_range
  resolution — tampered output would fail provenance checks.

### 20. References
- scripts/record-cycle-time.sh (e40s01).
- skills/release-branch/SKILL.md, REFERENCE.md (target skill).
- skills/survey-context/SKILL.md (story_start demotion).
- specs/RESEARCH-cycle-time-metrics.md (primary-source investigation).
