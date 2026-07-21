---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e53s04
TITLE:     Adopt docs/TARGET-ARCHITECTURE.md as the migration's north-star reference
TYPE:      Enabler
PARENT:    e53
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      M   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

Two separate bodies of work currently define bigpowers' migration target: bigspec's own
`constitution.md` + `architecture.md` (the overall methodology target), and this session's
wayfinder documentation-architecture work (24 tickets, 26 template artifacts, the big-docs
3-wave model, the specs/→docs/ dissolution decision). Nothing ties them together as a single
cited reference — every later migration epic (e54-e59) would otherwise have to re-derive the
target shape from scratch or guess which source is authoritative for what.

### 2. Value statement [draft]

As every later migration epic (e54-e59), I want a single `docs/TARGET-ARCHITECTURE.md` that
routes to both source bodies of work, so that I can cite one reference instead of re-deriving
the target shape each time.

### 3. Actors and permissions [draft]

- Later migration epic authors (internal) — read and cite this doc.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up during e53's build phase, as the last of the 4.
Precondition: bigspec's `constitution.md` (139 lines) and `architecture.md` (326 lines) exist
at the bigspec repo; the wayfinder session's 26 template artifacts exist at
`specs/wayfinder/doc-templates/templates/`.

### 5. Main flow and business logic [draft]

1. Write `docs/TARGET-ARCHITECTURE.md`, summarizing — not copying verbatim — bigspec's
   `constitution.md` (B0-B10 + Capstone) and `architecture.md`, with clear provenance (source
   repo, commit, date) for each summary.
2. Add a Documentation Architecture section summarizing big-docs' 3-wave model (Wave 1
   GitHub-native, Wave 2 GoodDocs `docs/`, Wave 3 Specs) and the specs/→docs/ dissolution
   decision from the wayfinder session's T6 amendment.
3. Add a pointer to the template/schema artifacts at
   `specs/wayfinder/doc-templates/templates/` as the adopted target shape for every document
   type — link and summarize, do not re-derive or duplicate their content.
4. Confirm the result reads as a router — summarizing and linking to sources, not reproducing
   them at length.

Interruption point: N/A — a single authoring pass.

### 6. Alternative flows and exceptions [draft]

6a. bigspec's `constitution.md` or `architecture.md` changes after this doc is written — the
provenance note (source commit) lets a reader detect staleness; this story does not set up an
automated sync.
6b. A future ticket adds another template beyond the current set — this doc's pointer to the
templates directory (not an enumerated list) means it doesn't need updating for every new
template.

### 7. Interface elements [draft]

Not applicable — a markdown document, no UI.

### 8. Domain model [draft]

Entities touched: none. Artifact produced: `docs/TARGET-ARCHITECTURE.md`.

### 9. Integrations and boundaries [draft]

- bigspec's `constitution.md` / `architecture.md` (ethereal, direction: in — a point-in-time
  summary, not a live sync).
- `specs/wayfinder/doc-templates/templates/` (perennial, direction: in — a link, so it stays
  current as templates are added).

### 10. Background processes [draft]

Not applicable.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The document's provenance note (source repo, commit, date) is its own audit trail.

### 13. Solution variabilities [draft]

Not applicable.

### 14. Quality attributes *NFR* [draft]

Not applicable — a static document has no runtime performance dimension.

### 15. Security and compliance *NFR* [draft]

Not applicable — no secrets or PII; bigspec and the wayfinder session's outputs are already
internal-accessible references.

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: TARGET-ARCHITECTURE.md exists and incorporates both sources
  Given bigspec's constitution.md + architecture.md and the wayfinder session's template
        artifacts all exist but nothing ties them together
  When  this story completes
  Then  docs/TARGET-ARCHITECTURE.md exists and summarizes both sources with provenance

Scenario: the doc is a router, not a restatement
  Given docs/TARGET-ARCHITECTURE.md is written
  When  its content is reviewed
  Then  it links to and summarizes its sources rather than duplicating them verbatim
```

### 18. Out of scope [draft]

- Modifying bigspec's own files — this story only summarizes and cites them.
- Enumerating every individual template by name — the doc points at the `templates/` directory,
  it doesn't restate each one's contents.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e53-establish-migration-baseline/epic.yaml`) — e53s04 AC block.
- `specs/wayfinder/doc-templates/MAP.md`.
