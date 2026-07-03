STORY KEY: E40-S06
TITLE:     validate-okf.sh + provenance gate (e31-style): bundle valid iff generator ran and commit_range resolves; wire into compliance CI
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
OKF story-metrics bundles (e40s03) are machine-generated, but without a
validation gate, a corrupted bundle could silently pollute benchmarks. The
e31 Quality Guarantee established the pattern: deterministic self-test
scripts that gate on pass/fail. validate-okf.sh applies this to metrics:
a bundle is valid iff the generator ran (record-cycle-time.sh) and
commit_range resolves to real commits. It also checks required keys,
source enum (measured|estimated|backfilled), correct additive-vs-median
tag per field, and bounds sanity (no cycle_minutes <= 0, no bcp_per_hour).
It NEVER gates on a specific metric value — only on provenance and freshness.

### 2. Value statement
As a benchmark consumer, I want confidence that every metric bundle was
produced by the official generator and references real commits, so I can
trust the aggregate without auditing individual rows.

### 3. Actors and permissions
- CI runner (system) — runs validate-okf.sh in compliance pipeline.
- Agent (system) — can run manually to check bundle validity.

### 4. Trigger and preconditions
Trigger: npm run compliance, CI pipeline, or manual invocation.
Precondition: OKF story-metrics bundles exist in specs/metrics/.

### 5. Main flow and business logic
1. Scan specs/metrics/ for OKF bundles (files with okf_kind: story-metrics frontmatter).
2. For each bundle:
   a. Assert required keys present: id, epic, bcps, commit_range, source, generated_at, generator.
   b. Assert source enum value is valid: measured|estimated|backfilled.
   c. Assert generator field matches scripts/record-cycle-time.sh.
   d. Assert commit_range resolves to real commits (git log check).
   e. Assert aggregation tags correct: Σ fields are numeric, ⌀ fields are numeric or null, % fields are 0-100.
   f. Assert bounds sanity: no negative values, no impossible ratios.
3. Report PASS/FAIL per bundle with specific remediation hints.
4. Exit 0 if all bundles PASS; exit 1 if any FAIL.

### 6. Alternative flows and exceptions
6a. No OKF bundles found — exit 0 with warning (not an error: no stories merged yet).
6b. Generator field doesn't match — FAIL with hint "regenerated with non-standard tool?"
6c. commit_range unresolvable — FAIL with hint "commit_range may reference squashed/deleted commits."

### 7-16. Not applicable (standard validation script pattern)

### 17. Acceptance criteria
Scenario: Valid bundle passes
  GIVEN a story-metrics OKF bundle with all required keys and valid provenance
  WHEN validate-okf.sh runs
  THEN it reports PASS for that bundle
  AND exits 0

Scenario: Bundle with unresolvable commit_range fails
  GIVEN a bundle whose commit_range does not resolve
  WHEN validate-okf.sh runs
  THEN it reports FAIL with remediation hint
  AND exits 1

Scenario: Bundle missing source field fails
  GIVEN a bundle without a source tag
  WHEN validate-okf.sh runs
  THEN it reports FAIL: "missing source field — must be measured|estimated|backfilled"
  AND exits 1

### 18. Out of scope
- Validating OKF content quality (lint is maintain-wiki's job, e39s07).
- Auto-fixing invalid bundles (validate-okf is read-only detection).

### 19. Open questions
- Should validate-okf.sh be blocking in CI from day 1? Yes — it gates on
  provenance, not values, so false positives are unlikely. Blocking
  after e40s01-s03 are complete.

### 20. References
- specs/templates/story-metrics.okf.md (bundle format).
- scripts/record-cycle-time.sh (generator, e40s01).
- specs/epics/archive/e31-quality-guarantee/ (e31-style deterministic gates).
- scripts/validate-specs-yaml.sh (sibling validation script).
