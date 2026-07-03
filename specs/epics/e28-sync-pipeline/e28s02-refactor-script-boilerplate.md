STORY KEY: E33-S02
TITLE:     Refactor 13 scripts to source skill-common.sh instead of duplicating boilerplate
TYPE:      Story
PARENT:    e28
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
Thirteen scripts under scripts/ each carry their own copy of the
`REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` boilerplate
(confirmed by grep at planning time). Once e28s01 ships skill-common.sh, these
copies are dead weight and drift risk: any change to repo-root or SKILLS_ROOT
resolution must be applied 13 times. This story replaces every duplicated
incantation with a single `source scripts/lib/skill-common.sh` line, leaving
at most one legitimate occurrence (inside the library itself).

### 2. Value statement
As a maintainer, I want all scripts to source the shared library for
repo-root resolution, so that path logic exists in exactly one place and a
grep for the old incantation proves the duplication is gone.

### 3. Actors and permissions
- Maintainer (internal) — runs the refactored scripts locally and in CI.
- CI runner (system) — executes the scripts in GitHub Actions workflows.

### 4. Trigger and preconditions
Trigger: manual refactor pass over scripts/*.sh.
Precondition: e28s01 complete — scripts/lib/skill-common.sh exists and its
resolve_repo_root behaviour matches the boilerplate it replaces.

### 5. Main flow and business logic
1. Enumerate the 13 scripts matching `REPO_ROOT=.*dirname.*BASH_SOURCE`.
2. In each, replace the inline REPO_ROOT (and SKILLS_ROOT, where present)
   derivation with sourcing scripts/lib/skill-common.sh and calling
   resolve_repo_root.
3. Preserve each script's observable behaviour byte-for-byte — this is a
   pure mechanical refactor, no output changes.
4. Re-run the pipeline (`bash scripts/sync-skills.sh`) and the golden
   self-test to prove no regression.

### 6. Alternative flows and exceptions
6a. A script needs a different relative depth to repo root — resolve_repo_root
    must handle it; if it cannot, the script is flagged and left as-is with a
    comment, and the exception is recorded in the epic notes.
6b. A script is sourced (not executed) by another script — sourcing order must
    avoid double-definition errors (library's include guard from e28s01).

### 7. Interface elements
Not applicable — no user-facing surface; scripts keep identical CLI behaviour.

### 8. Domain model
Entities read: scripts/*.sh source files. No domain data model changes.

### 9. Integrations and boundaries
- scripts/lib/skill-common.sh (e28s01, direction: in) — single source of path
  resolution.
- GitHub Actions workflows (perennial, direction: out) — invoke these scripts;
  behaviour must be unchanged.
- Downstream e39 (depends_on e28): e39's OKF generation scripts will follow
  this same source-the-library pattern on top of e28's render-target
  architecture, so this story establishes the convention e39 inherits.

### 10. Background processes
Not applicable — scripts remain synchronously invoked.

### 11. Notifications
Not applicable — no change to script signalling.

### 12. Audit and logging
Not applicable — no persistent audit trail involved.

### 13. Solution variabilities
- Scripts with non-standard depth or sourcing patterns (6a) may keep a local
  fallback, documented inline.

### 14. Quality attributes *NFR*
- Zero behaviour change: identical stdout/exit codes for every refactored
  script on the same inputs.
- Duplication metric: at most 1 file still matching the old incantation.

### 15. Security and compliance *NFR*
- No new file access, network, or privilege — mechanical refactor only.

### 16. UX and accessibility *NFR*
Not applicable — CLI scripts, no human-facing UI change.

### 17. Acceptance criteria
Scenario: Boilerplate eliminated (happy path)
  Given all 13 scripts have been refactored
  When  `grep -c 'REPO_ROOT=.*dirname.*BASH_SOURCE' scripts/*.sh | grep -v ':0$' | wc -l` is run
  Then  the count is at most 1

Scenario: Pipeline behaviour unchanged
  Given the refactor is complete
  When  `bash scripts/sync-skills.sh` is run
  Then  it exits 0
  And   `bash scripts/golden-g04-selftest.sh` exits 0

Scenario: Refactored script runs standalone
  Given any refactored script is invoked directly from an arbitrary cwd
  When  it executes
  Then  it resolves the repo root correctly via the library
  And   produces the same output as before the refactor

### 18. Out of scope
- Refactoring sync-skills.sh's render logic (e28s03).
- Refactoring the index/lockfile scripts' skill-parsing internals (e28s04).
- Any behaviour or output change in the scripts.

### 19. Open questions
- Which, if any, of the 13 scripts fall under exception 6a — resolved during
  implementation, recorded inline.

### 20. References
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.1 (epic source).
- specs/epics/e28-sync-pipeline/e28s01-skill-common-library.md (library this
  story consumes).
- scripts/*.sh (the 13 scripts matching the boilerplate grep).
