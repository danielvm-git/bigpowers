STORY KEY: E38-S01
TITLE:     Create scripts/trace-stories.sh — deterministic coverage matrix builder
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
bigpowers tracks stories in specs/release-plan.yaml and specs/execution-status.yaml,
and code carries `story: eNNsNN` tags, but nothing deterministically cross-references
the two. The existing trace-requirement skill is agent-driven and fragile: results vary
by run and cannot gate CI. The market survey (spec-kit V-Model build-matrix.sh, BMAD
TEA) shows the missing link is a deterministic matrix builder. Without it, dark stories
(planned but never implemented), orphan tags (code tagged for unknown stories), and
stale tags escape detection until a human audits by hand.

### 2. Value statement
As a maintainer, I want a deterministic script that builds a spec-to-code coverage
matrix, so that story coverage is machine-verifiable and can gate CI instead of
relying on ad-hoc agent grepping.

### 3. Actors and permissions
- Maintainer (internal) — runs the script locally.
- CI runner (system) — executes the script with --strict in GitHub Actions (e38s03).
- build-epic skill (agent) — invokes the script in Step 8 (e38s02).

### 4. Trigger and preconditions
Trigger: manual (`bash scripts/trace-stories.sh`) or via build-epic Step 8 / CI.
Preconditions: specs/release-plan.yaml and specs/execution-status.yaml exist and
parse; repository is a git checkout (grep scope is the working tree).

### 5. Main flow and business logic
1. Parse specs/release-plan.yaml + specs/execution-status.yaml → story inventory
   (id, title, status, bcp, epic).
2. Grep the codebase for `story: eNNsNN` tags → tag inventory (file, line, story id).
3. Resolve each story through the oracle tiers, recording confidence:
   - Tier 1: explicit story tag found → confidence high.
   - Tier 2: file-name heuristic match (slug/keyword from story title) → confidence medium.
   - Tier 3: epic capsule task reference (eNNsMM-tasks.yaml verify paths) → confidence low.
4. Cross-reference → coverage matrix; classify findings: dark story (no code at any
   tier), orphan tag (tag with no matching story), stale tag (story done in
   execution-status but tag still present with no linked change).
5. Emit three artifacts:
   - specs/traceability-matrix.json — machine-readable matrix for CI/CD.
   - specs/TRACEABILITY_LATEST.md — human-readable report.
   - specs/codebase-wiki/ — OKF-conformant bundle (one `type: Story` concept per
     story with YAML frontmatter: implementation_status, coverage_status, bcps,
     confidence; relative links only; no okf_version field; index.md entry point),
     per specs/IMPACT-e38-okf-adoption.md Phase 1 pilot. Existing artifacts remain
     the authority; the OKF bundle is a derived view.
6. --strict flag: exit non-zero if any P0 story has 0% code coverage; exit 0 otherwise.
Interruption point: N/A (script runs to completion in seconds).

### 6. Alternative flows and exceptions
6a. release-plan.yaml or execution-status.yaml missing/unparseable — report which
    file, exit 1.
6b. No story tags found anywhere — matrix still emitted; all stories dark; --strict
    exits non-zero if any dark story is P0.
6c. Orphan tag (tag references unknown story id) — listed in matrix under
    orphan_tags; does not fail non-strict runs.
6d. --help — print usage, exit 0 (probed by the epic verify command).

### 7. Interface elements
Context: new (standalone bash script).
Static elements: --help, --strict, --json flags; exit codes 0/1.
Dynamic elements: per-story coverage rows, confidence labels (high/medium/low),
finding lists (dark/orphan/stale).

### 8. Domain model
Entities read: specs/release-plan.yaml (story inventory), specs/execution-status.yaml
(story status), codebase story tags.
Entities written: specs/traceability-matrix.json, specs/TRACEABILITY_LATEST.md,
specs/codebase-wiki/ OKF concepts (derived views only).

### 9. Integrations and boundaries
- trace-requirement skill (perennial, direction: in) — this script is its
  deterministic replacement for matrix building.
- check-blind-spots.sh (e38s04, direction: out) — consumes the matrix.
- gate-trace skill (e38s06, direction: out) — consumes matrix + OKF frontmatter.
- CI sync-skills.yml (e38s03, direction: out) — runs --strict on push.

### 10. Background processes
Not applicable — invoked synchronously by CI, skills, or human.

### 11. Notifications
Not applicable — exit code, stdout, and emitted files are the only signalling.

### 12. Audit and logging
The emitted matrix carries a generated-at timestamp and oracle-tier provenance per
link, making every trace decision auditable. No separate log file.

### 13. Solution variabilities
- Tag pattern (config) — default `story: eNNsNN`; kept as a single grep variable.
- P0 definition (config) — stories in the active release with highest WSJF band;
  resolvable from release-plan.yaml.
- OKF output directory (config) — default specs/codebase-wiki/.

### 14. Quality attributes *NFR*
- Deterministic: same working tree → byte-identical matrix (modulo timestamp).
- Wall-clock: < 5 seconds on this repo (grep + YAML parse only, no network).
- No runtime dependencies beyond bash, grep, and python3 (for YAML/JSON).

### 15. Security and compliance *NFR*
- Writes only inside specs/ — never modifies code, skills, or CI files.
- No secrets, no network access; safe in read-mostly CI contexts.

### 16. UX and accessibility *NFR*
Not applicable — CLI script consumed by CI, skills, and maintainers.

### 17. Acceptance criteria
Scenario: Full matrix on a tagged repo (happy path)
  Given release-plan.yaml lists stories and code carries story tags
  When  trace-stories.sh is executed
  Then  it exits 0
  And   specs/traceability-matrix.json exists and parses as JSON
  And   specs/TRACEABILITY_LATEST.md lists every story with a confidence label
  And   specs/codebase-wiki/ contains one concept per story with parseable
        frontmatter and a non-empty type field

Scenario: Oracle confidence tiers recorded
  Given a story with an explicit tag and a story matched only by file-name heuristic
  When  trace-stories.sh is executed
  Then  the tagged story's links carry confidence "high"
  And   the heuristic story's links carry confidence "medium"

Scenario: Dark story flagged
  Given a story present in release-plan.yaml with no tag, heuristic, or task match
  When  trace-stories.sh is executed
  Then  the story appears under dark_stories in the matrix

Scenario: Strict mode fails on uncovered P0 (6b)
  Given a P0 story with 0% code coverage
  When  trace-stories.sh --strict is executed
  Then  it exits non-zero
  And   reports the uncovered P0 story id

Scenario: Missing input file (6a)
  Given specs/release-plan.yaml does not exist
  When  trace-stories.sh is executed
  Then  it exits 1
  And   reports "release-plan.yaml: not found"

Scenario: Help flag (6d)
  Given any repository state
  When  trace-stories.sh --help is executed
  Then  it exits 0 and prints usage

### 18. Out of scope
- Blind-spot heuristics beyond dark/orphan/stale (e38s04's job).
- Gate decisions PASS/CONCERNS/FAIL (e38s06's job).
- CI wiring (e38s03's job).
- Decomposing CONVENTIONS.md or skills into OKF (later OKF phases, not this pilot).

### 19. Open questions
- Exact P0 band boundary (top WSJF quartile vs. explicit priority field) — resolve
  during implementation against release-plan.yaml's actual schema.

### 20. References
- specs/epics/e38-traceability-gate/epic.yaml (source description).
- specs/IMPACT-e38-okf-adoption.md (OKF-conformant output decision, Phase 1 pilot).
- skills/trace-requirement/SKILL.md (current fragile approach being replaced).
- BMAD TEA oracle fallback + spec-kit V-Model build-matrix.sh (market survey, epic source).
