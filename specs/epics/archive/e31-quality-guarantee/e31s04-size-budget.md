STORY KEY: E31-S04
TITLE:     Add static size budget enforcement to golden suite
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      XS

### 1. Business narrative
SKILL.md files grow over time as features are added. Without a size budget, a
skill can balloon from 200 to 2,000 lines with no warning. This causes context
bloat for AI agents reading the skill. A static byte-count budget with warn/fail
thresholds catches skill bloat before it ships.

### 2. Value statement
As a maintainer, I want the golden suite to check per-skill byte counts against
a baseline, so that skill bloat is caught before merge.

### 3. Actors and permissions
- run-golden-suite.sh (system) — invokes size check as a gate.
- Maintainer (internal) — reviews size warnings.

### 4. Trigger and preconditions
Trigger: `bash scripts/run-golden-suite.sh --check-size`.
Precondition: BASELINE-GOLDEN.yaml exists with per-skill byte counts.

### 5. Main flow and business logic
1. Script reads BASELINE-GOLDEN.yaml for per-skill byte counts.
2. Script measures current byte count of every skills/*/SKILL.md.
3. Script compares current vs baseline per skill.
4. +20% over baseline → warn (exit 0 with warning message).
5. +50% over baseline → fail (exit 1).
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. No baseline file — report "run --baseline first", exit 1.
6b. New skill not in baseline — report as "new: <name>" (no threshold, info only).
6c. Skill deleted since baseline — report as "removed: <name>" (info only).

### 7. Interface elements
Context: existing (run-golden-suite.sh --check-size flag).
Static elements: warn/fail messages with byte counts and percentages.
Dynamic elements: per-skill comparison table.

### 8. Domain model
Entities read: BASELINE-GOLDEN.yaml, skills/*/SKILL.md files.

### 9. Integrations and boundaries
- BASELINE-GOLDEN.yaml (perennial, direction: in) — baseline source.
- skills/*/SKILL.md (perennial, direction: in) — measured targets.

### 10. Background processes
Not applicable.

### 11. Notifications
- stdout — per-skill warnings and failures.

### 12. Audit and logging
Not applicable — stateless check.

### 13. Solution variabilities
- warn_threshold (config) — default 20%.
- fail_threshold (config) — default 50%.

### 14. Quality attributes *NFR*
- Wall-clock: < 1 second (wc -c on ~72 files).
- Deterministic: same files → same result.

### 15. Security and compliance *NFR*
- Read-only — no filesystem writes. No secrets.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: All skills within budget (happy path)
  Given BASELINE-GOLDEN.yaml exists
  And   all SKILL.md files are within +20% of baseline
  When  run-golden-suite.sh --check-size is executed
  Then  it exits 0
  And   reports no warnings

Scenario: Skill over warn threshold
  Given a SKILL.md is +25% over baseline
  When  run-golden-suite.sh --check-size is executed
  Then  it exits 0
  And   reports "WARN: <skill> +25%"

Scenario: Skill over fail threshold
  Given a SKILL.md is +55% over baseline
  When  run-golden-suite.sh --check-size is executed
  Then  it exits 1
  And   reports "FAIL: <skill> +55%"

Scenario: No baseline (6a)
  Given BASELINE-GOLDEN.yaml does not exist
  When  run-golden-suite.sh --check-size is executed
  Then  it exits 1
  And   reports "run --baseline first"

### 18. Out of scope
- Line-count or complexity metrics (byte count only).
- Auto-rejecting PRs based on size (CI gate only).

### 19. Open questions
Not applicable.

### 20. References
- e31s03 (run-golden-suite.sh).
- e31s05 (baseline creation).
