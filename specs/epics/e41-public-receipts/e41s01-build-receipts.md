STORY KEY: E41-S01
TITLE:     Create scripts/build-receipts.sh — aggregate all quality evidence into specs/receipts.json
TYPE:      Story
PARENT:    e41
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
bigpowers' quality evidence is scattered across four independent artifacts:
the compliance score (e31, live), golden-story pass@k reports (e37), honest
git-derived OKF metric bundles (e40), and the traceability matrix (e38). No
single machine-readable document aggregates them, so the public receipts page
(e41s02) has nothing to render from. This story creates the aggregator:
scripts/build-receipts.sh reads each evidence source from its canonical
location and emits specs/receipts.json — the single source of truth every
downstream consumer (page, CI gate, validator) reads.

### 2. Value statement
As a maintainer, I want one script that aggregates all quality evidence into
a single receipts.json with per-section provenance, so that the public
receipts page renders verified evidence instead of hand-maintained claims.

### 3. Actors and permissions
- Maintainer (internal) — runs the script locally.
- CI runner (system) — executes the script in the docs-site workflow (e41s03).

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/build-receipts.sh`) or CI (docs-site workflow,
wired in e41s03).
Precondition: none strictly — any subset of the four evidence artifacts may
exist; missing artifacts are handled as an explicit `absent` state, not an
error.

### 5. Main flow and business logic
1. Script reads the compliance score from audit-compliance.sh output.
2. Script reads golden-suite results from specs/benchmarks/reports/.
3. Script reads metrics from specs/metrics/ OKF bundles (e40 format).
4. Script reads the traceability matrix from specs/traceability-matrix.json.
5. Script emits specs/receipts.json with one section per evidence source
   (compliance, golden_suite, metrics, traceability), each carrying:
   value, generated_at, source enum (measured|estimated|backfilled|absent),
   and the command that produced it.
6. Script exits 0.
Interruption point: N/A (script runs to completion, no network).

### 6. Alternative flows and exceptions
6a. Evidence artifact missing (e.g. no traceability-matrix.json yet) — the
    corresponding section is emitted with `source: absent` and NO value
    field; the script still exits 0. Missing evidence is a state, not an
    error — this is the epic's core design rule: degrade to an explicit
    "not yet measured" state, never fabricate a number.
6b. Evidence artifact present but unparseable — treat as absent for that
    section and report the parse problem on stderr; still exit 0 so partial
    evidence can ship.

### 7. Interface elements
Context: new (standalone bash script + generated JSON document).
Static elements: exit code 0, receipts.json schema (four fixed section keys).
Dynamic elements: per-section value, generated_at timestamp, source tag,
producing command.

### 8. Domain model
Entities read: compliance score (audit-compliance.sh output), golden-suite
reports (specs/benchmarks/reports/), OKF metric bundles (specs/metrics/),
traceability matrix (specs/traceability-matrix.json).
Entity written: specs/receipts.json (receipt document — sections keyed
compliance, golden_suite, metrics, traceability).

### 9. Integrations and boundaries
- e40 honest metrics / OKF bundles (hard dependency, direction: in) — the
  metrics section MUST read e40-format bundles with their source tags;
  displaying pre-e40 numbers is exactly the dishonesty this epic exists to
  reject.
- e28 docs site (hard dependency, direction: out) — receipts.json is
  consumed by the site build (e41s02); the schema is the contract.
- e38 traceability matrix (soft dependency, direction: in) — until e38
  lands, specs/traceability-matrix.json is missing and the traceability
  section emits `source: absent`.
- e37 golden suite (soft dependency, direction: in) — until e37s02–s04
  land, golden-suite reports may be missing and that section emits
  `source: absent`.
- e31 compliance score (perennial, direction: in) — already live; expected
  to be `measured` from day one.

### 10. Background processes
Not applicable — invoked synchronously by CI or human.

### 11. Notifications
Not applicable — exit code, stdout, and the generated JSON are the only
signalling mechanisms.

### 12. Audit and logging
Each receipts.json section records its own provenance (generated_at, source
tag, producing command) — the receipt IS the audit trail. No additional log.

### 13. Solution variabilities
- Evidence source list (config) — hardcoded to the 4 current sources;
  extensible by adding a reader per new source.
- source enum (fixed) — measured|estimated|backfilled|absent, shared with
  e40's OKF vocabulary.

### 14. Quality attributes *NFR*
- Wall-clock: seconds (local file reads only, no network).
- Deterministic: same artifacts on disk → same receipts.json (modulo
  generated_at timestamps).
- Idempotent: safe to re-run; overwrites specs/receipts.json in place.

### 15. Security and compliance *NFR*
- Reads local files only — no secrets, no network access.
- Honesty guarantee: the script never invents a value. A section without a
  real measured artifact is tagged `source: absent` with no value field —
  fabricating or defaulting a number is a defect, not a fallback.

### 16. UX and accessibility *NFR*
Not applicable — CLI script producing machine-readable JSON.

### 17. Acceptance criteria
Scenario: All evidence sources present (happy path)
  Given a repo checkout with compliance, golden-suite, metrics, and
        traceability artifacts in their canonical locations
  When  bash scripts/build-receipts.sh runs
  Then  it emits specs/receipts.json with one section per evidence source
        (compliance, golden_suite, metrics, traceability)
  And   each section carries value, generated_at, source enum
        (measured|estimated|backfilled|absent), and the command that
        produced it
  And   the script exits 0

Scenario: Missing evidence artifact degrades to absent (6a)
  Given an evidence source whose artifact is missing (e.g. no
        traceability-matrix.json yet)
  When  bash scripts/build-receipts.sh runs
  Then  that section is emitted with source: absent and no value field
  And   the script still exits 0 — missing evidence is a state, not an error

### 18. Out of scope
- Rendering the receipts page (e41s02).
- CI wiring (e41s03).
- Validating receipts.json conformance (e41s04 extends validate-okf.sh).
- Generating the underlying evidence itself (owned by e31/e37/e38/e40).

### 19. Open questions
- Exact canonical filenames for e37 golden reports and e38 traceability
  matrix depend on those epics landing (soft dependencies); until then the
  reader treats their expected paths as absent. Confirm paths when e37/e38
  merge.

### 20. References
- specs/epics/e41-public-receipts/epic.yaml (source change request and
  graceful-degradation design rule).
- specs/epics/e40-metrics-integrity/ (OKF bundle format and source enum).
- scripts/validate-okf.sh (e40s06 validator extended in e41s04).
- specs/CHANGE-REQUEST-e40-metrics-integrity.md (provenance rules).
