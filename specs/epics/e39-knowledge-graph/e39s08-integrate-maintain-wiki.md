STORY KEY: E39-S08
TITLE:     Integrate maintain-wiki into build-epic Step 8 and verify-work Phase 3
TYPE:      Story
PARENT:    e39
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
maintain-wiki (e39s07) provides ingest, lint, and query operations, but without
integration into the development workflow, it's a manual afterthought. Adding
maintain-wiki INGEST to build-epic Step 8 (after story verification) ensures
every completed story updates the codebase wiki with new concepts and
cross-references. Adding maintain-wiki LINT to verify-work Phase 3 catches
drift and contradictions before they accumulate. Together, these integrations
make wiki maintenance automatic rather than remembered.

### 2. Value statement
As a developer completing a story, I want the knowledge graph to update
automatically, so I don't have to remember to run wiki maintenance as a
separate step.

### 3. Actors and permissions
- build-epic (system) — invokes maintain-wiki INGEST in Step 8.
- verify-work (system) — invokes maintain-wiki LINT in Phase 3.

### 4. Trigger and preconditions
Trigger: build-epic Step 8 execution (INGEST), verify-work Phase 3 execution (LINT).
Precondition: maintain-wiki skill exists (e39s07 complete).

### 5. Main flow and business logic
build-epic Step 8:
1. After story verification and test pass.
2. Invoke maintain-wiki INGEST: update codebase wiki with new story concepts,
   new module concepts, and cross-references.
3. Verify INGEST succeeded (no parse errors in generated OKF concepts).

verify-work Phase 3:
1. After manual verification / UAT.
2. Invoke maintain-wiki LINT: check for drift, contradictions, orphan pages.
3. Surface lint findings in verify-work report.
4. Block PASS gate on lint errors (contradictions are CRITICAL; stale claims are WARNING).

### 6-16. Not applicable (standard integration pattern)

### 17. Acceptance criteria
Scenario: Wiki updated on story completion
  GIVEN build-epic Step 8 is reached
  WHEN maintain-wiki INGEST runs
  THEN the codebase wiki is updated with story concepts
  AND grep -q 'maintain-wiki' skills/build-epic/SKILL.md exits 0

Scenario: Wiki linted during verification
  GIVEN verify-work Phase 3 is reached
  WHEN maintain-wiki LINT runs
  THEN lint findings appear in the verify-work report
  AND grep -q 'maintain-wiki' skills/verify-work/SKILL.md exits 0

### 18. Out of scope
- Adding maintain-wiki to other skills (request-review, audit-code).

### 19. Open questions
- Should LINT be blocking in verify-work (block PASS on CRITICAL) or advisory?
  CRITICAL (contradictions, stale claims on recently-modified files) blocks;
  WARNING (orphans, missing cross-references) is advisory.

### 20. References
- skills/maintain-wiki/SKILL.md (e39s07).
- skills/build-epic/SKILL.md (target for INGEST).
- skills/verify-work/SKILL.md (target for LINT).
