STORY KEY: E39-S10
TITLE:     Extend scripts/validate-okf.sh (created by e40s06) with OKF v0.1 frontmatter conformance checks
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
e40s06 creates scripts/validate-okf.sh with the metrics provenance gate
(validates story-metrics OKF bundles). This story extends it with a generic
OKF v0.1 conformance layer: every non-reserved .md file has parseable YAML
frontmatter, every frontmatter has a non-empty `type` field, and reserved
filenames (index.md, log.md) follow the spec structure. The extend-not-create
pattern (same as e41s04 for receipts) is intentional: e40 lands before e39 in
the release train order, so the base script exists before this extension.

### 2. Value statement
As a CI operator, I want one validation script that covers both metrics
provenance and OKF conformance, so I don't need separate validation
commands for different bundle types.

### 3. Actors and permissions
- CI runner (system) — runs validate-okf.sh in pipeline.

### 4. Trigger and preconditions
Trigger: validate-okf.sh invocation (manual or CI).
Precondition: e40s06 validate-okf.sh exists with metrics provenance checks.
Precondition: OKF bundles exist at specs/skills-wiki/, conventions-wiki/, agent-guide/.

### 5. Main flow and business logic
1. Extend validate-okf.sh to accept a directory argument (OKF bundle root).
2. For each .md file in the bundle (excluding reserved filenames):
   a. Assert parseable YAML frontmatter.
   b. Assert non-empty `type` field.
3. For reserved filenames (index.md, log.md): assert spec-conformant structure.
4. Combine with existing e40s06 metrics provenance checks.
5. Wire into sync-skills.yml CI as a step (non-blocking initially, blocking after e39s04 generates first bundle).

### 6. Alternative flows and exceptions
6a. No OKF bundles exist yet — skip OKF conformance, run metrics checks only.
6b. validate-okf.sh not found — error (e40s06 must land first per release train order).

### 7-16. Not applicable (standard script extension pattern)

### 17. Acceptance criteria
Scenario: OKF conformance checked
  GIVEN validate-okf.sh exists (e40s06)
  WHEN the OKF v0.1 conformance layer is added
  THEN grep -q 'type' scripts/validate-okf.sh exits 0
  AND bash scripts/validate-okf.sh --help exits 0
  AND the script validates parseable frontmatter and non-empty type fields

### 18. Out of scope
- Creating validate-okf.sh from scratch (that's e40s06).
- Validating OKF content quality (lint is maintain-wiki's job, not validate-okf).

### 19. Open questions
- Should OKF conformance be blocking in CI from day 1 or phased?
  Non-blocking initially; blocking after e39s04 generates the first skills-wiki
  bundle (same phased approach as the IMPACT assessment recommends).

### 20. References
- scripts/validate-okf.sh (e40s06, base script to extend).
- GoogleCloudPlatform/knowledge-catalog SPEC.md §9 (OKF conformance spec).
- specs/IMPACT-e38-okf-adoption.md (phased rollout plan).
