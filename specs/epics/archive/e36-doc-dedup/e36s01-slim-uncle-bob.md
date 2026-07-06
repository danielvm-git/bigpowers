STORY KEY: E36-S01
TITLE:     Slim docs/references/uncle-bob.md to provenance pointer
TYPE:      Story
PARENT:    e36
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-03
MATURITY:  3
SIZE:      M

### 1. Business narrative
docs/references/uncle-bob.md restates Clean Code principles (Boy Scout Rule,
SRP, Intention-Revealing Names, F.I.R.S.T, Small Functions) that are already
codified as enforceable rules in CONVENTIONS.md (e.g. Boy Scout Rule, C5, T4,
T5, T8, "Tests (F.I.R.S.T — Uncle Bob Ch 9)"). Two copies of the same
principle drift independently: when a rule is refined in CONVENTIONS.md the
reference doc silently goes stale, and agents reading both waste context on
duplicated text. e36 converts reference docs from principle restatements to
thin provenance pointers, making CONVENTIONS.md the single source of truth.

### 2. Value statement
As a maintainer, I want uncle-bob.md to be a thin provenance pointer (source,
author, pointer to the CONVENTIONS.md sections it informs), so that Clean Code
principles live in exactly one authoritative place and cannot drift.

### 3. Actors and permissions
- Maintainer (internal) — edits the reference doc and runs the verify command.
- Agents (system) — read CONVENTIONS.md for rules and uncle-bob.md only for provenance.

### 4. Trigger and preconditions
Trigger: manual (epic e36 build cycle).
Precondition: CONVENTIONS.md contains the codified Clean Code rules
(Boy Scout Rule in §Code style, F.I.R.S.T in §Tests) so no principle is lost
when the restatement is removed.

### 5. Main flow and business logic
1. Identify every principle bullet in uncle-bob.md that is restated in CONVENTIONS.md.
2. Rewrite uncle-bob.md as a provenance pointer: title, Source, Author, and a
   one-line pointer per informed section (e.g. "F.I.R.S.T rubric → CONVENTIONS.md §Tests").
3. Keep the file under 20 lines total.
4. Run the story verify: `wc -l docs/references/uncle-bob.md` reports < 20 lines.
Interruption point: N/A (single-file doc edit).

### 6. Alternative flows and exceptions
6a. A principle in uncle-bob.md has no CONVENTIONS.md counterpart — do not
    delete it silently; either add nothing (out of scope to extend
    CONVENTIONS.md) and keep a pointer to the source PDF, or flag it in the PR.
6b. File already under 20 lines but still restating principles — the line
    budget is necessary, not sufficient; restated rubric text must still be
    replaced with pointers.

### 7. Interface elements
Context: existing (docs/references/uncle-bob.md).
Static elements: Source and Author lines (provenance) are preserved verbatim.
Dynamic elements: pointer lines mapping each concept to its CONVENTIONS.md section.

### 8. Domain model
Entities read: docs/references/uncle-bob.md, CONVENTIONS.md (§Code style,
§Tests). Entities written: docs/references/uncle-bob.md only.

### 9. Integrations and boundaries
- CONVENTIONS.md (perennial, direction: in) — the authority the pointer targets.
- Skills that cite uncle-bob.md (direction: out) — unaffected; the file path is unchanged.

### 10. Background processes
Not applicable — one-shot documentation edit.

### 11. Notifications
Not applicable — reviewed via normal PR flow.

### 12. Audit and logging
Not applicable — git history is the audit trail.

### 13. Solution variabilities
- Line budget (config) — hardcoded to < 20 lines by the epic verify command.
- Pointer format — should match the thin-provenance pattern described in
  specs/IMPACT-e38-okf-adoption.md (concept bodies cite sources; authority lives in one place).

### 14. Quality attributes *NFR*
- uncle-bob.md < 20 lines (deterministic, checked by verify command).
- Zero information loss: every removed principle must have a CONVENTIONS.md pointer.

### 15. Security and compliance *NFR*
Not applicable — documentation-only change, no code, secrets, or network access.

### 16. UX and accessibility *NFR*
Not applicable — internal reference doc consumed by agents and maintainers.

### 17. Acceptance criteria
Scenario: File slimmed to provenance pointer (happy path)
  Given CONVENTIONS.md contains the codified Clean Code rules
  When  docs/references/uncle-bob.md is rewritten as a provenance pointer
  Then  `wc -l docs/references/uncle-bob.md` reports fewer than 20 lines
  And   the epic verify prints "OK: slimmed"

Scenario: Provenance preserved
  Given uncle-bob.md has been slimmed
  When  the file is read
  Then  the Source line still cites the Clean Code PDF in ../archive/clean-code-exhibits/
  And   the Author line still names Robert C. Martin

Scenario: No principle restatement remains (6b)
  Given uncle-bob.md has been slimmed
  When  the file is searched for rubric restatements
  Then  the F.I.R.S.T criteria are not spelled out in the file
  And   a pointer to CONVENTIONS.md §Tests is present instead

### 18. Out of scope
- Editing CONVENTIONS.md (it is the untouched authority).
- Slimming any other reference doc (e36s02 covers akita/ousterhout/karpathy/wasowski).
- Updating skills that mention Uncle Bob concepts (e36s03 covers F.I.R.S.T in skills).

### 19. Open questions
- uncle-bob.md is currently 11 lines, so the epic verify (< 20 lines) already
  passes before any work; the substantive change is replacing restated
  principles with pointers, per scenario 6b.

### 20. References
- specs/epics/e36-doc-dedup/epic.yaml (story e36s01).
- specs/DEEPEN-ARCHITECTURE-REVIEW.md §5.5 (epic source).
- CONVENTIONS.md §Tests (F.I.R.S.T — Uncle Bob Ch 9), §Code style (Boy Scout Rule).
- specs/IMPACT-e38-okf-adoption.md (thin-provenance pointer pattern).
