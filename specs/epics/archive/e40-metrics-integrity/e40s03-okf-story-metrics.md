STORY KEY: E40-S03
TITLE:     Adopt OKF story-metrics bundle format (specs/templates/story-metrics.okf.md); emit one bundle per merged story
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
Currently cycle-times.yaml stores metrics as flat ledger rows — one row per
story, hand-computed fields. The OKF story-metrics bundle format
(specs/templates/story-metrics.okf.md) replaces this with structured,
machine-readable bundles: YAML frontmatter with typed fields, aggregation
tags (Σ additive / ⌀ median / % rate / • static), and a provenance gate.
record-cycle-time.sh emit one OKF bundle per merged story instead of a flat
ledger row, making metrics queryable, benchmarkable, and honestly aggregated.

### 2. Value statement
As a benchmark consumer, I want per-story metrics in a structured format with
explicit aggregation semantics, so I can compute project-level totals without
accidentally summing a median.

### 3. Actors and permissions
- record-cycle-time.sh (system) — emits OKF bundles.
- validate-okf.sh (system) — validates bundle conformance.

### 4. Trigger and preconditions
Trigger: record-cycle-time.sh append invocation.
Precondition: specs/templates/story-metrics.okf.md template exists.

### 5. Main flow and business logic
1. record-cycle-time.sh append reads template format.
2. For each merged story, emit a .md file in specs/metrics/ with:
   a. YAML frontmatter: story identity, provenance, DORA keys, agent telemetry, effort, quality, flow.
   b. Markdown body: human-readable explanation of each block.
3. Every field carries an aggregation tag: Σ (sum), ⌀ (median), % (rate), • (static).
4. Template already drafted — story is to wire the emission into record-cycle-time.sh.

### 6-16. Not applicable (standard template adoption pattern)

### 17. Acceptance criteria
Scenario: OKF bundles emitted per story
  GIVEN record-cycle-time.sh append is called for a merged story
  WHEN the bundle is emitted
  THEN the output file has okf_kind: story-metrics in frontmatter
  AND all fields carry aggregation tags
  AND the template at specs/templates/story-metrics.okf.md exists and matches

### 18. Out of scope
- Backfilling OKF bundles for historical stories (quarantine is e40s07).

### 19. Open questions
- Should the OKF bundles live in specs/metrics/ or a separate specs/metrics-bundles/?
  specs/metrics/ — existing directory, additive (cycle-times.yaml stays for historical reference).

### 20. References
- specs/templates/story-metrics.okf.md (template, pre-drafted).
- scripts/record-cycle-time.sh (e40s01, emission target).
- specs/RESEARCH-cycle-time-metrics.md.
