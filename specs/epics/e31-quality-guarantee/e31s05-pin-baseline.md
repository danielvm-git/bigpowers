STORY KEY: E31-S05
TITLE:     Pin baseline for golden suite
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      XS

### 1. Business narrative
The golden suite needs a baseline to compare against for size budgets (e31s04)
and future regression detection. Without a committed baseline file, every run
starts from scratch and size drift goes unnoticed. A single --baseline command
captures the current state and commits it as the reference point.

### 2. Value statement
As a maintainer, I want to pin a baseline snapshot so that future golden suite
runs can detect drift from the known-good state.

### 3. Actors and permissions
- Maintainer (internal) — runs --baseline once after all gates pass.
- CI runner (system) — does not create baselines (manual only).

### 4. Trigger and preconditions
Trigger: `bash scripts/run-golden-suite.sh --baseline`.
Precondition: all gates pass (baseline must represent a healthy state).

### 5. Main flow and business logic
1. Script runs all deterministic gates.
2. If all gates pass, script writes BASELINE-GOLDEN.yaml.
3. If any gate fails, script exits 1 and does not write baseline.
4. Baseline file includes: timestamp, git commit, per-gate status, per-skill byte counts, pass_rate: 1.0.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. A gate fails — report which gate, exit 1, do not write baseline.

### 7. Interface elements
Context: existing (--baseline flag on run-golden-suite.sh).
Static elements: baseline file path, success/failure message.

### 8. Domain model
Entity created: BASELINE-GOLDEN.yaml (pinned reference state).

### 9. Integrations and boundaries
Not applicable — file write within repo.

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
Audited entity: BASELINE-GOLDEN.yaml. Fields: created_at, git_commit, pass_rate, per_gate results, per_skill byte_counts.

### 13. Solution variabilities
Not applicable — single invocation mode.

### 14. Quality attributes *NFR*
- Baseline creation: < 10 seconds (same as full suite run).
- File must be valid YAML and committed to git.

### 15. Security and compliance *NFR*
- Write only to trusted directory (specs/benchmarks/reports/).
- Must not overwrite existing baseline without confirmation.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Baseline created from healthy state (happy path)
  Given all gates pass
  When  run-golden-suite.sh --baseline is executed
  Then  it exits 0
  And   writes specs/benchmarks/reports/BASELINE-GOLDEN.yaml
  And   the file contains pass_rate: 1.0

Scenario: Gate failure blocks baseline (6a)
  Given a gate fails
  When  run-golden-suite.sh --baseline is executed
  Then  it exits 1
  And   does not write BASELINE-GOLDEN.yaml

### 18. Out of scope
- Automatic baseline updates (manual only).
- Baseline diff visualization.

### 19. Open questions
Not applicable.

### 20. References
- e31s03 (run-golden-suite.sh).
- e31s04 (size budget — consumes this baseline).
