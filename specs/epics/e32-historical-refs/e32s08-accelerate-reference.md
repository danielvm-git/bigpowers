STORY KEY: E32-S08
TITLE:     Create docs/references/accelerate.md (DORA four keys)
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
The DORA four keys (lead time for changes, deployment frequency, change failure
rate, time to restore service) are the industry standard for measuring software
delivery performance. The e40 Metrics Integrity epic builds on DORA to track
honest, additive metrics, and the wire-ci skill references deployment frequency.
Without a canonical reference doc, agents lack a citable source for what DORA
measures and why.

### 2. Value statement
As an agent implementing metrics, I want a canonical reference for DORA four
keys, so my measurement design aligns with the industry standard.

### 3. Actors and permissions
- Documentation maintainer (internal) — writes the reference doc.

### 4. Trigger and preconditions
Trigger: manual creation of docs/references/accelerate.md.
Precondition: none (new file).

### 5. Main flow and business logic
1. Research: Accelerate (Forsgren, Humble, Kim, 2018), DORA State of DevOps reports.
2. Write provenance header: authors, publication, key findings.
3. Define each of the four keys with definitions and how bigpowers computes them (per e40).
4. Cross-reference to e40 Metrics Integrity epic.

### 6-16. Not applicable (standard reference doc pattern)

### 17. Acceptance criteria
Scenario: Reference doc created
  Given no existing accelerate.md
  When  the doc is created with provenance and DORA four keys
  Then  test -f docs/references/accelerate.md exits 0
  And   grep -q 'DORA|four key' docs/references/accelerate.md exits 0

### 18. Out of scope
- Implementing DORA metrics (that is e40).

### 19. Open questions
Not applicable.

### 20. References
- specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md.
- Accelerate (Forsgren, Humble, Kim, 2018).
- specs/RESEARCH-cycle-time-metrics.md (primary-source survey for e40).
