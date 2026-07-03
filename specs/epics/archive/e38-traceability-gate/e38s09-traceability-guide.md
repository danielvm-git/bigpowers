STORY KEY: E38-S09
TITLE:     Write docs/references/traceability-gate.md — architecture & operator guide
TYPE:      Story
PARENT:    e38
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The e38 traceability system has four components (matrix builder, blind-spot
detector, gate skill, CI integration) but no single document explaining how
they fit together. An operator encountering a FAIL verdict needs to understand
what to fix. A new maintainer needs to understand the architecture. The
traceability-gate.md reference doc explains the three-tier architecture
(matrix → blind-spots → gate), the oracle resolution tiers, the heuristic
blind-spot catalog, the gate decision rules, CI/CD integration points, and
how to interpret or override results.

### 2. Value statement
As an operator responding to a gate-trace FAIL, I want a single document
explaining what each component does and how to resolve findings, so I can
fix traceability gaps without reverse-engineering the pipeline.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/traceability-gate.md.
Precondition: all e38 components specified (s01-s08).

### 5. Main flow and business logic
1. Document three-tier architecture: trace-stories.sh (matrix) → check-blind-spots.sh (detector) → gate-trace (decision).
2. Document oracle resolution tiers: story tags (high confidence) → file-name heuristics (medium) → epic capsule task refs (low).
3. Catalog all 6 heuristic blind-spot checks with descriptions and severity.
4. Document gate decision rules (PASS/CONCERNS/FAIL/WAIVED) with oracle downgrade.
5. Document CI/CD integration points (sync-skills.yml, release-branch, verify-work).
6. Document how to interpret results and how to override CONCERNS.
7. Include provenance: market survey date (2026-07-02), TEA inspiration, article reference.

### 6-16. Not applicable (standard reference doc creation pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  GIVEN no existing traceability-gate.md
  WHEN the doc is created
  THEN test -f docs/references/traceability-gate.md exits 0
  AND grep -q 'TEA|oracle confidence|blind-spot' docs/references/traceability-gate.md exits 0
  AND the doc covers architecture, oracle tiers, blind-spot catalog,
      gate rules, CI/CD integration, and override instructions

### 18. Out of scope
- Updating the market survey with new tools discovered after 2026-07-02.
- Creating an interactive dashboard for traceability (deferred to visual-dashboard).

### 19. Open questions
- Should this doc live in specs/ or docs/references/? docs/references/ — it's
  a reference for operators, not a spec artifact for the planning pipeline.

### 20. References
- scripts/trace-stories.sh (e38s01).
- scripts/check-blind-spots.sh (e38s04).
- skills/gate-trace/SKILL.md (e38s06).
- BMAD TEA traceability approach (market survey 2026-07-02).
- "The Agentic Coding Stack" article (Murat Aslan, 2026).
