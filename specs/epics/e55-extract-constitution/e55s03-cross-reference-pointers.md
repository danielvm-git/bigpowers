---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-23T19:45:48Z
supersedes: null
commit_range: null
---

```
STORY KEY: e55s03
TITLE:     Point CLAUDE.md/CONVENTIONS.md at constitution.md, don't delete them yet
TYPE:      Enabler
PARENT:    e55
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-23
MATURITY:  4
SIZE:      S   (Fibonacci 1/2/3/5/8)
```

### Zoom-Out Mandate

This story modifies two existing, widely-read files, so per the zoom-out
mandate before touching them:

- **`CLAUDE.md`** — purpose: project-level instructions read by Claude Code at
  session start (context routing, commands, agent rules); callers:
  Claude Code's session bootstrap, `scripts/sync-skills.sh` (propagates content
  to `.cursor/`/`.gemini/`/`.pi`/`website/` derivatives), human contributors
  reading it directly; contracts: must stay valid Markdown; no script parses it
  by strict structural position (confirmed: `sync-references.sh` calls
  independent generator scripts, doesn't regex-parse `CLAUDE.md` itself).
- **`CONVENTIONS.md`** — purpose: the rules/conventions document (P0–P3 tiers)
  agents and audit scripts read to gate behavior; callers: `audit-code`,
  `trace-stories.sh` (`# story: eNNsNN` header tags), the compliance suite
  (Gherkin scenarios reference its sections), `scripts/decompose-conventions.sh`
  (splits it into `specs/conventions-wiki/` by heading); contracts: valid
  Markdown, `# story:` tags at the top, heading structure `decompose-
  conventions.sh` walks generically (confirmed: it treats "each major heading"
  as a wiki page — adding one more heading is additive, not breaking).

Conclusion: a new, clearly-scoped section pointing at `constitution.md` is
additive to both files' structure and doesn't conflict with any caller's
parsing assumptions.

### 1. Business narrative [draft]

e55s02 built `constitution.md` as a consolidated entry point, but nothing in
`CLAUDE.md` or `CONVENTIONS.md` — the two files most contributors and agents
actually open first — tells a reader it exists. Without a pointer, the new
file is an island; readers keep starting from the old 27-scattered-file
picture out of habit, and the consolidation effort doesn't actually change
anyone's behavior.

### 2. Value statement [draft]

As a contributor or agent reading `CLAUDE.md`/`CONVENTIONS.md` (as they
already do today), I want a clear pointer to `constitution.md`, so that I
discover the consolidated doctrine view without needing to already know it
exists.

### 3. Actors and permissions [draft]

- Contributors / agents (internal) — read `CLAUDE.md`/`CONVENTIONS.md` today;
  gain a pointer to `constitution.md`.
- Future work (internal, out of scope) — full retirement of the old files, if
  ever decided, builds on this pointer existing first.

### 4. Trigger and preconditions [draft]

Trigger: picked up as e55's third and final story, after e55s02.
Precondition: `constitution.md` exists at the repo root with all 12 blocks
populated (e55s02, commit `f7a1bba3`); no existing pointer to it exists in
either file yet.

### 5. Main flow and business logic [draft]

1. Add a short pointer section near the top of `CLAUDE.md` (after the
   `# story:` tag block, before "Context Routing") noting `constitution.md`
   exists as the consolidated doctrine entry point, with one line per block it
   covers isn't needed — just the pointer and what it's for.
2. Add an equivalent short pointer section near the top of `CONVENTIONS.md`
   (after its `# story:` tag block, before "Conventional Commits & Semantic
   Versioning").
3. Both pointers state plainly that `CLAUDE.md`/`CONVENTIONS.md` remain fully
   authoritative for their own content today — the pointer is additive
   awareness, not a redirect that implies the reader should stop reading here.
4. Add a `# story: e55s03` tag to both files' existing header tag blocks.
5. Confirm no existing line in either file was removed, reordered, or reworded
   — this story only inserts new lines.

Interruption point: N/A — two small, independent insertions.

### 6. Alternative flows and exceptions [draft]

6a. A future reader might assume this pointer means the old files are
deprecated — the pointer text explicitly says otherwise ("remains fully
authoritative"), since full retirement is out of scope and undecided.

### 7. Interface elements [draft]

Not applicable — markdown documents, no UI surface.

### 8. Domain model [draft]

Entities touched: `CLAUDE.md`, `CONVENTIONS.md` (both modified, additive
only). No new artifact produced.

### 9. Integrations and boundaries [draft]

- `constitution.md` (direction: in) — the target both pointers reference.
- `scripts/decompose-conventions.sh`, `scripts/sync-references.sh` (direction:
  none — confirmed unaffected by an additive heading, per Zoom-Out Mandate
  above).

### 10. Background processes [draft]

Not applicable.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The diff itself, plus the commit that lands it, is the audit record.

### 13. Solution variabilities [draft]

Not applicable.

### 14. Quality attributes *NFR* [draft]

- `scripts/decompose-conventions.sh` must still run cleanly against the
  modified `CONVENTIONS.md` (no new wiki-generation errors).

### 15. Security and compliance *NFR* [draft]

Not applicable — see `specs/security/epics/e55/THREAT_MODEL.md` (PASS, no
attacker-reachable surface).

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: CLAUDE.md points to constitution.md
  Given constitution.md exists as the consolidated doctrine entry point
  When  this story completes
  Then  CLAUDE.md contains a pointer to constitution.md stating it remains
        fully authoritative for its own content today

Scenario: CONVENTIONS.md points to constitution.md
  Given constitution.md exists as the consolidated doctrine entry point
  When  this story completes
  Then  CONVENTIONS.md contains a pointer to constitution.md stating it
        remains fully authoritative for its own content today

Scenario: no existing content is removed or reworded
  Given CLAUDE.md and CONVENTIONS.md have established content today
  When  this story completes
  Then  a diff of both files shows only additions, no deletions or line
        modifications to pre-existing content

Scenario: downstream tooling still works
  Given scripts/decompose-conventions.sh parses CONVENTIONS.md by heading
  When  this story adds one new heading
  Then  scripts/decompose-conventions.sh still runs to completion without error
```

### 18. Out of scope [draft]

- Full retirement, deletion, or condensation of `CLAUDE.md`/`CONVENTIONS.md`
  — a separate, later decision per the epic's own scope.
- Any change to `constitution.md`'s own content — that shipped in e55s02.
- Archiving the epic capsule — that's `release-branch`'s own hard gate,
  triggered automatically once this story (the last one) is `done`.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e55-extract-constitution/epic.yaml`) — e55s03
  planned-story entry.
- `constitution.md` — the cross-reference target, written by e55s02.
- This project's own T18 wayfinder ticket (AGENTS.md canonical-file + pointers
  precedent), cited in `planning-context.yaml`'s key_decisions.
