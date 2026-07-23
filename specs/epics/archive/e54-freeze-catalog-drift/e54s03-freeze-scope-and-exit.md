---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-release"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e54s03
TITLE:     Document the freeze's scope, exit criteria, and exception process
TYPE:      Enabler
PARENT:    e54
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      XS   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

e54s01 and e54s02 build the mechanics of a freeze (baseline + drift warning), but neither
states, in a place a contributor would actually read, what the freeze covers, when it ends, or
how to make a legitimate change during it without fighting the gate every time. Without this,
the freeze either gets silently ignored (warnings pile up, nobody acts) or becomes an
unexplained annoyance (a contributor sees a WARNING with no context for what to do about it).

### 2. Value statement [draft]

As a contributor working during the freeze window, I want a documented scope, exit condition,
and exception process, so that a WARNING from e54s02's gate tells me exactly what happened and
what to do next, instead of leaving me to guess.

### 3. Actors and permissions [draft]

- Any contributor (internal) — reads this section when they hit a drift warning.
- Repo maintainer (internal) — the one who ultimately declares the freeze over.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up as e54's third and final story, once e54s01/e54s02 exist to
document.
Precondition: no documented freeze scope, exit criteria, or exception process exists anywhere
in CONVENTIONS.md or CLAUDE.md today.

### 5. Main flow and business logic [draft]

1. Add a "Catalog Freeze (e54-e59 migration)" section to CONVENTIONS.md stating: what's frozen
   (new skill additions, structural SKILL.md changes to phase/effort/model), what's NOT frozen
   (bug fixes, description edits, content fixes within an existing skill's existing shape).
2. State the exit criterion explicitly: the freeze ends when e56 (reclassify-catalog) merges —
   its own completion is the unfreeze event, not a calendar date.
3. Document the exception marker convention e54s02 checks for (e.g. a `<!-- freeze-exception:
   <reason> -->` comment in the affected SKILL.md, or a commit trailer) and when it's
   appropriate to use one.

Interruption point: N/A — a single documentation addition.

### 6. Alternative flows and exceptions [draft]

6a. The freeze needs to be lifted early for an unrelated urgent reason (e.g. a security fix
requiring a new skill) — the documented exception process covers this; no separate emergency
procedure is invented here.

### 7. Interface elements [draft]

Not applicable — documentation only.

### 8. Domain model [draft]

Not applicable — no data model; this is prose documentation.

### 9. Integrations and boundaries [draft]

- e54s02's drift-detection gate (perennial, direction: out) — this story's exception-marker
  convention is what that gate's suppression logic reads.

### 10. Background processes [draft]

Not applicable.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

Not applicable — the CONVENTIONS.md edit itself, via git history, is the record.

### 13. Solution variabilities [draft]

Not applicable.

### 14. Quality attributes *NFR* [draft]

Not applicable — documentation has no runtime performance dimension.

### 15. Security and compliance *NFR* [draft]

Not applicable.

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: freeze scope and exit criteria are documented
  Given no freeze documentation exists today
  When  this story completes
  Then  CONVENTIONS.md states what's frozen, what's not, and that e56's completion ends it

Scenario: the exception marker convention is documented
  Given e54s02's gate checks for an exception marker but nothing explains its format
  When  this story completes
  Then  CONVENTIONS.md documents the exact marker format and when to use it
```

### 18. Out of scope [draft]

- Building the exception-marker detection itself — that's e54s02's job. This story documents
  the convention e54s02 already implements.
- Actually lifting the freeze — that's e56's own completion event, not an action this story
  performs.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e54-freeze-catalog-drift/epic.yaml`) — e54s03 AC block.
- `e54s02-drift-detection-gate.md` — the gate whose exception marker this story documents.

---

## Requirement deltas (plan-work, e45s29)

#### ADDED: a documented Catalog Freeze section in CONVENTIONS.md
A new "Catalog Freeze (e54-e59 migration)" section states what is frozen, what is not, the exit
criterion (e56's completion), and the exception-marker format. Purely additive documentation —
no existing CONVENTIONS.md rule is changed, so there is no before/after behavior to record. The
only cross-artifact contract is that the exception-marker string here must match byte-for-byte
what e54s02's `check-catalog-drift.sh` greps for (enforced by this story's task 2).
