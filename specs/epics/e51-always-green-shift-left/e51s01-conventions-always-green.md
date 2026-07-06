<!-- story: e51s01 -->
STORY KEY: E51-S01
TITLE:     CONVENTIONS — Always Green, Shift Left, Discovered Defects, banned phrases
TYPE:      Story
PARENT:    e51
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-06
MATURITY:  3
SIZE:      S

### 1. Business narrative
Solo developers using bigpowers report agents dismissing reproducible failures as
"pre-existing" or "outside this session." CONVENTIONS.md must encode Always Green
(Shift Left) as operational law with banned phrases and fix-or-log routing.

### 2. Value statement
As a solo developer, I want CONVENTIONS to forbid defect dismissal, so agents fix or
log every reproducible failure immediately.

### 12. Seeded project migration note
Existing projects seeded before e51 will **not** receive CONVENTIONS updates automatically.
Owners must either:
- Re-run `seed-conventions` on a branch and merge the Always Green sections, or
- Manually copy § Always Green and § Discovered Defects from bigpowers `CONVENTIONS.md`, or
- Run `migrate-version` when a migration step ships (future).

Document this note inside CONVENTIONS § Always Green as a one-line "Existing projects" callout.

### 17. Acceptance criteria (Gherkin)
```gherkin
Scenario: Agent reads discovered defect rules
  Given CONVENTIONS.md includes § Always Green
  When an agent encounters a red Preflight or test gate
  Then it must run quick-fix or fix-bug
  And it must not use banned dismissive phrases
```
