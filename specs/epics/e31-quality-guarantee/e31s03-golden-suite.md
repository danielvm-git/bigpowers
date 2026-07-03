STORY KEY: E31-S03
TITLE:     Create deterministic golden suite runner
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      M

### 1. Business narrative
Multiple verification scripts exist (compliance, G-04 self-test, YAML validation)
but must be run individually. There is no orchestrated suite that runs them in
order, captures results in a machine-readable format, and enforces a baseline.
This makes regression detection ad-hoc. The e37 golden story G-01 expects this
suite to exist and reports when it doesn't.

### 2. Value statement
As a maintainer, I want a single command that runs all deterministic gates and
writes a timestamped report, so that I can detect regressions in one step.

### 3. Actors and permissions
- Maintainer (internal) — runs the suite locally.
- CI runner (system) — runs the suite in GitHub Actions.

### 4. Trigger and preconditions
Trigger: `bash scripts/run-golden-suite.sh` or `--dry-run`.
Precondition: project root is the working directory; bash ≥ 4.0.

### 5. Main flow and business logic
1. Script checks prerequisites (bash version, required commands).
2. Script runs `npm run compliance` and captures exit code + stdout.
3. Script runs `bash scripts/golden-g04-selftest.sh` and captures exit code + stdout.
4. Script writes results to `specs/benchmarks/reports/GOLDEN-YYYY-MM-DD.yaml`.
5. Script reports pass/fail summary to stdout.
6. Script exits 0 if all gates pass; exits 1 if any gate fails.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. --dry-run flag — print the plan without executing.
6b. --baseline flag — run suite and pin results to BASELINE-GOLDEN.yaml.
6c. A gate script is missing — report "not found: <path>", exit 1.
6d. Output directory missing — create specs/benchmarks/reports/ before writing.

### 7. Interface elements
Context: new (standalone bash script).
Static elements: CLI flags (--dry-run, --baseline), stdout summary.
Dynamic elements: per-gate pass/fail status, report file path.

### 8. Domain model
Entities created: GOLDEN-YYYY-MM-DD.yaml (timestamped report), BASELINE-GOLDEN.yaml (pinned baseline).

### 9. Integrations and boundaries
- npm run compliance (perennial, direction: in) — first gate.
- golden-g04-selftest.sh (perennial, direction: in) — second gate.
- specs/benchmarks/reports/ (perennial, direction: out) — report destination.

### 10. Background processes
Not applicable — synchronous script.

### 11. Notifications
Not applicable — stdout and exit code only.

### 12. Audit and logging
Audited entity: GOLDEN-YYYY-MM-DD.yaml. Fields: timestamp, gate_results (per gate: name, exit_code, duration_seconds), overall_pass.

### 13. Solution variabilities
- Gate list (config) — array of commands; extensible without script changes.
- Report directory (config) — hardcoded to specs/benchmarks/reports/.

### 14. Quality attributes *NFR*
- Wall-clock: sum of gate durations (< 10 seconds expected).
- Machine-readable output — YAML format with stable schema.

### 15. Security and compliance *NFR*
- Read-only except for report file writes (trusted directory).
- No secrets, no network access.

### 16. UX and accessibility *NFR*
Not applicable — CLI only.

### 17. Acceptance criteria
Scenario: All gates pass (happy path)
  Given all gate scripts exist and pass
  When  run-golden-suite.sh is executed
  Then  it exits 0
  And   writes specs/benchmarks/reports/GOLDEN-YYYY-MM-DD.yaml
  And   the report shows all gates with exit_code: 0

Scenario: Dry run (6a)
  Given --dry-run flag
  When  run-golden-suite.sh --dry-run is executed
  Then  it prints the gate list without executing
  And   exits 0

Scenario: Baseline pin (6b)
  Given --baseline flag
  When  run-golden-suite.sh --baseline is executed
  Then  it runs all gates
  And   writes specs/benchmarks/reports/BASELINE-GOLDEN.yaml
  And   the baseline includes pass_rate field

Scenario: Missing gate script (6c)
  Given scripts/golden-g04-selftest.sh does not exist
  When  run-golden-suite.sh is executed
  Then  it exits 1
  And   reports "not found: scripts/golden-g04-selftest.sh"

### 18. Out of scope
- Agent-driven golden stories (that is e37).
- Per-skill capability benchmarks (that is run-benchmark).
- Size budget enforcement (e31s04).

### 19. Open questions
Not applicable.

### 20. References
- e31s01 (G-04 self-test).
- e31s04 (size budget — extends this suite).
- specs/QUALITY-GUARANTEE-STRATEGY.md.
- specs/benchmarks/ (existing schema directory).
