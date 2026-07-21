---
okf_kind: story
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: 2026-07-21T00:00:00Z
supersedes: null
commit_range: null
---

```
STORY KEY: e53s01
TITLE:     Commit the untracked GOLDEN baseline
TYPE:      Enabler
PARENT:    e53
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-21
MATURITY:  4
SIZE:      XS   (Fibonacci 1/2/3/5/8)
```

### 1. Business narrative [draft]

`specs/benchmarks/reports/GOLDEN-2026-07-18.yaml` exists on disk (an 11/11 passing GOLDEN
suite run) but was never committed to git — confirmed via `git status`. The migration epic
e53's own "GOLDEN stays green" invariant, cited throughout the migration plan, needs to
reference an artifact that actually exists in git history, not just the working tree. Until
this file is committed, a fresh clone or CI checkout cannot see this baseline, and
`build-receipts.sh`'s `GOLDEN-*.yaml` glob resolves to an older, currently-tracked report
instead.

### 2. Value statement [draft]

As the bigpowers migration effort, I want the current GOLDEN baseline committed to git, so
that the "GOLDEN stays green" invariant cites a real, retrievable artifact instead of an
untracked file that could be lost or never seen by CI.

### 3. Actors and permissions [draft]

- Repo maintainer (internal) — commits the file via git.
- CI / fresh-clone consumers (system) — read the committed baseline via `build-receipts.sh`'s
  glob.

### 4. Trigger and preconditions [draft]

Trigger: this story is picked up during e53's build phase.
Precondition: `specs/benchmarks/reports/GOLDEN-2026-07-18.yaml` exists on disk and is
untracked (`git status --short` shows `??`).

### 5. Main flow and business logic [draft]

1. Confirm the file is untracked and no other uncommitted changes would be swept up with the
   same `git add`.
2. Stage and commit the file on its own, using a Conventional Commits message
   (`chore: track GOLDEN-2026-07-18 baseline`).
3. Confirm the file is now tracked (`git ls-files --error-unmatch`) and that
   `build-receipts.sh`'s `GOLDEN-*.yaml` glob picks it up as the latest report.

Interruption point: N/A — a single atomic commit, not a resumable multi-step flow.

### 6. Alternative flows and exceptions [draft]

6a. Other unrelated uncommitted changes exist in the working tree at commit time — stage only
this one file explicitly (`git add <path>`), never a broad `git add -A`.
6b. The file has since been superseded by a newer GOLDEN report — re-run this story against
whichever `GOLDEN-*.yaml` is currently untracked and latest, not necessarily the 07-18 date.

### 7. Interface elements [draft]

Not applicable — no UI surface; this is a git/filesystem operation.

### 8. Domain model [draft]

Entities touched: none (no application data model). Artifact touched:
`specs/benchmarks/reports/GOLDEN-2026-07-18.yaml` (a GOLDEN suite run report — timestamp,
git_commit, deterministic gate results, pass_rate).

### 9. Integrations and boundaries [draft]

- git (perennial, direction: out) — the commit itself.
- `build-receipts.sh`'s `GOLDEN-*.yaml` glob (perennial, direction: in) — the consumer that
  will newly see this file post-commit.

### 10. Background processes [draft]

Not applicable — no scheduled or event-driven process; a one-time manual commit.

### 11. Notifications [draft]

Not applicable.

### 12. Audit and logging [draft]

The git commit itself is the audit trail — commit message, author, timestamp, diff.

### 13. Solution variabilities [draft]

Not applicable — no configuration or per-tenant variation.

### 14. Quality attributes *NFR* [draft]

Not applicable — a single file commit has no latency/uptime/scale dimension.

### 15. Security and compliance *NFR* [draft]

Not applicable — the file contains no secrets or PII; it is a benchmark pass/fail report
already safe to publish (every other `GOLDEN-*.yaml` report is already tracked and public).

### 16. UX and accessibility *NFR* [draft]

Not applicable.

### 17. Acceptance criteria [draft]

```
Scenario: GOLDEN baseline gets committed
  Given specs/benchmarks/reports/GOLDEN-2026-07-18.yaml exists on disk and is untracked
  When  the file is committed with a Conventional Commits message
  Then  git ls-files confirms the file is tracked

Scenario: no unrelated changes swept up (6a)
  Given other uncommitted changes exist elsewhere in the working tree
  When  this story's commit is made
  Then  the commit diff contains only specs/benchmarks/reports/GOLDEN-2026-07-18.yaml
```

### 18. Out of scope [draft]

- Regenerating or re-running the GOLDEN suite — this story commits the existing report as-is.
- Flipping any gate's optionality — that is e53s03's job (mapping only) and a later epic's job
  (flipping).

### 19. Open questions [draft]

Not applicable — no open questions; this is a fully specified, mechanical story.

### 20. References [draft]

- `epic.yaml` (`specs/epics/e53-establish-migration-baseline/epic.yaml`) — e53s01 AC block.
- `scripts/build-receipts.sh:41` — the `GOLDEN-*.yaml` glob consumer.
