STORY KEY: E40-S07
TITLE:     Quarantine fabricated cycle-times.yaml rows (tag source: backfilled) and exclude from aggregates
TYPE:      Story
PARENT:    e40
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The investigation (specs/RESEARCH-cycle-time-metrics.md) found suspicious rows
in specs/metrics/cycle-times.yaml: templated blocks (11× identical 45-min/1.3
rows), outliers (bcp_per_hour up to 120), and three e13 stories sharing identical
start and end timestamps. These rows were produced by the SELF-REPLICATING
methodology defect that e40 is fixing. Rather than deleting them (which would
erase the evidence of the defect), this story tags them as `source: backfilled`
and excludes them from all aggregates. The rows stay — marked honestly — as a
reminder of why provenance matters.

### 2. Value statement
As a benchmark consumer, I want fabricated metrics excluded from aggregates so
they don't pollute the baseline, but I also want them preserved as evidence of
the methodology defect that produced them.

### 3. Actors and permissions
- Documentation maintainer (internal) — tags the rows.
- record-cycle-time.sh (system) — excludes backfilled rows from aggregates.

### 4. Trigger and preconditions
Trigger: manual edit of specs/metrics/cycle-times.yaml.
Precondition: the suspicious rows have been identified (from research doc).

### 5. Main flow and business logic
1. Identify fabricated rows: e01/e02 45-min blocks, e13 identical timestamps, 120 BCP/hr outliers.
2. Tag each with `source: backfilled` and a note citing the investigation.
3. Update record-cycle-time.sh to exclude backfilled rows from aggregate computations.
4. Do NOT delete any rows — mark provenance honestly.

### 6. Alternative flows and exceptions
6a. Row is ambiguous (might be real, might be fabricated) — tag as `source: estimated`, not backfilled.
6b. New backfilled rows are accidentally added — validate-okf.sh rejects backfilled as non-standard source.

### 7-16. Not applicable (standard data remediation pattern)

### 17. Acceptance criteria
Scenario: Fabricated rows quarantined
  GIVEN the known suspicious rows in cycle-times.yaml
  WHEN they are tagged as source: backfilled
  THEN grep -q 'source: backfilled' specs/metrics/cycle-times.yaml exits 0
  AND the row count is unchanged (no deletion)
  AND record-cycle-time.sh excludes backfilled rows from aggregates

### 18. Out of scope
- Backfilling OKF bundles for historical stories (they stay in the legacy ledger).
- Auditing all historical rows (focus on the known suspicious patterns).

### 19. Open questions
- Should a new file (specs/metrics/cycle-times-fabricated.yaml) be created instead
  of tagging in-place? Tagging in-place preserves provenance — moving would
  break the historical context.

### 20. References
- specs/metrics/cycle-times.yaml (target file).
- specs/RESEARCH-cycle-time-metrics.md (investigation identifying suspicious rows).
- scripts/record-cycle-time.sh (e40s01, aggregate exclusion logic).
