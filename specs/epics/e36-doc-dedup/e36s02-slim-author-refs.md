STORY KEY: E36-S02
TITLE:     Slim docs/references/akita.md, ousterhout.md, karpathy.md, wasowski.md to provenance pointers
TYPE:      Story
PARENT:    e36
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
Four author reference docs — akita.md, ousterhout.md, karpathy.md,
wasowski.md — restate the core concepts of their sources (agentic
readability heuristics, deep modules, think-first/surgical-change habits,
SDD/BDD linkage). The same ideas are codified as enforceable rules in
CONVENTIONS.md and operationalized in skills (design-interface,
develop-tdd, elaborate-spec). Restated concepts drift from the codified
rules and cost duplicate context on every agent read. Applying the same
thin-provenance conversion as e36s01 across all four files closes the
remaining author-doc duplication in docs/references/.

### 2. Value statement
As a maintainer, I want the four author reference docs to be thin
provenance pointers (source, author, pointers to where each concept is
codified), so that each principle has exactly one authoritative statement.

### 3. Actors and permissions
- Maintainer (internal) — edits the four docs and runs the verify command.
- Agents (system) — read CONVENTIONS.md/skills for rules and these docs only for provenance.

### 4. Trigger and preconditions
Trigger: manual (epic e36 build cycle), after e36s01 establishes the
pointer format on uncle-bob.md.
Precondition: the concepts each doc restates are traceable to a codified
home (CONVENTIONS.md section or a skill's SKILL.md).

### 5. Main flow and business logic
1. For each of the four files, list its concept bullets and locate the
   codified counterpart (CONVENTIONS.md section or skill).
2. Rewrite each file in the pointer format established by e36s01: title,
   Source, Author, one pointer line per concept destination.
3. Keep each file at 30 lines or fewer (epic verify flags files > 30 lines).
4. Run the epic verify loop over all four files; it must print OK.
Interruption point: files are independent; the story can pause between files.

### 6. Alternative flows and exceptions
6a. A concept has no codified counterpart — keep the pointer to the external
    source only; do not expand CONVENTIONS.md (out of scope), flag in the PR.
6b. One file exceeds 30 lines after rewrite — the epic verify prints
    "FAIL: <name> still long"; trim until it passes.
6c. Source URL dead or moved — keep the original citation and note the
    access date; provenance is historical, not a live link contract.

### 7. Interface elements
Context: existing (four files under docs/references/).
Static elements: Source and Author lines preserved verbatim in each file.
Dynamic elements: pointer lines mapping concepts to their codified homes.

### 8. Domain model
Entities read: docs/references/{akita,ousterhout,karpathy,wasowski}.md,
CONVENTIONS.md, related SKILL.md files (read-only, for pointer targets).
Entities written: the four reference docs only.

### 9. Integrations and boundaries
- CONVENTIONS.md (perennial, direction: in) — primary pointer target.
- Skills citing these docs, e.g. design-interface cites Ousterhout
  (direction: out) — unaffected; file paths are unchanged.

### 10. Background processes
Not applicable — one-shot documentation edit.

### 11. Notifications
Not applicable — reviewed via normal PR flow.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Line budget (config) — 30 lines per file, fixed by the epic verify command.
- Pointer format — reuse the format landed in e36s01 for consistency.

### 14. Quality attributes *NFR*
- Each of the four files ≤ 30 lines (deterministic, checked by verify command).
- Zero information loss: every removed concept keeps a pointer to its codified home or source.

### 15. Security and compliance *NFR*
Not applicable — documentation-only change, no code, secrets, or network access.

### 16. UX and accessibility *NFR*
Not applicable — internal reference docs consumed by agents and maintainers.

### 17. Acceptance criteria
Scenario: All four files slimmed (happy path)
  Given e36s01 has established the provenance pointer format
  When  akita.md, ousterhout.md, karpathy.md, and wasowski.md are rewritten as pointers
  Then  the epic verify loop reports no "FAIL: <name> still long" line
  And   prints OK

Scenario: Provenance preserved per file
  Given the four files have been slimmed
  When  each file is read
  Then  its Source line still cites the original article, book, or repository
  And   its Author line still names the original author

Scenario: One file still too long (6b)
  Given karpathy.md is 35 lines after rewrite
  When  the epic verify loop runs
  Then  it prints "FAIL: karpathy still long"

Scenario: Concept without codified home (6a)
  Given a concept bullet has no CONVENTIONS.md or skill counterpart
  When  the file is rewritten
  Then  the concept keeps only its pointer to the external source
  And   the gap is flagged in the PR description

### 18. Out of scope
- uncle-bob.md (covered by e36s01).
- spec-kit.md and other tool-landscape docs (covered by e36s04).
- Extending CONVENTIONS.md or any SKILL.md to absorb orphan concepts.

### 19. Open questions
- All four files are currently 9-10 lines, so the epic verify (≤ 30 lines)
  already passes before any work; the substantive change is replacing
  restated concept text with pointers, mirroring e36s01 §19.

### 20. References
- specs/epics/e36-doc-dedup/epic.yaml (story e36s02).
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.5 (epic source).
- specs/epics/e36-doc-dedup/e36s01-slim-uncle-bob.md (pointer format precedent).
- specs/IMPACT-e38-okf-adoption.md (thin-provenance pointer pattern).
