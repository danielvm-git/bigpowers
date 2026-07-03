STORY KEY: E39-S02
TITLE:     Create specs/agent-locks.yaml — multi-agent coordination protocol
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
When multiple agents work the same repository (build-epic sessions, dispatched
subagents), nothing records which agent is working on which story or which
files it is touching. Two agents can silently modify the same files, producing
merge conflicts or lost work. This is the Layer 5 (Product Surface) gap:
"which open agents are touching the same requirement?" has no answer today.

### 2. Value statement
As a solo developer running multiple agents, I want a lock file that tracks
which agent holds which story and which files, so that two agents never modify
the same files concurrently and lock conflicts surface before work starts.

### 3. Actors and permissions
- Agent running kickoff-branch (system) — acquires a lock.
- Agent running release-branch (system) — releases its lock.
- CI runner (system) — validates that no lock is stale (>24h).
- Maintainer (internal) — inspects or manually clears locks.

### 4. Trigger and preconditions
Trigger: kickoff-branch start (acquire), release-branch completion (release),
CI run (stale-lock validation).
Precondition: specs/agent-locks.yaml exists (created empty by this story).

### 5. Main flow and business logic
1. kickoff-branch, before creating a worktree, reads specs/agent-locks.yaml.
2. If the target story_id is unlocked, it appends a lock entry:
   ```yaml
   locks:
     - story_id: e30s01
       locked_by: "agent: build-epic session-abc123"
       locked_at: "2026-07-03T01:00:00Z"
       files_touched: [skills/build-epic/SKILL.md, scripts/audit-compliance.sh]
   ```
3. If the story is already locked, kickoff-branch FAILS with the holder's
   identity and locked_at timestamp.
4. release-branch removes the lock entry on completion.
5. CI validates no lock is older than 24h; stale locks fail the check.
Interruption point: a lock left behind by a crashed agent is the stale-lock
case handled by the CI check (5).

### 6. Alternative flows and exceptions
6a. Story already locked — kickoff-branch aborts, reports holder and timestamp.
6b. Stale lock (>24h) found by CI — check fails, names the stale entry.
6c. release-branch finds no lock for its story — warn and continue (idempotent
    release).
6d. agent-locks.yaml unparseable — acquisition and CI check fail with parse error.

### 7. Interface elements
Context: extends existing skills (kickoff-branch, release-branch) + new file.
Static elements: YAML schema (locks: list of story_id/locked_by/locked_at/
files_touched), CI check exit codes.
Dynamic elements: lock holder and age reported on conflict.

### 8. Domain model
Entities written: specs/agent-locks.yaml (lock ledger).
Entity fields: story_id (string), locked_by (agent identity string),
locked_at (ISO-8601 UTC timestamp), files_touched (list of repo paths).

### 9. Integrations and boundaries
- kickoff-branch skill (perennial, direction: in/out) — acquires locks; fails
  if already locked.
- release-branch skill (perennial, direction: in/out) — releases locks.
- CI (perennial, direction: in) — validates no stale locks (>24h).

### 10. Background processes
Not applicable — lock operations run inline within skill invocations; the
stale check runs inside existing CI jobs.

### 11. Notifications
Not applicable — conflicts and stale locks are reported via skill output and
CI failure only.

### 12. Audit and logging
Lock entries themselves are the audit trail: locked_by and locked_at record
who held what and since when, versioned in git history.

### 13. Solution variabilities
- Staleness threshold (config) — 24h default, a single variable in the check.
- Lock granularity — story-level with advisory files_touched list.

### 14. Quality attributes *NFR*
- Lock check adds negligible time to kickoff-branch (single YAML read).
- Deterministic: same ledger state → same acquire/release/stale outcome.

### 15. Security and compliance *NFR*
- Plain YAML in-repo, no secrets. Agent identity strings contain session ids
  only, no credentials.

### 16. UX and accessibility *NFR*
Not applicable — YAML ledger consumed by skills and CI.

### 17. Acceptance criteria
Scenario: Acquire free lock (happy path)
  Given specs/agent-locks.yaml has no lock for story e30s01
  When  kickoff-branch starts work on e30s01
  Then  a lock entry with story_id, locked_by, locked_at, files_touched is added

Scenario: Acquisition blocked by existing lock (6a)
  Given e30s01 is locked by "agent: build-epic session-abc123"
  When  a second agent's kickoff-branch targets e30s01
  Then  kickoff-branch fails
  And   reports the holder identity and locked_at timestamp

Scenario: Release on completion
  Given an agent holds the lock for e30s01
  When  release-branch completes for e30s01
  Then  the lock entry for e30s01 is removed

Scenario: Stale lock detection (6b)
  Given a lock whose locked_at is more than 24 hours old
  When  the CI stale-lock validation runs
  Then  the check fails
  And   names the stale story_id and holder

Scenario: Unparseable ledger (6d)
  Given specs/agent-locks.yaml contains invalid YAML
  When  lock acquisition or CI validation runs
  Then  it fails with a parse error

### 18. Out of scope
- File-level locking or merge conflict resolution (locks are story-scoped,
  files_touched is advisory).
- Cross-repository coordination.
- Automatic stale-lock cleanup (CI fails; a human or agent clears the entry).

### 19. Open questions
- Whether dispatch-agents should also acquire locks for its parallel workers,
  or rely on the dispatcher holding one story-level lock.

### 20. References
- specs/epics/e39-knowledge-graph/epic.yaml (e39s02 description with schema).
- skills/kickoff-branch/SKILL.md, skills/release-branch/SKILL.md (integration
  points).
- specs/IMPACT-e38-okf-adoption.md (Layer 5 multi-agent awareness gap).
