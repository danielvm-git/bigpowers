STORY KEY: E42-S02
TITLE:     Build one feature epic end-to-end via the 8-step build-epic cycle
TYPE:      Story
PARENT:    e42
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
A scaffolded cockpit alone proves nothing — the persuasive artifact is a
COMPLETE build trail a prospect can read commit by commit: story spec, tasks
with verify commands, TDD commits, verify-work UAT record, audit-code score,
Conventional Commit landing. This story runs one feature epic of the showcase
app through the full 8-step build-epic cycle. Because e42 is slotted v2.8x,
cycle-time metrics MUST be recorded via scripts/record-cycle-time.sh (the e40
honest-metrics pipeline) — never hand-arithmetic — so the trail demonstrates
the current methodology, not the deprecated one. The resulting trail doubles
as fixture material for e37 golden stories.

### 2. Value statement
As a prospective adopter, I want to read one feature epic's complete build
trail in the showcase repo, so that I can see exactly what the 8-step
methodology produces before adopting it.

### 3. Actors and permissions
- Maintainer (dvm) — runs build-epic in the showcase repo, commits and pushes.
- Prospective adopter (external, read-only) — reads the trail on GitHub.

### 4. Trigger and preconditions
Trigger: manual — follows e42s01 completion.
Preconditions: showcase repo scaffolded with committed cockpit (e42s01); the
showcase repo's release plan defines at least one feature epic;
record-cycle-time.sh pattern (e40) available to replicate in the showcase repo.

### 5. Main flow and business logic
1. Pick the showcase repo's first feature epic from its release-plan.yaml.
2. Run the full 8-step build-epic cycle on it: story spec + tasks.yaml with
   verify commands, develop-tdd red-green-refactor commits, verify-work UAT
   record, audit-code score, Conventional Commit landing.
3. Record cycle-time metrics via the record-cycle-time.sh pipeline (e40) —
   never hand-arithmetic.
4. Confirm the complete trail is committed and visible in the repo history.
Interruption point: between build-epic steps — the cycle is resumable one
step per invocation; the showcase repo's state.yaml tracks position.

### 6. Alternative flows and exceptions
6a. A build-epic step fails its gate (tests, audit) — fix within the cycle;
    the failure and fix become part of the demonstrative trail, not a reason
    to rewrite history.
6b. Cycle-time data incomplete (missing start/end timestamps) — backfill via
    the record-cycle-time.sh pipeline only; if impossible, record the gap
    honestly per e40 metrics-integrity rules rather than estimating by hand.
6c. Epic too large to finish in one session — resume via build-epic resume
    mode; do not squash the multi-session history.

### 7. Interface elements
Context: existing (showcase repo created in e42s01).
Static elements: story spec .md, tasks.yaml, UAT record, audit score doc.
Dynamic elements: git history (TDD commits), cycle-time metrics entries.

### 8. Domain model
Entities created (in the showcase repo): epic capsule (story spec + tasks.yaml
with verify commands), verify-work UAT record, audit-code score record,
cycle-time metrics entries, feature source code and tests.
Entities read: showcase repo's release-plan.yaml and state.yaml.

### 9. Integrations and boundaries
- GitHub (external, direction: out) — pushed commits; read-back via gh api
  for verification from THIS repo.
- e40 metrics pipeline (perennial, direction: in) — record-cycle-time.sh is
  the only sanctioned cycle-time mechanism.
- ADR-0002 local-first boundary — verify commands in THIS repo use read-only
  gh queries; the showcase repo's own gates verify its build.

### 10. Background processes
Not applicable — build-epic runs as interactive maintainer sessions.

### 11. Notifications
Not applicable — the public commit history is the only signal.

### 12. Audit and logging
The complete trail IS the deliverable: story spec, tasks with verify commands,
TDD commits, UAT record, audit score, Conventional Commit landing, and
pipeline-recorded cycle times — all committed, none reconstructed after the fact.

### 13. Solution variabilities
- Which feature epic to build (decision) — chosen from the showcase repo's
  release plan; must exercise genuine logic worth demonstrating.
- Metrics storage location in the showcase repo (config) — mirrors the e40
  layout used in bigpowers.

### 14. Quality attributes *NFR*
- Trail completeness: every one of the 8 steps must leave a readable artifact.
- Metrics integrity: cycle times recorded via record-cycle-time.sh only (e40);
  hand-arithmetic is a defect, not a shortcut.
- History honesty: no rebase/squash that erases the demonstrative steps.

### 15. Security and compliance *NFR*
- Public repo: no secrets in code, specs, or CI config.
- No write operations against THIS repo from any verify command.

### 16. UX and accessibility *NFR*
Not applicable — deliverable is a readable git history and specs/ trail.

### 17. Acceptance criteria
Scenario: Complete 8-step trail committed (happy path)
  Given the scaffolded showcase repo
  When  one feature epic is built via the full 8-step cycle
  Then  the repo's history shows the complete trail: story spec, tasks
        with verify commands, TDD commits, verify-work UAT record,
        audit-code score, Conventional Commit landing
  And   cycle-time metrics are recorded via record-cycle-time.sh (e40
        pipeline — never hand-arithmetic)

### 18. Out of scope
- Bug-fix trail (e42s03) — this story covers the feature half only.
- Building more than one feature epic — one complete trail is the deliverable.
- Registering the trail as an e37 fixture (e42s04).
- Any edits to files in THIS repo.

### 19. Open questions
Not applicable — the 8-step cycle and e40 metrics pipeline are both defined;
only the feature choice is deferred to e42s01's scope output.

### 20. References
- specs/epics/e42-showcase-repo/epic.yaml (source and v2.8x slotting note).
- scripts/record-cycle-time.sh (e40 honest-metrics pipeline to replicate).
- skills/build-epic/SKILL.md, skills/develop-tdd/SKILL.md,
  skills/verify-work/SKILL.md, skills/audit-code/SKILL.md (cycle steps).
- specs/epics/e37-golden-stories/ (downstream fixture consumer).
