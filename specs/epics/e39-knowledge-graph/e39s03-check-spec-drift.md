STORY KEY: E39-S03
TITLE:     Create scripts/check-spec-drift.sh — requirement change → suspect trace links
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The e38 traceability gate links requirements to implementing code, but those
links can silently go stale: when an epic capsule YAML or release-plan.yaml is
modified AFTER the implementation landed, the trace link still reports green
even though the code may no longer satisfy the changed requirement. No tool
answers "if RQ-12 changes, what code might be stale?" — the spec drift
detection gap in Layer 5 (Product Surface).

### 2. Value statement
As a maintainer, I want a script that flags trace links as suspect when a
requirement changed after its implementation, so that stale implementations
surface as CONCERNS in the traceability gate instead of passing silently.

### 3. Actors and permissions
- Maintainer (internal) — runs the script locally.
- CI runner (system) — may run it alongside gate-trace.
- gate-trace (system) — consumes specs/drift-report.json to downgrade verdicts.

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/check-spec-drift.sh`) or as a gate-trace
companion step when an epic capsule YAML or release-plan.yaml is modified.
Precondition: e38 trace links exist mapping requirements to implementing files.

### 5. Main flow and business logic
1. For each traced requirement, compare mtime of the requirement file (epic
   capsule YAML or release-plan.yaml) vs. mtime of its implementing files.
2. If the requirement changed AFTER the implementation → mark that trace link
   as "suspect".
3. Write all suspect links to specs/drift-report.json.
4. gate-trace downgrades PASS→CONCERNS if suspect links exist; suspect links
   appear in the trace matrix with a ⚠️ marker.
5. Exit 0 when no suspect links; non-zero exit signals suspects found.
Interruption point: N/A (script runs to completion).

### 6. Alternative flows and exceptions
6a. Trace link references a non-existent implementing file — report as broken
    link, include in drift-report.json.
6b. No trace links exist yet — report "nothing to check", exit 0.
6c. drift-report.json unwritable — report error, exit 1.
6d. --help flag — print usage and exit 0.

### 7. Interface elements
Context: new (standalone bash script) + gate-trace extension.
Static elements: --help usage, exit codes, drift-report.json schema.
Dynamic elements: suspect-link list (requirement, implementing file,
mtime delta), ⚠️ markers in trace matrix.

### 8. Domain model
Entities read: epic capsule YAML files (specs/epics/*/epic.yaml),
specs/release-plan.yaml, e38 trace links, implementing file mtimes.
Entities written: specs/drift-report.json (suspect and broken links).

### 9. Integrations and boundaries
- e38 traceability (perennial, direction: in) — supplies the trace links this
  script evaluates; suspect links feed back into the e38 trace matrix.
- gate-trace (perennial, direction: out) — reads drift-report.json and
  downgrades PASS→CONCERNS when suspects exist.

### 10. Background processes
Not applicable — invoked synchronously by maintainer, CI, or gate-trace.

### 11. Notifications
Not applicable — drift-report.json, exit code, and trace-matrix ⚠️ markers
are the only signalling mechanisms.

### 12. Audit and logging
drift-report.json is the persisted record of each run; git history of the
report provides drift chronology.

### 13. Solution variabilities
- Drift heuristic (design) — mtime comparison initially; could later use git
  commit timestamps for robustness across checkouts.

### 14. Quality attributes *NFR*
- Wall-clock: seconds (stat calls over traced files, no network).
- Deterministic for a given working tree state.

### 15. Security and compliance *NFR*
- Reads repo files only; writes only specs/drift-report.json. No secrets,
  no network.

### 16. UX and accessibility *NFR*
Not applicable — CLI script and JSON report consumed by gate-trace and
maintainers.

### 17. Acceptance criteria
Scenario: No drift (happy path)
  Given every traced requirement is older than its implementing files
  When  check-spec-drift.sh is executed
  Then  it exits 0
  And   specs/drift-report.json contains zero suspect links

Scenario: Requirement changed after implementation
  Given an epic capsule YAML was modified after its implementing files
  When  check-spec-drift.sh is executed
  Then  the trace link is marked "suspect" in specs/drift-report.json
  And   the exit code is non-zero

Scenario: Gate downgrade on suspects
  Given specs/drift-report.json contains at least one suspect link
  When  gate-trace runs
  Then  a PASS verdict is downgraded to CONCERNS
  And   the suspect link appears in the trace matrix with a ⚠️ marker

Scenario: Broken implementing file (6a)
  Given a trace link points at a file that no longer exists
  When  check-spec-drift.sh is executed
  Then  the link is reported as broken in specs/drift-report.json

Scenario: Help flag (6d)
  Given the script exists
  When  check-spec-drift.sh --help is executed
  Then  it prints usage and exits 0

### 18. Out of scope
- Semantic diffing of requirement text (mtime/timestamp comparison only).
- Auto-repairing suspect links or regenerating implementations.
- Drift detection for files outside the e38 trace links.

### 19. Open questions
- mtime vs. git commit timestamps: mtime is unreliable after fresh clones;
  the implementation may need `git log -1 --format=%ct` as the comparison
  source.

### 20. References
- specs/epics/e39-knowledge-graph/epic.yaml (e39s03 description).
- e38 traceability gate stories (trace links, gate-trace, trace matrix).
- specs/IMPACT-e38-okf-adoption.md (spec drift as a remaining missing-link
  question).
