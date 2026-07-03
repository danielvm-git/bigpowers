STORY KEY: E36-S04
TITLE:     Update docs/references/spec-kit.md to cover full SDD tool landscape (Kiro, Tessl, BMAD, GSD)
TYPE:      Story
PARENT:    e36
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      S

### 1. Business narrative
docs/references/spec-kit.md currently covers only spec-kit itself, but the
spec-driven development (SDD) tool landscape has expanded significantly:
Kiro (spec-driven code generation), Tessl (AI-native SDD platform), BMAD
(methodology-first approach), GSD (general spec-driven framework), and
bigpowers itself. The e38 market survey identified 5 tools in the traceability
space alone. A single reference doc covering the full landscape — including
how bigpowers relates to each — provides orientation for new users and
prevents scattered, incomplete information across the codebase.

### 2. Value statement
As a new bigpowers user evaluating the SDD tool ecosystem, I want a single
reference doc that maps the competitive landscape, so I can understand where
bigpowers fits without hunting across 5 separate sources.

### 3. Actors and permissions
- Skill maintainer (internal) — edits the reference doc.
- New user (external) — reads the reference doc.

### 4. Trigger and preconditions
Trigger: manual edit of docs/references/spec-kit.md.
Precondition: existing spec-kit.md content is the baseline to expand.

### 5. Main flow and business logic
1. Audit current docs/references/spec-kit.md for existing SDD tool coverage.
2. Research Kiro, Tessl, BMAD, GSD feature sets and differentiators.
3. Add one section per tool: what it does, how it relates to SDD, key differentiators vs bigpowers.
4. Add a comparison matrix summarizing the landscape.
5. Preserve existing spec-kit coverage — expand, don't replace.

### 6. Alternative flows and exceptions
6a. Tool documentation unavailable — note "not independently verified" and link to official source.
6b. Tool overlaps with another reference doc — cross-reference rather than duplicate.

### 7. Interface elements
Context: existing (docs/references/spec-kit.md).
Static elements: per-tool sections, comparison matrix.
Dynamic elements: links to tool documentation (may change over time).

### 8. Domain model
Entities written: docs/references/spec-kit.md (expanded).
Entities referenced: Kiro docs, Tessl docs, BMAD methodology, GSD framework, spec-kit docs.

### 9. Integrations and boundaries
- Other reference docs (direction: none) — spec-kit.md is a standalone reference.
- SKILL.md files (direction: out) — may cross-reference the updated spec-kit.md.

### 10. Background processes
Not applicable — manual documentation edit.

### 11. Notifications
Not applicable — no user-facing alert.

### 12. Audit and logging
Not applicable — git diff serves as the change record.

### 13. Solution variabilities
- Tool list (config) — expandable as new SDD tools emerge.
- Comparison criteria (config) — currently: approach, open-source, agent-native, bigpowers relation.

### 14. Quality attributes *NFR*
- Accuracy: each tool claim cites a primary source (docs, readme, or market survey).
- Currency: add "Last updated: 2026-07-03" footer for freshness tracking.

### 15. Security and compliance *NFR*
- Read-only documentation edit — no code changes, no secrets, no network access required.
- External links are marked as such.

### 16. UX and accessibility *NFR*
- Comparison matrix uses markdown table for readability.
- Per-tool sections are clearly headed for scanning.

### 17. Acceptance criteria
Scenario: Full landscape coverage (happy path)
  Given the existing spec-kit.md as baseline
  When  sections for Kiro, Tessl, BMAD, and GSD are added
  Then  grep -q 'Kiro|Tessl' docs/references/spec-kit.md exits 0
  And   the comparison matrix includes all 5+ tools
  And   each tool section includes: what it does, key differentiator, and
        how bigpowers relates

Scenario: Unavailable tool docs (6a)
  Given a tool's official documentation is inaccessible
  When  the reference doc is compiled
  Then  that tool's section includes "not independently verified" annotation
  And   links to the official source are included

### 18. Out of scope
- Writing a comprehensive competitive analysis (this is a reference doc, not a market report).
- Updating other reference docs to cover SDD tools (keep in spec-kit.md).
- Rating or ranking tools — present features, let the reader decide.

### 19. Open questions
- Should the comparison matrix live in spec-kit.md or become its own reference doc?
  Decision deferred until after initial draft: if the matrix is > 30 lines, split.
- Do BMAD and GSD have sufficient public documentation for a fair section?
  Research-first before writing.

### 20. References
- docs/references/spec-kit.md (existing file).
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.5 (dedup mandate).
- e38 epic.yaml (market survey of 5 traceability tools — analogous landscape survey).
