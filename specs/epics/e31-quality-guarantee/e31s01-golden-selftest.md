STORY KEY: E31-S01
TITLE:     Create sync-pipeline self-test script (G-04)
TYPE:      Story
PARENT:    e31
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-02
MATURITY:  3
SIZE:      S

### 1. Business narrative
The sync-skills.sh pipeline produces artifacts across 3 targets (.cursor/rules,
.gemini/extensions, .pi) with 72 skills each. A broken pipeline — wrong artifact
count, stale lockfile, inconsistent SKILL-INDEX — escapes detection because no
automated check runs after sync. The e37 golden story G-01 already probes for
this script's existence. Without G-04, pipeline regressions go undetected until
a downstream consumer (Claude, Cursor, Gemini) fails silently.

### 2. Value statement
As a maintainer, I want a deterministic self-test that validates the sync
pipeline output, so that any regression in artifact generation is caught
before merge.

### 3. Actors and permissions
- Maintainer (internal) — runs the script locally and in CI.
- CI runner (system) — executes the script in GitHub Actions.

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/golden-g04-selftest.sh`) or CI (sync-skills CI job).
Precondition: sync-skills.sh has been run and artifacts exist at expected paths.

### 5. Main flow and business logic
1. Script asserts each target directory exists (.cursor/rules, .gemini/extensions/bigpowers, .pi).
2. Script counts *.md artifact files per target and asserts 72 each.
3. Script parses skills-lock.json and asserts the count matches SKILL-INDEX.md total.
4. Script exits 0 on all assertions passing; exits non-zero with diff on failure.
Interruption point: N/A (script runs to completion in < 2 seconds).

### 6. Alternative flows and exceptions
6a. Target directory missing — report which directory, exit 1.
6b. Artifact count mismatch — report expected 72 vs actual N per target, exit 1.
6c. Lockfile vs index mismatch — report lockfile count vs index count, exit 1.
6d. skills-lock.json unparseable — report JSON parse error, exit 1.

### 7. Interface elements
Context: new (standalone bash script).
Static elements: exit codes (0/1), stdout messages.
Dynamic elements: count diffs (expected vs actual).

### 8. Domain model
Entities read: skills-lock.json (skill catalog), SKILL-INDEX.md (markdown index),
artifact directories (.cursor/rules/*.md, .gemini/extensions/bigpowers/*.md, .pi/skills/*/SKILL.md).

### 9. Integrations and boundaries
- sync-skills.sh (perennial, direction: in) — produces the artifacts this script validates.

### 10. Background processes
Not applicable — invoked synchronously by CI or human.

### 11. Notifications
Not applicable — exit code and stdout are the only signalling mechanism.

### 12. Audit and logging
Not applicable — deterministic script, no persistent audit trail needed.

### 13. Solution variabilities
- Target directories (config) — hardcoded to the 3 current targets; extensible via array.

### 14. Quality attributes *NFR*
- Wall-clock: < 2 seconds (file counting only, no network).
- Deterministic: same input → same output, every run.

### 15. Security and compliance *NFR*
- Reads only — no write operations, no secrets, no network access.
- Safe to run in any CI context with read-only permissions.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by CI and maintainers.

### 17. Acceptance criteria
Scenario: All artifacts consistent (happy path)
  Given sync-skills.sh has been run successfully
  When  golden-g04-selftest.sh is executed
  Then  it exits 0
  And   reports "72 artifacts per target"
  And   reports "lockfile count matches index"

Scenario: Missing target directory (6a)
  Given .cursor/rules does not exist
  When  golden-g04-selftest.sh is executed
  Then  it exits 1
  And   reports ".cursor/rules: directory not found"

Scenario: Artifact count mismatch (6b)
  Given .cursor/rules contains 70 .md files
  When  golden-g04-selftest.sh is executed
  Then  it exits 1
  And   reports "expected 72, got 70 in .cursor/rules"

Scenario: Lockfile/index mismatch (6c)
  Given skills-lock.json lists 70 skills and SKILL-INDEX.md shows 72
  When  golden-g04-selftest.sh is executed
  Then  it exits 1
  And   reports "lockfile (70) != index (72)"

Scenario: Unparseable lockfile (6d)
  Given skills-lock.json contains invalid JSON
  When  golden-g04-selftest.sh is executed
  Then  it exits 1
  And   reports "skills-lock.json: parse error"

### 18. Out of scope
- Checking .md file content (only counts artifacts, does not diff contents).
- Validating individual SKILL.md frontmatter (that is sync-skills.sh's job).
- Auto-fixing mismatches (script is read-only).

### 19. Open questions
Not applicable — scope is well-defined from QUALITY-GUARANTEE-STRATEGY.md.

### 20. References
- specs/QUALITY-GUARANTEE-STRATEGY.md (G-04 definition).
- scripts/sync-skills.sh (pipeline under test).
- .github/workflows/e37-golden-deepseek.md (G-01 golden story that probes for this script).
