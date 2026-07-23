---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e53s03
TITLE:     Gate-trace the compliance-to-GOLDEN hard-gate coupling
TYPE:      Enabler
PARENT:    e53
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      S   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

A later migration epic (e58, evals-over-compliance) plans to demote the `compliance` gate from
a hard, non-optional GOLDEN check to an advisory one. `scripts/lib/golden-suite-gates.sh:9`
currently hardcodes it as non-optional, and the 94% compliance threshold is cited as a "Hard
Stop" across 5 separate docs. Nobody has yet mapped exactly what breaks if that gate is
demoted — which scripts, which CI steps, which docs would need to change in the same breath.
Without that map, e58 risks silently hollowing out what GOLDEN actually verifies.

### 2. Value statement [draft]

As the e58 story that will eventually demote the compliance gate, I want a mapped dependency
report today, so that I can flip the gate later without silently breaking something nobody
remembered was coupled to it.

### 3. Actors and permissions [draft]

- e58's future author (internal) — consumes this report as a pre-flight input.
- This story's author (internal) — produces the report via hand-authored analysis of the real
  scripts and docs.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up during e53's build phase, ahead of e58.
Precondition: `golden-suite-gates.sh:9` hardcodes `compliance` as non-optional
(`is_optional=false`), and the 94% threshold is cited as a "Hard Stop" in 5 docs (confirmed to
exist, not yet enumerated by file:line anywhere).

### 5. Main flow and business logic [draft]

1. Read `golden-suite-gates.sh` and `run-verification-gates.sh` in full; trace every path that
   reads the `compliance` gate's pass/fail signal — the GOLDEN gate chain, agent-story gating,
   the release workflow.
2. For each of the 5 docs citing the 94% threshold as a Hard Stop, record the exact file:line
   and whether demoting the gate would require that doc to change too.
3. Write the findings to `specs/tech-architecture/GOLDEN-COMPLIANCE-DEPENDENCY.md`, stating
   explicitly that this story maps the dependency only — it does not flip
   `golden-suite-gates.sh:9`'s `is_optional` flag. That flip belongs to e58.

Interruption point: N/A — a single research-and-write pass, not a resumable multi-session flow.

### 6. Alternative flows and exceptions [draft]

6a. A cited doc's Hard Stop language has since been removed or changed — record the
discrepancy rather than silently updating the count.
6b. A consumer of the compliance signal is found that isn't one of the 5 already-known docs —
add it to the report rather than treating the 5 as a closed list.

### 7. Interface elements [draft]

Not applicable — a written analysis document, no UI.

### 8. Domain model [draft]

Entities touched: none (no application data). Artifact produced:
`specs/tech-architecture/GOLDEN-COMPLIANCE-DEPENDENCY.md`.

### 9. Integrations and boundaries [draft]

- `scripts/lib/golden-suite-gates.sh`, `scripts/run-verification-gates.sh` (perennial,
  direction: in) — read-only analysis targets.
- The 5 docs citing the 94% Hard Stop (perennial, direction: in) — read-only analysis targets.

### 10. Background processes [draft]

Not applicable.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The report itself, dated and committed, is the audit record.

### 13. Solution variabilities [draft]

Not applicable.

### 14. Quality attributes *NFR* [draft]

Not applicable — a static analysis document has no runtime performance dimension.

### 15. Security and compliance *NFR* [draft]

Not applicable — no secrets or PII; the report only references already-public scripts and
docs.

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: dependency report exists and covers every citing doc
  Given golden-suite-gates.sh:9 hardcodes compliance as non-optional
  And   the 94% threshold is cited as a Hard Stop in 5 docs
  When  this story completes
  Then  specs/tech-architecture/GOLDEN-COMPLIANCE-DEPENDENCY.md exists
  And   it enumerates all 5 citing docs by file:line with a change-required verdict for each

Scenario: scope boundary is explicit
  Given this story maps the dependency only
  When  the report is read
  Then  it explicitly states it does not flip golden-suite-gates.sh:9's is_optional flag
```

### 18. Out of scope [draft]

- Flipping `is_optional` on the compliance gate — that is e58's job.
- Updating any of the 5 cited docs — the report records what would need to change, it does not
  change it.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e53-establish-migration-baseline/epic.yaml`) — e53s03 AC block.
- `scripts/lib/golden-suite-gates.sh:9`.
