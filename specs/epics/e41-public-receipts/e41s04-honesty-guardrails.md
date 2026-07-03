STORY KEY: E41-S04
TITLE:     Honesty guardrails codified — validate-okf checks receipts.json source tags
TYPE:      Story
PARENT:    e41
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The receipts page (e41s02) exists to prove bigpowers' discipline, not claim it.
But receipts.json is machine-generated — a bug in build-receipts.sh could emit
a section with a value but tag it "absent", or tag it "measured" but with no
actual measurement. Without a conformance check, the page could silently display
fabricated or contradictory data. The e40 validate-okf.sh provenance gate checks
that generators ran and commit ranges resolve; this story extends it to cover
receipts.json, adding a semantic gate: every section must carry a source tag,
and no section tagged "absent" may carry a value. Violations fail with a
remediation hint naming the offending section.

### 2. Value statement
As a site visitor, I want assurance that the receipts page is honest — that
"measured" means measured, and "absent" means genuinely unavailable — so I can
trust the evidence this methodology publishes about itself.

### 3. Actors and permissions
- CI runner (system) — runs validate-okf.sh in pipeline.
- Skill maintainer (internal) — extends validate-okf.sh.

### 4. Trigger and preconditions
Trigger: validate-okf.sh invocation (manual or CI).
Precondition: receipts.json exists at specs/receipts.json.
Precondition: e40s06 validate-okf.sh exists as the base to extend.

### 5. Main flow and business logic
1. validate-okf.sh reads receipts.json.
2. For each evidence section (compliance, golden_suite, metrics, traceability):
   a. Assert section has a `source` tag (measured|estimated|backfilled|absent).
   b. If source == "absent", assert no `value` field exists.
   c. If source != "absent", assert a `value` field exists.
3. Report validation result: PASS or FAIL with per-section findings.
4. On FAIL, emit remediation hint: which section, what's wrong, how to fix.

### 6. Alternative flows and exceptions
6a. receipts.json not found — exit 0 with warning (not an error: page not yet built).
6b. Unknown source tag value — FAIL with hint listing valid enum values.
6c. Missing required section (compliance/golden_suite/metrics/traceability) — WARN.

### 7. Interface elements
Context: extension of existing validate-okf.sh.
Static elements: receipts.json conformance rules.
Dynamic elements: per-section PASS/FAIL with remediation hints.

### 8. Domain model
Entities read: specs/receipts.json (evidence aggregation).
Entities modified: scripts/validate-okf.sh (extended with receipts checks).

### 9. Integrations and boundaries
- e40s06 validate-okf.sh (direction: in) — base script to extend.
- e41s01 build-receipts.sh (direction: in) — produces receipts.json.
- docs-site CI workflow (direction: out) — consumer of validate-okf.sh results.

### 10. Background processes
Not applicable — synchronous validation script.

### 11. Notifications
Not applicable — exit code and stdout are the signalling mechanism.

### 12. Audit and logging
- Validation results written to stdout with per-section detail.
- CI run logs capture the validation output.

### 13. Solution variabilities
- Required section list (config) — currently [compliance, golden_suite, metrics, traceability].
- Strictness (config) — currently FAIL on semantic violation; could add WARN mode.

### 14. Quality attributes *NFR*
- Execution time: < 1 second (reads one JSON file + applies rules).
- Deterministic: same receipts.json → same validation result every run.

### 15. Security and compliance *NFR*
- Read-only — no modifications to receipts.json or any data file.
- No network access required.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by CI and maintainers.

### 17. Acceptance criteria
Scenario: Valid receipts.json (happy path)
  GIVEN a receipts.json where every section has a valid source tag
  AND no section tagged "absent" carries a value
  WHEN bash scripts/validate-okf.sh runs
  THEN it exits 0
  AND reports "receipts.json: PASS"

Scenario: Section missing source tag (violation)
  GIVEN a receipts.json where the compliance section lacks a source tag
  WHEN bash scripts/validate-okf.sh runs
  THEN it exits 1
  AND reports "compliance: missing source tag — must be measured|estimated|backfilled|absent"

Scenario: Absent section has value (violation)
  GIVEN a receipts.json where golden_suite is tagged "absent" but carries a value
  WHEN bash scripts/validate-okf.sh runs
  THEN it exits 1
  AND reports "golden_suite: tagged absent but carries a value"

Scenario: receipts.json not found (6a)
  GIVEN specs/receipts.json does not exist
  WHEN bash scripts/validate-okf.sh runs
  THEN it exits 0 with warning "receipts.json not found — skipping"

### 18. Out of scope
- Validating the accuracy of measured values (provenance gate only, per e40).
- Adding receipts checks to other validation scripts.
- Creating receipts.json if it doesn't exist.

### 19. Open questions
- Should validate-okf.sh also check that the generated_at timestamp in
  receipts.json is within an acceptable freshness window? Deferred: the
  CI workflow ensures regeneration on every push, so staleness is not
  a concern in the current design.

### 20. References
- specs/epics/e41-public-receipts/epic.yaml (parent epic, honesty guardrails).
- scripts/validate-okf.sh (base script, created by e40s06).
- scripts/build-receipts.sh (generator, created by e41s01).
- specs/templates/story-metrics.okf.md (e40 provenance gate pattern).
