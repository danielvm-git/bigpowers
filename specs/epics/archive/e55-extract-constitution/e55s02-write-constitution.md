---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-23T19:26:51Z
supersedes: null
commit_range: null
---

```
STORY KEY: e55s02
TITLE:     Write constitution.md from the mapping, CLAUDE.md/CONVENTIONS.md unchanged
TYPE:      Enabler
PARENT:    e55
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-23
MATURITY:  4
SIZE:      S   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

e55s01 produced a complete mapping of bigpowers' current doctrine (49 source files)
to bigspec's 11 constitution blocks + Capstone, but a mapping alone isn't a
consolidated source of rules — no file yet exists that a skill author or reader can
open to see all 12 blocks in one place. This story builds that destination file.
Per this epic's own scope boundary, it builds the **structure**, not a full
copy-paste duplication of every rule's text (that would recreate the exact drift
problem this epic exists to fix, and moving full rule content is explicitly e56's
job) — each block section synthesizes what current doctrine states, citing where
the fuller text still lives.

### 2. Value statement [draft]

As a skill author or future maintainer, I want a single `constitution.md` that
states, block by block, what bigpowers' doctrine currently says — with citations to
the fuller source — so that I have one place to start reading instead of 49
scattered files, without losing access to the detail those files still hold.

### 3. Actors and permissions [draft]

- Skill authors / maintainers (internal) — read `constitution.md` as the
  consolidated entry point.
- e55s03 (internal) — adds `CLAUDE.md`/`CONVENTIONS.md` pointers to this file next.
- e56 (internal, future) — will eventually move full rule-classified skill content
  into this file's structure; this story only builds the shape it moves into.

### 4. Trigger and preconditions [draft]

Trigger: picked up as e55's second story, immediately after e55s01.
Precondition: `specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md`
exists with a complete B0-B10 + Capstone mapping; no `constitution.md` exists yet
at the repo root.

### 5. Main flow and business logic [draft]

1. Write `constitution.md` at the repo root (alongside `CLAUDE.md`) with a short
   header stating its authority ("this file is where a skill author starts
   reading; it does not yet replace `CLAUDE.md`/`CONVENTIONS.md`, which remain
   fully authoritative until e55s03/future work adds pointers") — no
   `constitution_version`/SemVer amendment scheme (that belongs to e59).
2. Write Part I: one section per block (B0 through B10, then Capstone), each
   synthesizing e55s01's mapping for that block in a few sentences plus a bullet
   list of its concrete current rules, each bullet citing its real source file
   (e.g. "— see `CONVENTIONS.md` §Risk Tiers, `docs/references/tea.md`").
3. Resolve e55s01's first open question: the migration-scoped **Catalog Freeze**
   section (`CONVENTIONS.md` §Catalog Freeze) is time-bound (expires when e56
   merges) — explicitly exclude it from `constitution.md`; it stays only in
   `CONVENTIONS.md` as transitional process state, not permanent doctrine.
4. Resolve e55s01's second open question: describe today's Gherkin-based 94%
   self-compliance gate (`npm run compliance`) honestly, under B5/B6 where it
   actually lives operationally today, with an explicit note that
   `reborn-constitution.md`'s Capstone definition targets replacing this
   mechanism with outcome evals — and that replacement is **e58's job, not yet
   built**. Do not describe the eval-based mechanism as already in place.
5. Confirm every block section cites at least one real, currently-existing
   source file — no invented rules, no forward-dated e57/e58/e59 concepts
   presented as already true.

Interruption point: N/A — a single-file write, not a resumable multi-step flow.

### 6. Alternative flows and exceptions [draft]

6a. A block has thin or no current bigpowers content (per e55s01's mapping, e.g.
B3/B9/B10 were sparse across the `docs/references/*.md` craftsmanship batch) —
state plainly what current rules DO exist for that block (often concentrated in
`CLAUDE.md`/`CONVENTIONS.md` rather than the reference docs) rather than padding
the section with invented content to look complete.

6b. A rule is genuinely duplicated across multiple source files (per e55s01's
duplication findings, e.g. F.I.R.S.T testing stated in 6 files) — cite the
duplication explicitly in the relevant block section as a known drift instance,
rather than silently picking one source and hiding the others.

### 7. Interface elements [draft]

Not applicable — markdown document, no UI surface.

### 8. Domain model [draft]

Entities touched: none pre-existing. Artifact produced: `constitution.md` (repo
root) — 12 sections (B0–B10, Capstone), each with a short synthesis + cited rule
bullets.

### 9. Integrations and boundaries [draft]

- `specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md` (direction:
  in) — this story's direct content source.
- `CLAUDE.md`, `CONVENTIONS.md` (direction: none this story — explicitly
  untouched; e55s03 adds pointers next).
- e55s03 (direction: out) — consumes this file as the cross-reference target.

### 10. Background processes [draft]

Not applicable.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The file itself, plus the commit that lands it, is the audit record.

### 13. Solution variabilities [draft]

Not applicable.

### 14. Quality attributes *NFR* [draft]

- Every cited source file must actually exist and actually contain the cited
  content (spot-checkable, not just asserted).

### 15. Security and compliance *NFR* [draft]

Not applicable — see `specs/security/epics/e55/THREAT_MODEL.md` (PASS, no
attacker-reachable surface; first-party doctrine content only).

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: constitution.md exists with all 12 blocks populated
  Given e55s01-doctrine-mapping.md contains a complete B0-B10 + Capstone mapping
  When  constitution.md is written
  Then  it contains a section for each of B0 through B10 and Capstone, each citing
        at least one real, currently-existing source file

Scenario: CLAUDE.md and CONVENTIONS.md are untouched
  Given constitution.md is additive
  When  this story completes
  Then  git diff for CLAUDE.md and CONVENTIONS.md is empty

Scenario: the Catalog Freeze section is excluded (open question 1, resolved)
  Given CONVENTIONS.md's Catalog Freeze section is migration-scoped and
        time-bound (expires when e56 merges)
  When  constitution.md is written
  Then  it does not restate the Catalog Freeze section or its
        freeze-exception mechanism

Scenario: the current compliance gate is described honestly (open question 2, resolved)
  Given bigpowers' current proof mechanism is a Gherkin-based 94% self-compliance
        gate, and reborn-constitution.md's Capstone targets replacing it with
        outcome evals via e58 (not yet built)
  When  constitution.md describes verification/compliance
  Then  it states the current 94% gate as today's real mechanism and separately
        notes e58 as the epic expected to eventually replace it — never
        presenting the eval-based mechanism as already in place

Scenario: no forward-dated concepts presented as already true
  Given constitution_version/SemVer schemes (e59), universal OKF-bundle coverage
        (e57), and a count-bcp skill (not yet built) all belong to later epics
  When  constitution.md is written
  Then  none of those terms appear as already-true current-state claims
```

### 18. Out of scope [draft]

- Moving full rule-classified skill content into `constitution.md` — that is
  e56's job; this story builds the block structure with concise synthesis and
  citations, not a full-text copy-paste of every source file.
- Adding cross-reference pointers from `CLAUDE.md`/`CONVENTIONS.md` back to
  `constitution.md` — that is e55s03's job.
- Any `constitution_version`/amendment/SemVer scheme — that is e59's job.

### 19. Open questions [draft]

Not applicable — both open questions carried from e55s01 are resolved in §5
above (steps 3 and 4).

### 20. References [draft]

- `epic.yaml` (`specs/epics/e55-extract-constitution/epic.yaml`) — e55s02
  planned-story entry.
- `specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md` — direct
  content source.
- `specs/reborn-constitution.md` Part I — block skeleton/structure reference
  only, not a content source.
