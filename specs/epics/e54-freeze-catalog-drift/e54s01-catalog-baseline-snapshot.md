---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-release"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e54s01
TITLE:     Snapshot the current skill catalog as an immutable baseline
TYPE:      Enabler
PARENT:    e54
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      S   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

bigspec's `architecture.md` §1 verdicts the current 80-skill catalog as a metric to drop —
target is ~28 procedures once rules move to a constitution and deterministic tools move to a
kernel (e56, reclassify-catalog). That reclassification is a diff against a starting point.
Today there is no committed, dated snapshot of "the catalog as it stood the day the migration
froze" — only the live, continuously-changing `skills/` directory. Without one, e56 (and every
gate e54s02 adds) has nothing stable to compare against, and a future reader auditing the
migration's before/after has no ground truth for "before."

### 2. Value statement [draft]

As the e56 reclassification epic (and anyone auditing the migration later), I want a dated,
immutable snapshot of the pre-migration skill catalog, so that "what changed" has a fixed
starting point instead of a moving target.

### 3. Actors and permissions [draft]

- e56's future author (internal) — diffs the reclassified catalog against this baseline.
- Repo maintainer / auditor (internal) — reads the snapshot as historical record.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up as e54's first story, immediately after e53 completes.
Precondition: `skills/*/SKILL.md` is the live catalog (80 skills as of e53's completion); no
prior point-in-time snapshot of the full catalog exists anywhere in the repo.

### 5. Main flow and business logic [draft]

1. Write `scripts/snapshot-catalog-baseline.sh` — enumerates every `skills/*/SKILL.md`,
   extracts `name`/`phase`/`effort`/`model`/`description` from frontmatter, and writes a
   single structural file: `specs/tech-architecture/CATALOG-BASELINE-<date>.yaml`.
2. Include a header block: snapshot date, git commit hash, total skill count, and the explicit
   statement "frozen for e54-e59 migration; do not hand-edit."
3. Commit the snapshot file and confirm `git log -1` shows it as tracked, dated, and tied to a
   real commit hash (the immutability comes from git history, not a lock file).

Interruption point: N/A — a single script run + commit, not a resumable multi-step flow.

### 6. Alternative flows and exceptions [draft]

6a. A skill's frontmatter is missing a required field (e.g. no `model:`, matching the find-way
gap found during e53's own execution) — the script records `null` for that field rather than
failing the whole snapshot, and flags the gap in a `warnings:` list at the top of the output.
6b. The snapshot is re-run before e56 starts (e.g. after a documented exception per e54s03) —
the script always writes a new dated file rather than overwriting the original baseline, so the
history of "what the catalog looked like at each checkpoint" is preserved, not lost.

### 7. Interface elements [draft]

Not applicable — CLI tooling, no UI surface.

### 8. Domain model [draft]

Entities touched: none (read-only enumeration). Artifact produced:
`specs/tech-architecture/CATALOG-BASELINE-<date>.yaml` (one row per skill: name, phase, effort,
model, description, path).

### 9. Integrations and boundaries [draft]

- `skills/*/SKILL.md` (perennial, direction: in) — read-only enumeration source.
- e54s02's drift-detection gate (perennial, direction: out) — the baseline this story produces
  is that gate's comparison target.

### 10. Background processes [draft]

Not applicable — invoked once at freeze start, not scheduled.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The snapshot file itself, plus the git commit that tracks it, is the audit record.

### 13. Solution variabilities [draft]

Not applicable — one baseline, no per-tenant variation.

### 14. Quality attributes *NFR* [draft]

- Snapshot generation must complete in well under 5s for an 80-skill catalog (a simple
  frontmatter scan, not a heavy analysis).

### 15. Security and compliance *NFR* [draft]

Not applicable — no secrets or PII; skill metadata is already public.

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: baseline snapshot is written and committed
  Given skills/*/SKILL.md is the live 80-skill catalog
  When  scripts/snapshot-catalog-baseline.sh is run
  Then  specs/tech-architecture/CATALOG-BASELINE-<date>.yaml exists, lists all 80 skills,
        and is committed to git with a real commit hash

Scenario: a skill missing a required field doesn't abort the snapshot (6a)
  Given a skill's SKILL.md is missing the model: field
  When  the snapshot script runs
  Then  the snapshot still completes, records null for that field, and lists it under warnings
```

### 18. Out of scope [draft]

- Reclassifying or renaming any skill — that is e56's job. This story only records the
  starting state.
- Enforcing the freeze — that is e54s02's job. This story produces the reference point only.

### 19. Open questions [draft]

Not applicable.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e54-freeze-catalog-drift/epic.yaml`) — e54s01 AC block.
- `/Users/danielvm/Developer/bigspec/docs/architecture.md` §1 — the "primitives on trial"
  verdict this baseline exists to eventually diff against.
