---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-release"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e54s02
TITLE:     Add a soft drift-detection gate for the freeze window
TYPE:      Enabler
PARENT:    e54
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      M   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

e54s01 freezes a baseline; on its own, a snapshot doesn't stop drift — it just records what
drifted from. Without an active check, a new skill can land (as `find-way` did, one commit
before this session's audit began) or an existing SKILL.md can be restructured mid-migration,
and nobody notices until e56's reclassification work discovers the catalog no longer matches
what it planned against. bigspec's own `constitution.md` (Part IV, gate types) and
`architecture.md` §10 (red-team) are explicit that gates should be risk-scaled and shipped
advisory-first — a hard block here would recreate exactly the "gate fatigue" failure mode both
documents warn against, for a freeze that is temporary by design.

### 2. Value statement [draft]

As the migration's Phase 0, I want an advisory check that flags catalog drift during the freeze
window, so that e55-e59 aren't silently planning against a baseline that's already stale,
without introducing a hard block that outlives its own justification.

### 3. Actors and permissions [draft]

- Any contributor adding or restructuring a skill during the freeze window (internal) — sees
  the WARNING and either reverts, waits, or logs an exception (e54s03).
- Preflight / CI (system) — surfaces the warning without blocking.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up as e54's second story, after e54s01's baseline exists.
Precondition: no mechanism today compares the live catalog against any prior state; a new skill
or a structural SKILL.md change currently passes Preflight silently.

### 5. Main flow and business logic [draft]

1. Write `scripts/check-catalog-drift.sh` — diffs the live `skills/*/SKILL.md` enumeration
   against the most recent `specs/tech-architecture/CATALOG-BASELINE-*.yaml` (e54s01's output).
2. Classify drift into three kinds: addition (new skill dir), removal (skill dir gone), and
   structural change (frontmatter fields changed — name/phase/effort/model).
3. Print each finding as `WARNING:`, never `FAIL:` — exit code stays 0 regardless of findings,
   consistent with a Confirm-gate (user-reviewed), not a Risk/Quality gate (blocking).
4. Wire it into `scripts/run-verification-gates.sh` as an informational step (not one of the
   `GOLDEN_GATES` entries whose exit code is checked), or into Preflight's own chain — either
   way, visible every run, never gating.
5. Recognize an explicit exception marker (e54s03's documented process) and suppress the
   warning for a change that carries one, so legitimate unrelated work isn't nagged repeatedly.

Interruption point: N/A — a single script addition, not a resumable multi-step flow.

### 6. Alternative flows and exceptions [draft]

6a. A change is legitimately unrelated to the migration (e.g. a hotfix to an existing skill's
description) — the exception marker from e54s03 lets it proceed without repeated warnings.
6b. The freeze window ends (e56 completes) — this story's gate should be easy to retire; it
must not become a permanent fixture nobody remembers to remove (documented in e54s03's exit
criteria, not solved by this story itself).
6c. No baseline file exists yet (e54s01 hasn't landed, or was deleted) — the script reports
"no baseline found, skipping drift check" rather than erroring, so it degrades gracefully
instead of blocking unrelated work.

### 7. Interface elements [draft]

Not applicable — CLI tooling, no UI surface.

### 8. Domain model [draft]

Entities touched: none (read-only diff). Reads: `specs/tech-architecture/CATALOG-BASELINE-*.yaml`
(e54s01) and live `skills/*/SKILL.md`. Produces: stdout WARNING lines only, no new artifact file.

### 9. Integrations and boundaries [draft]

- e54s01's baseline file (perennial, direction: in) — the comparison target.
- `scripts/run-verification-gates.sh` or Preflight (perennial, direction: out) — where the
  check surfaces, as advisory output only.
- e54s03's exception process (perennial, direction: in) — the suppression mechanism for 6a.

### 10. Background processes [draft]

Not applicable — runs on-demand as part of Preflight/CI, not scheduled independently.

### 11. Notifications [draft]

The WARNING output itself, printed to the contributor's own terminal/CI log — no separate
notification channel.

### 12. Audit and logging [draft]

Each run's WARNING output is the log; no persistent audit file beyond what CI already retains.

### 13. Solution variabilities [draft]

- Exception marker format (config) — a single documented convention (e54s03), not per-tenant.

### 14. Quality attributes *NFR* [draft]

- Drift check must run in well under 5s for an 80-skill catalog (a simple diff, not a heavy
  analysis) — it runs on every Preflight invocation, so it must not add perceptible latency.

### 15. Security and compliance *NFR* [draft]

Not applicable — no secrets or PII; skill metadata is already public.

### 16. UX and accessibility *NFR* [draft]

Not applicable — CLI-only, no end-user-facing surface.

### 17. Acceptance criteria [draft]

```
Scenario: a new skill during the freeze triggers a warning, not a block
  Given a baseline exists from e54s01 and a new skills/<name>/SKILL.md is added
  When  scripts/check-catalog-drift.sh is run
  Then  it prints a WARNING naming the new skill and exits 0

Scenario: no drift produces no warnings
  Given the live catalog exactly matches the baseline
  When  scripts/check-catalog-drift.sh is run
  Then  it prints no WARNING lines and exits 0

Scenario: an exception-marked change is suppressed (6a)
  Given a structural change carries the documented exception marker
  When  scripts/check-catalog-drift.sh is run
  Then  that specific change is not reported as a warning

Scenario: no baseline degrades gracefully (6c)
  Given no CATALOG-BASELINE-*.yaml file exists
  When  scripts/check-catalog-drift.sh is run
  Then  it reports "no baseline found, skipping" and exits 0, not a failure
```

### 18. Out of scope [draft]

- Turning this into a hard block at any point in this story — see e54s03 for what actually
  retires the gate at freeze end.
- Auto-fixing or reverting drift — this story only reports.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e54-freeze-catalog-drift/epic.yaml`) — e54s02 AC block.
- `/Users/danielvm/Developer/bigspec/constitution.md` Part IV (gate types) and
  `/Users/danielvm/Developer/bigspec/docs/architecture.md` §10 (red-team: "ship risk-tiered
  gates advisory-first").
