STORY KEY: E37-S04
TITLE:     Add --agent mode to run-golden-suite.sh: headless chain execution per golden story, per-epic cadence, report merged with deterministic gates
TYPE:      Story
PARENT:    e42
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
The golden suite currently runs deterministic gate scripts (e31) that validate
pipeline output. The e42 golden stories extend this with agent-driven tests
that measure agent capability via pass@k 2-of-3 flake policy. Without a
unified `--agent` mode in run-golden-suite.sh, deterministic and agent-driven
results live in separate reports, and the per-epic cadence is not enforced.
This story adds `--agent` mode: headless chain execution of e42 golden stories
with merged reporting — deterministic gates first, then agent-driven stories,
one combined pass/fail verdict.

### 2. Value statement
As a release engineer, I want a single command that runs both deterministic
and agent-driven golden tests, so that I can gate a release on one combined
verdict without manually stitching reports.

### 3. Actors and permissions
- Release engineer (internal) — invokes `--agent` mode before release
- CI runner (system) — runs the combined suite in GitHub Actions
- DeepSeek v4 API (external) — provides agent execution via gh-aw

### 4. Trigger and preconditions
Trigger: `bash scripts/run-golden-suite.sh --agent` (manual or CI).
Precondition: e42s03 golden story YAMLs exist at specs/benchmarks/golden/g-*.yaml.
Precondition: gh-aw is installed and authenticated (DeepSeek v4 via Anthropic protocol).
Precondition: e31 deterministic gates pass before agent-driven stories execute.

### 5. Main flow and business logic
1. Run deterministic gate scripts (e31) — exit early on failure.
2. For each golden story YAML in specs/benchmarks/golden/:
   a. Invoke gh-aw with the golden story .lock.yml workflow.
   b. Collect pass@k results (2-of-3 per story).
   c. Merge results into combined report.
3. Emit combined report: deterministic gate status + per-story pass@k + flake analysis.
4. Exit 0 if all gates pass and all golden stories pass at pass@k; exit 1 otherwise.
5. `--dry-run` flag: validate YAMLs and workflow references without executing.

### 6. Alternative flows and exceptions
6a. gh-aw not installed — report error and exit 2.
6b. DeepSeek API unavailable — report "agent gate skipped" and exit 0 with warning (graceful degradation).
6c. Golden story YAML malformed — report which story, skip it, continue.
6d. Flake detected (pass@k < 2-of-3) — report flake rate, exit 1.
6e. `--dry-run` — validate all YAMLs and workflow refs, report findings, exit 0 on clean.

### 7. Interface elements
Context: extension of existing run-golden-suite.sh.
Static elements: `--agent` flag, `--dry-run` flag, combined report format.
Dynamic elements: per-story pass@k counters, flake analysis, DeepSeek API status.

### 8. Domain model
Entities read: specs/benchmarks/golden/g-*.yaml (golden story definitions),
.github/workflows/e42-golden-deepseek.lock.yml (compiled workflow).
Entities written: combined golden suite report (stdout + optional file).

### 9. Integrations and boundaries
- e31 deterministic gates (direction: in) — must pass before agent stories execute.
- gh-aw CLI (direction: out) — executes DeepSeek v4 via Anthropic protocol.
- DeepSeek v4 API (external) — agent execution backend.
- e42s03 golden story YAMLs (direction: in) — define what to test.
- run-golden-suite.sh (perennial) — this script, extended.

### 10. Background processes
Not applicable — invoked synchronously, headless chain execution.

### 11. Notifications
Not applicable — exit code and report are the signalling mechanism.

### 12. Audit and logging
- Timestamped per-story execution logs for each golden story run.
- Combined report archived alongside release artifacts.
- Flake analysis logged for trend tracking across weekly runs.

### 13. Solution variabilities
- DeepSeek API base URL (config) — default ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic.
- Pass@k threshold (config) — default 2-of-3, overridable.
- Golden story directory (config) — default specs/benchmarks/golden/.

### 14. Quality attributes *NFR*
- Deterministic gates: < 5 seconds (no network).
- Agent-driven stories: variable (~30-120s per story depending on DeepSeek latency).
- Combined suite: runs all stories sequentially with per-epic cadence.
- Flake resilience: pass@k 2-of-3 absorbs transient failures.

### 15. Security and compliance *NFR*
- DeepSeek API key stored in GitHub Secrets (not in repo).
- gh-aw processes stories in a sandboxed worktree.
- No user data sent to DeepSeek — only the golden story spec.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by CI and release engineers.

### 17. Acceptance criteria
Scenario: Combined suite passes (happy path)
  Given all e31 deterministic gates pass
  And   all golden story YAMLs are valid
  And   DeepSeek v4 API is available
  When  bash scripts/run-golden-suite.sh --agent
  Then  it exits 0
  And   reports "deterministic gates: PASS"
  And   reports pass@k results per golden story
  And   emits combined verdict "PASS"

Scenario: Deterministic gate fails (6a)
  Given one e31 deterministic gate fails
  When  bash scripts/run-golden-suite.sh --agent
  Then  it exits 1
  And   reports the failing deterministic gate
  And   does NOT execute any agent-driven stories

Scenario: DeepSeek API unavailable (6b)
  Given DeepSeek v4 API is unreachable
  When  bash scripts/run-golden-suite.sh --agent
  Then  it exits 0 with warning
  And   reports "agent gate skipped: DeepSeek API unavailable"

Scenario: Dry-run mode (6e)
  Given all golden story YAMLs exist
  When  bash scripts/run-golden-suite.sh --agent --dry-run
  Then  it exits 0
  And   reports validation results per YAML
  And   does NOT invoke gh-aw or the API

### 18. Out of scope
- Modifying the golden story YAML format (that is e42s03).
- Changing the pass@k policy (2-of-3 is locked).
- Auto-retrying flaked stories (they are reported, not re-run).

### 19. Open questions
- Cost tracking for DeepSeek API usage per run — deferred to e40 (metrics integrity).
- Flake baseline: how many flaked runs are acceptable before a story is flagged
  as flaky? Deferred until 3 weekly runs establish baseline per e42 epic note.

### 20. References
- specs/QUALITY-GUARANTEE-STRATEGY.md (golden suite design).
- specs/epics/e42-golden-stories/epic.yaml (parent epic, spike verdict).
- .github/workflows/e42-golden-deepseek.lock.yml (compiled G-01 workflow).
- specs/benchmarks/golden/ (golden story YAML directory — created by e42s03).
