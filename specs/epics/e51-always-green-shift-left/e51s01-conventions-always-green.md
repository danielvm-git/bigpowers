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

### 17. Acceptance criteria (Gherkin)
```gherkin
Scenario: Agent reads discovered defect rules
  Given CONVENTIONS.md includes § Always Green
  When an agent encounters a red Preflight or test gate
  Then it must run quick-fix or fix-bug
  And it must not use banned dismissive phrases
```
