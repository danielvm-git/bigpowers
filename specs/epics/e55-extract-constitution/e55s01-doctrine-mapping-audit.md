---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-23T19:03:39Z
supersedes: null
commit_range: null
---

```
STORY KEY: e55s01
TITLE:     Map every current doctrine source to a B0-B10 + Capstone block
TYPE:      Enabler
PARENT:    e55
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-23
MATURITY:  4
SIZE:      S   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

bigpowers states its own rules across ~49 scattered files today: `CLAUDE.md`,
`CONVENTIONS.md`, `docs/PRINCIPLES.md`, and 46 `docs/references/*.md` files. The same
rule is often restated in more than one of them, so they drift — a rule updated in
one file stays stale in another, and no single file is authoritative. Before
`constitution.md` can be written (e55s02), there must be a complete, explicit map of
every current rule to exactly one of bigspec's 11 blocks (B0-B10) or the Capstone —
without that map, the next story risks silently dropping a rule, duplicating one, or
inventing content that isn't actually in the current doctrine.

### 2. Value statement [draft]

As e55s02 (which writes `constitution.md`) and as future maintainers reviewing the
migration, I want a complete, traceable mapping of every current doctrine rule to
exactly one B0-B10 + Capstone block, so that the constitution's content has a clear
source and no rule is silently dropped, duplicated, or invented.

### 3. Actors and permissions [draft]

- e55s02 (internal) — consumes this mapping as its direct content source.
- Repo maintainer (internal) — reviews the mapping for completeness/accuracy before
  e55s02 proceeds.

### 4. Trigger and preconditions [draft]

Trigger: picked up as e55's first story, after epic e54 (dependency) completed.
Precondition: `CLAUDE.md`, `CONVENTIONS.md`, `docs/PRINCIPLES.md`, and 46
`docs/references/*.md` files are the current doctrine sources; no mapping to
bigspec's B0-B10 + Capstone taxonomy exists in this repo yet.

### 5. Main flow and business logic [draft]

1. Enumerate every doctrine source file: `CLAUDE.md`, `CONVENTIONS.md`,
   `docs/PRINCIPLES.md`, all 46 `docs/references/*.md` files (49 files total).
2. For each file, extract each distinct rule or convention it states.
3. Assign each rule to exactly one of bigspec's 11 blocks (B0 Token/Context
   Substrate through B10 Synthesis) or Capstone, using
   `specs/reborn-constitution.md`'s block **definitions** (Part I section headers +
   one-line summaries) as the taxonomy reference only — never its content-level
   claims, since that file targets a hypothetical future rewrite.
4. Write the mapping as `specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md`:
   one section per block (B0-B10, Capstone), each listing the rules assigned to it
   with their source file (and line/section where practical).
5. Flag any rule that doesn't cleanly fit a single block as "unclear — needs a
   decision" rather than force-fitting it.

Interruption point: N/A — a single audit pass, not a resumable multi-step flow.

### 6. Alternative flows and exceptions [draft]

6a. A rule appears in more than one source file (e.g. restated in both
`CONVENTIONS.md` and a `docs/references/*.md` file) — record every source location
for that rule but map it once, explicitly noting the duplication. This is exactly the
kind of drift e55 exists to fix, so duplication findings are a valuable output, not
noise.

6b. A bigspec block (per `reborn-constitution.md`'s definitions) has no current
bigpowers rule that maps to it — record the block as "no current rule maps here"
rather than inventing content to fill it. Per this epic's own constraint, this story
introduces zero new rule content.

### 7. Interface elements [draft]

Not applicable — audit document, no UI surface.

### 8. Domain model [draft]

Entities touched: none (read-only audit). Artifact produced:
`specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md` (one section per
B0-B10 + Capstone block, listing source-file → rule → block assignments).

### 9. Integrations and boundaries [draft]

- `CLAUDE.md`, `CONVENTIONS.md`, `docs/PRINCIPLES.md`, `docs/references/*.md`
  (perennial, direction: in) — read-only audit sources.
- `specs/reborn-constitution.md` (perennial, direction: in) — structural taxonomy
  reference only, not a content source.
- e55s02 (direction: out) — this mapping is that story's direct content input.

### 10. Background processes [draft]

Not applicable — invoked once at story start, not scheduled.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The mapping document itself, plus the commit that lands it, is the audit record.

### 13. Solution variabilities [draft]

Not applicable — one mapping, no per-tenant variation.

### 14. Quality attributes *NFR* [draft]

- The mapping must cover 100% of the 49 source files — no file silently skipped.

### 15. Security and compliance *NFR* [draft]

Not applicable — first-party, already-public doctrine content; see
`specs/security/epics/e55/THREAT_MODEL.md` (PASS, no attacker-reachable surface).

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: mapping covers every doctrine source file
  Given CLAUDE.md, CONVENTIONS.md, docs/PRINCIPLES.md, and 46 docs/references/*.md
        files exist
  When  e55s01-doctrine-mapping.md is produced
  Then  every one of the 49 source files appears at least once as a mapping source,
        and all 12 blocks (B0-B10 + Capstone) are represented or explicitly marked
        "no current rule maps here"

Scenario: no forward-dated concepts leak in as if already true (out-of-scope guard)
  Given specs/reborn-constitution.md contains e57/e58/e59 concepts (a
        constitution_version scheme, a universal "every file is an OKF bundle"
        claim, a count-bcp skill/kernel module)
  When  the mapping is written
  Then  none of those terms appear in e55s01-doctrine-mapping.md as already-true
        content of the current repo
```

### 18. Out of scope [draft]

- Writing `constitution.md` itself — that is e55s02's job. This story only produces
  the mapping it will be built from.
- Changing any rule's content or meaning — reorganization only.
- Deciding CLAUDE.md/CONVENTIONS.md cross-references — that is e55s03's job.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e55-extract-constitution/epic.yaml`) — e55s01 planned-story entry.
- `planning-context.yaml` (`specs/epics/e55-extract-constitution/planning-context.yaml`) — elaboration, main_flow step 1.
- `specs/reborn-constitution.md` Part I — B0-B10 + Capstone block definitions (structural reference only).
