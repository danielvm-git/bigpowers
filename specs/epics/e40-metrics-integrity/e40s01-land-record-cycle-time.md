STORY KEY: E40-S01
TITLE:     Land record-cycle-time.sh — git-derived additive effort + lead_time (report/append + additivity self-check)
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      XS

### 1. Business narrative
specs/metrics/cycle-times.yaml is unreliable: agent-self-reported wall-clock,
hand-computed, ungated — with outliers up to 120 BCP/hr and eleven identical
templated 45-min rows. scripts/record-cycle-time.sh was drafted and verified in
the 2026-07-03 session (interleaving and overnight cases both sum exactly to
the whole-repo total). This story lands the script as an integrated, guarded
tool: usage/help output for discoverability and a --self-test subcommand that
asserts the additivity invariant on demand, so the invariant is checkable in CI
rather than only trusted from the drafting session.

### 2. Value statement
As a maintainer, I want the git-derived cycle-time script landed with a help
guard and a runnable additivity self-test, so that effort and lead-time numbers
are recomputed deterministically from git and the Σ(story effort) == whole-repo
effort invariant can be re-proven at any time.

### 3. Actors and permissions
- Maintainer (internal) — runs report/append/self-test locally.
- CI runner (system) — will invoke the self-test once wired into gates (e40s06).
- release-branch skill (agent) — future caller of `append` (e40s02, out of this story).

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/record-cycle-time.sh {report|append|--self-test}`).
Precondition: script exists at scripts/record-cycle-time.sh (drafted in prior
session); repo has git history with `Story: <id>` trailers for attribution.

### 5. Main flow and business logic
1. Invoked with no arguments or `--help`/`-h`, the script prints usage
   (report/append/self-test synopsis) — help exits 0, bare invocation exits non-zero.
2. `report` partitions the commit stream globally (gap < 120 min → real effort
   credited to the later commit's story; gap ≥ 120 min → flat 120-min session
   pad), prints per-story effort_hours, and runs the additivity check against
   the whole-range oracle.
3. `append` recomputes the partition and appends one measured row (effort_hours
   ADDITIVE; lead_time_minutes calendar latency, median-aggregated, NEVER
   summed; commit_count; commit_range; source: measured; idle_threshold_min).
4. `--self-test` runs the additivity assertion — Σ(per-story effort_hours)
   equals the whole-repo effort within rounding tolerance — exiting 0 on pass,
   1 on failure.
Interruption point: N/A (script runs to completion in seconds).

### 6. Alternative flows and exceptions
6a. No arguments — print usage to stderr, exit non-zero.
6b. `--help` / `-h` — print usage to stdout, exit 0.
6c. Additivity check fails — report Σ vs whole-range values, exit 1.
6d. `append` for a story with no attributable commits — die with a hint about
    the `Story: <id>` trailer, exit 1 (existing behaviour, preserved).
6e. Not inside a git repo, or git missing — die with message, exit 1
    (existing behaviour, preserved).

### 7. Interface elements
Context: existing (scripts/record-cycle-time.sh, extended).
Static elements: subcommands report/append, new --help/-h and --self-test,
exit codes (0/1), usage text.
Dynamic elements: per-story effort table, additivity PASS/FAIL line.

### 8. Domain model
Entities read: git commit log (author dates, SHAs, `Story:` trailers).
Entities written: specs/metrics/cycle-times.yaml rows (append mode only).
Key fields: effort_hours (Σ additive, idle-stripped), lead_time_minutes
(⌀ median-aggregated, never summed) — two SEPARATED fields by design.

### 9. Integrations and boundaries
- git (perennial, direction: in) — sole data source; no daemon, no editor plugin.
- specs/metrics/cycle-times.yaml (internal, direction: out) — append target.
- release-branch skill (internal, direction: in, future) — wired in e40s02.

### 10. Background processes
Not applicable — invoked synchronously by a human, a skill, or CI.

### 11. Notifications
Not applicable — exit code and stdout/stderr are the only signalling mechanism.

### 12. Audit and logging
Appended rows carry provenance fields (commit_range, source: measured,
idle_threshold_min) so every number is traceable to real commits; no separate
audit trail needed.

### 13. Solution variabilities
- Idle threshold and session pad (config) — 120 min constants, matching the
  git-hours defaults (maxCommitDiffInMinutes / firstCommitAdditionInMinutes).
- Story trailer key (config) — `--story-key`, default `Story`.

### 14. Quality attributes *NFR*
- Deterministic: same git range → same output, every run.
- Wall-clock: seconds (single git log pass + awk; no network).
- Additivity invariant machine-checked, not assumed.

### 15. Security and compliance *NFR*
- Reads git log only; writes only the ledger file in append mode.
- No secrets, no network access; safe in read-only CI for report/self-test.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by CI, skills, and maintainers.

### 17. Acceptance criteria
Scenario: Help guard (6b)
  Given scripts/record-cycle-time.sh is landed
  When  it is invoked with --help
  Then  it exits 0
  And   the usage text names the report and append subcommands

Scenario: Bare invocation refused (6a)
  Given scripts/record-cycle-time.sh is landed
  When  it is invoked with no arguments
  Then  it exits non-zero
  And   prints a usage line mentioning report and append

Scenario: Additivity self-test passes on real history
  Given the repo has commits with Story trailers
  When  the script is invoked with --self-test
  Then  it exits 0
  And   reports that Σ(per-story effort_hours) equals the whole-range effort

Scenario: Additivity failure is loud (6c)
  Given the partition and the whole-range oracle disagree beyond tolerance
  When  the self-test runs
  Then  it exits 1
  And   reports both the partition sum and the oracle value

Scenario: Report still runs end-to-end
  Given the script is landed with the new guards
  When  `report` is invoked on the default range
  Then  it exits 0
  And   prints one effort row per story bucket plus the ADDITIVITY line

### 18. Out of scope
- Wiring `append` into release-branch (e40s02).
- Emitting OKF bundles instead of flat ledger rows (e40s03).
- Validating or gating existing cycle-times.yaml rows (e40s06, e40s07).
- Changing the partition algorithm itself — drafted and verified in the prior
  session; this story only integrates and guards it.

### 19. Open questions
Not applicable — scope is fixed by the epic source block and the drafted script.

### 20. References
- scripts/record-cycle-time.sh (drafted + verified 2026-07-03 session).
- specs/RESEARCH-cycle-time-metrics.md (git-hours model, additivity proof, RQ1/RQ3).
- specs/CHANGE-REQUEST-e40-metrics-integrity.md (implementation plan step e40s01).
- specs/epics/e40-metrics-integrity/epic.yaml (locked design decisions).
