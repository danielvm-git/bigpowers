---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e53s02
TITLE:     Build the tombstone-alias mechanism
TYPE:      Enabler
PARENT:    e53
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      M   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

The planned migration sequence (e54-e59) will rename or merge several skills as bigpowers
reclassifies its catalog (e56, skill reclassification/merges). Today, renaming a skill
directory breaks every reference to its old name — invocations, documentation links, and any
consumer project pinned to the old name all fail with no transition window. The migration
plan's own stated invariant — "every skill rename ships a tombstone alias for one release" —
currently has zero supporting tooling: no script, no CONVENTIONS.md section, nothing in
`scripts/` implements it. This story builds that mechanism ahead of need, so e56 doesn't have
to invent it under time pressure.

### 2. Value statement [draft]

As a future migration story renaming or merging a skill, I want a tombstone-alias mechanism, so
that consumers referencing the old skill name still resolve for one release instead of breaking
immediately.

### 3. Actors and permissions [draft]

- Migration story author (internal) — invokes `tombstone-skill.sh` when renaming/merging a
  skill.
- Consumers of the old skill name (external/system) — still resolve via the stub for one
  release.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up during e53's build phase, proactively, ahead of the first real
rename in e56.
Precondition: no tombstone tooling exists anywhere in `scripts/` or CONVENTIONS.md (confirmed:
zero hits for tombstone/alias).

### 5. Main flow and business logic [draft]

1. Design the tombstone convention: a renamed/merged skill's old `skills/<old-name>/SKILL.md`
   is replaced with a stub stating the new name/location, forwarding invocation where the
   harness allows it.
2. Write `scripts/tombstone-skill.sh <old-name> <new-name-or-merge-target>` — generates the
   stub SKILL.md, preserves the old name's story tags for traceability, and registers the
   mapping in `specs/tombstones.yaml`.
3. Write `scripts/validate-tombstones.sh` — confirms each registered tombstone's stub still
   resolves and flags any that have exceeded their one-release expiry window.
4. Document the mechanism in CONVENTIONS.md under a new "Tombstone Aliases" section, including
   the requirement that the first real use of `tombstone-skill.sh` must also update
   `docs/references/model-profiles.md`'s skill-count annotations — the new stub increments the
   live count the same as any other `skills/*/SKILL.md`.

Interruption point: between steps 2 and 3 — the generator can exist and be tested standalone
before the validator is written.

### 6. Alternative flows and exceptions [draft]

6a. No tombstones are registered yet (this story's own end state) — `validate-tombstones.sh`
must report a clean "no tombstones" result, not a false failure.
6b. A tombstone's one-release expiry window passes — `validate-tombstones.sh` flags it for
removal rather than silently leaving a permanent stub.
6c. The harness doesn't support runtime invocation-forwarding for a given surface (e.g. a
static generated artifact) — the stub still documents the new name/location even without
functional forwarding.

### 7. Interface elements [draft]

Not applicable — CLI tooling, no UI surface.

### 8. Domain model [draft]

New entity: tombstone mapping (`old_name`, `new_name_or_merge_target`, `created_at`,
`expires_release`), persisted in `specs/tombstones.yaml`. Entity touched:
`skills/<old-name>/SKILL.md` (replaced with a stub).

### 9. Integrations and boundaries [draft]

- `scripts/validate-skill-catalog.sh`, `scripts/check-skill-links.py`,
  `website/scripts/prebuild.mjs` (perennial, direction: in) — all scan `skills/*/SKILL.md`; a
  stub must still satisfy their frontmatter/naming requirements once first used.
- `docs/references/model-profiles.md`'s skill-count annotation (perennial, direction: out) —
  must be updated whenever a stub is actually generated (documented as a required step in this
  story's CONVENTIONS.md output, §5.4).

### 10. Background processes [draft]

Not applicable — invoked manually per rename, not scheduled.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

`specs/tombstones.yaml` itself is the audit ledger — every tombstone's origin, target, and
creation date.

### 13. Solution variabilities [draft]

- Expiry window (config) — "one release," currently hardcoded; no per-tenant variation needed
  since this is bigpowers-internal tooling.

### 14. Quality attributes *NFR* [draft]

- `validate-tombstones.sh` must run in well under 1s for a repo of this size — it is a
  Preflight-adjacent check, not a heavy scan.

### 15. Security and compliance *NFR* [draft]

Not applicable — no secrets or PII; tombstone mappings are the same class of information as any
other skill catalog metadata, already public.

### 16. UX and accessibility *NFR* [draft]

Not applicable — CLI-only, no end-user-facing surface.

### 17. Acceptance criteria [draft]

```
Scenario: tombstone-skill.sh generates a stub
  Given a real skill directory and a target new name
  When  tombstone-skill.sh <old-name> <new-name> is run
  Then  skills/<old-name>/SKILL.md becomes a stub pointing at <new-name>
  And   specs/tombstones.yaml records the mapping

Scenario: validate-tombstones.sh with zero tombstones registered (6a)
  Given no tombstones are registered
  When  validate-tombstones.sh is run
  Then  it reports "no tombstones" and exits 0

Scenario: expired tombstone flagged (6b)
  Given a tombstone whose one-release expiry window has passed
  When  validate-tombstones.sh is run
  Then  it flags the expired tombstone for removal

Scenario: CONVENTIONS.md documents the mechanism
  Given the Tombstone Aliases section is written
  When  a reader consults CONVENTIONS.md
  Then  it documents both the mechanism and the required skill-count-annotation update step
```

### 18. Out of scope [draft]

- Actually renaming or merging any real skill — that is e56's job. This story builds the
  mechanism only.
- Runtime invocation-forwarding for every possible harness surface — best-effort where the
  harness allows it, documented where it doesn't (6c).

### 19. Open questions [draft]

Not applicable — the mechanism's shape was fully specified during this story's own resolution.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e53-establish-migration-baseline/epic.yaml`) — e53s02 AC block.
- `CLAUDE.md` § Pre-Merge Checklist — "Run `--baseline` after any intentional increase in skill
  count or structure."
