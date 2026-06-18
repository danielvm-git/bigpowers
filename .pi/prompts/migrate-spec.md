---
description: Detect GSD, spec-kit, or BMAD spec artifacts and transform them into bigpowers YAML layout (state.yaml, release-plan.yaml, epics/, requirements/, plans/, ADRs). Use when migrating foreign spec docs.
---


# Migrate Spec

Transform existing GSD, spec-kit, or BMAD planning artifacts into the bigpowers `specs/` model. No code is written — the output is a set of bigpowers-format spec files the user can use immediately.

## Quick start

1. Run this skill from the root of the project being migrated (not the bigpowers repo itself).
2. The skill auto-detects the source framework and presents its findings before transforming anything.
3. All output goes to `specs/` at the project root.


## Red flags — stop and ask

Before proceeding, check for these rationalization traps:

- **Partial artifact set** — only one fingerprint file found (e.g. just `spec.md` with no `plan.md`). Don't assume it's a complete project. Ask: "I found only X — is this the full set of your spec artifacts?"
- **Wrong trigger** — user said "migrate my code" or "migrate the database", not "migrate my specs". Confirm before running.
- **Stale source** — source artifacts have commit dates older than 6 months with no recent activity. Flag: "These specs appear inactive since <date>. Are they still the source of truth?"
- **Active divergence** — source `state.yaml` or `sprint-status.yaml` shows in-progress work. Flag: "There is active work in flight. Migrating now may lose in-progress context. Proceed?"

If any red flag fires: surface it, wait for explicit user confirmation before continuing.


## Process

### Step 1 — Detect the source framework

Scan for the fingerprints below. Stop at first match; if multiple match, list them and ask the user which is primary.

| Framework | Fingerprints (any one is sufficient) |
|-----------|--------------------------------------|
| **GSD** | `.planning/` directory; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md` with `REQ-` IDs |
| **spec-kit** | `.specify/` directory; `spec.md` + `plan.md` at root; `.github/skills/speckit-*/SKILL.md` |
| **BMAD** | `_bmad/` directory; `_bmad-output/` directory; `prd.md` with `FR-` IDs; `epic-*.md` or `story-*.md` |

If none found: ask the user which framework before proceeding.

→ verify: `ls .planning/ 2>/dev/null && echo "GSD" || ls .specify/ 2>/dev/null && echo "spec-kit" || ls _bmad/ 2>/dev/null && echo "BMAD" || echo "BLOCKED: no known framework detected"`

### Step 2 — Inventory the source artifacts

List every artifact found matching the detected framework. Present the list to the user:

```
Detected: GSD
Found:
  ✓ .planning/ROADMAP.md
  ✓ .planning/REQUIREMENTS.md  (12 REQ-XX items)
  ✓ .planning/state.yaml
  ✓ .planning/phases/01-auth/01-CONTEXT.md
  ✗ .planning/METHODOLOGY.md  (not present)

Skipping:
  .planning/phases/01-auth/01-01-SUMMARY.md  (execution record; archived only)

Proceed with migration? [yes / skip <artifact> / abort]
```

→ verify: `find . -maxdepth 4 \( -name "ROADMAP.md" -o -name "spec.md" -o -name "prd.md" -o -name "REQUIREMENTS.md" \) 2>/dev/null | grep -v ".git" | head -15`

### Step 3 — Transform (one artifact at a time, show diffs)

Apply the mapping from [REFERENCE.md](./REFERENCE.md) and [REFERENCE-GSD.md](./REFERENCE-GSD.md). For each target file:

1. Show what will be created or appended (title + first 20 lines).
2. Ask: "Create this? [yes / edit / skip]"
3. On yes: write to `specs/`.

> **HARD GATE** — Never overwrite an existing `specs/` file without explicit user confirmation. Merge into it if it exists; don't clobber.
>
> → verify: `git diff --name-only HEAD -- specs/ 2>/dev/null | head -20`

→ verify: `ls specs/*.md 2>/dev/null | head -15`

### Step 4 — Generate state.yaml

Always regenerate `specs/state.yaml` from scratch in bigpowers format (see REFERENCE.md for template):

```markdown
# Session State: <project name>
## Current Milestone
Migrated from <framework> on <date>. Next: review generated specs and run plan-work.
## Pending Releases
- [ ] Review migrated specs
- [ ] Run elaborate-spec to validate scope
- [ ] Run plan-work to produce first release plan
```

→ verify: `[ -f specs/state.yaml ] && echo "ok" || echo "MISSING: specs/state.yaml not created"`

### Step 5 — Surface learnings (optional)

After migration, offer the user a brief analysis of what the source framework did that bigpowers doesn't have yet.

Use the learnings table from [REFERENCE.md](./REFERENCE.md#learnings-to-adopt). Present as checkboxes so the user can decide which to adopt.

→ verify: `grep -c "\- \[ \]" specs/state.yaml 2>/dev/null && echo "pending items recorded" || echo "no pending items in state.yaml"`


## Artifact Mapping Summary

Full mapping tables: [REFERENCE-GSD.md](./REFERENCE-GSD.md) (GSD) · [REFERENCE.md](./REFERENCE.md) (spec-kit, BMAD, learnings).

| Source | Target |
|--------|--------|
| GSD `ROADMAP.md` | `specs/release-plan.yaml + epic shards` |
| GSD `REQUIREMENTS.md` | `specs/product/SCOPE_LATEST.yaml` |
| GSD `CONTEXT.md` (phases) | `specs/tech-architecture/tech-stack.md` + `specs/adr/` |
| GSD `PLAN.md` | `specs/epics/eNN-slug/epic.yaml` (tasks with verify in `-tasks.yaml`) |
| GSD `METHODOLOGY.md` | `specs/tech-architecture/tech-stack.md` |
| spec-kit `spec.md` | `specs/product/SCOPE_LATEST.yaml` + `specs/tech-architecture/tech-stack.md` |
| spec-kit `plan.md` | `specs/tech-architecture/tech-stack.md` + `specs/release-plan.yaml` + `specs/epics/` |
| spec-kit `tasks.md` | `specs/epics/ (see slice-tasks)` |
| BMAD `prd.md` | `specs/product/SCOPE_LATEST.yaml` |
| BMAD `architecture.md` | `specs/tech-architecture/tech-stack.md` + `specs/adr/` |
| BMAD `epic-*.md` | `specs/release-plan.yaml + epic shards` |
| BMAD `story-*.md` | `specs/epics/ (see slice-tasks)` |
| BMAD `project-context.md` | `CLAUDE.md` (append project-specific section) |
| BMAD `decision-log.md` | `specs/adr/` (one ADR per logged decision) |


## Rules

- **Preserve source IDs** — REQ-XX, FR-XX, UJ-XX become inline comments in bigpowers targets. Never silently renumber.
- **Never merge contradictory docs** — if source has both `CONTEXT.md` and `architecture.md`, create sections in bigpowers `CONTEXT.md`; don't collapse them.
- **ADRs are opt-in** — only create an ADR when: hard to reverse, surprising without context, result of a real trade-off. Lightweight decisions go to `specs/DECISION-LOG.md`.
- **state.yaml is always regenerated** — never migrate source STATE verbatim; bigpowers state.yaml needs its own format.
- **specs/ is the only output location** — no files are created outside `specs/` and `CLAUDE.md`.

---

# migrate-spec Reference — GSD

Full artifact transformation rules for migrating GSD projects to bigpowers YAML layout.

See [REFERENCE.md](./REFERENCE.md) for spec-kit, BMAD, learnings, and ADR/DECISION-LOG formats.

---

## Artifact Locations

GSD stores everything under `.planning/` at the project root.

```
.planning/
├── ROADMAP.md
├── STATE.md
├── REQUIREMENTS.md
├── METHODOLOGY.md
├── HANDOFF.json
├── .continue-here.md
└── phases/
    └── XX-name/
        ├── XX-CONTEXT.md
        ├── XX-YY-PLAN.md
        ├── XX-YY-SUMMARY.md
        └── XX-DISCUSSION-LOG.md
    spikes/
        └── SPIKE-NNN/README.md
```

---

## Transformation Rules

### `.planning/ROADMAP.md` → `specs/release-plan.yaml` + `specs/epics/eNN-*.yaml`

GSD ROADMAP has: milestone name, phases, success criteria per phase, plan count.

Transform:
- Each GSD phase → one epic entry in `release-plan.yaml` (`id`, `title`, `wsjf`, `file`)
- Phase detail → matching `specs/epics/eNN-slug.yaml` (stories, tasks, `verify`)
- Completed phases → `done` in `execution-status.yaml`; active → `in_progress`

---

### `.planning/REQUIREMENTS.md` → `specs/product/SCOPE_LATEST.yaml`

GSD REQUIREMENTS has: REQ-XX IDs, Validated/Active/Out-of-Scope categories, traceability.

Transform:
- Copy REQ-XX IDs as-is (preserve for cross-referencing)
- Validated requirements → `in_scope` entries
- Out-of-Scope → `out_of_scope` entries
- Active (in-progress) → `in_scope` with status note

---

### `.planning/phases/XX-name/XX-CONTEXT.md` → `specs/tech-architecture/TECH_STACK_LATEST.md` + `specs/adr/`

GSD CONTEXT.md has 6 sections: domain, decisions, canonical_refs, code_context, specifics, deferred.

Transform:
- `domain` → `plans/TECH_STACK_LATEST.md` Domain section
- `decisions` → scan each: if hard-to-reverse + surprising → `specs/adr/NNNN-{slug}.md`; if lightweight → `specs/DECISION-LOG.md`
- `canonical_refs` → Reference links in TECH_STACK
- `code_context` → Architecture section
- `deferred` → `SCOPE_LATEST.yaml` `out_of_scope` (with "(deferred from GSD)" note)

---

### `.planning/phases/XX-name/XX-YY-PLAN.md` → `specs/epics/eNN-*.yaml` tasks

GSD PLAN has: frontmatter (depends-on, verify), objective, typed tasks, success criteria, output spec.

Transform:
- Preserve task structure as `tasks[]` in epic shard
- Keep `verify: <command>` lines
- Map GSD `depends-on` to task `depends-on` notes
- SUMMARY.md (execution record) → skip or append to `specs/archive/`

---

### `.planning/METHODOLOGY.md` → `specs/tech-architecture/METHODOLOGY_LATEST.md`

GSD METHODOLOGY.md is a standing reference for analytical lenses (Bayesian updating, STRIDE, cost-of-delay).

Transform:
- Copy each lens as a section in `specs/tech-architecture/METHODOLOGY_LATEST.md`
- Note: "These lenses should inform `plan-work` and `audit-code` sessions."

---

### `.planning/HANDOFF.json` + `.continue-here.md` → `specs/state.yaml` `handoff`

GSD HANDOFF has: current phase, last plan, blocking reason, required reading list.

Transform — populate `handoff` in `state.yaml`:

```yaml
handoff:
  last_step_completed: "<phase/plan from HANDOFF>"
  open_decisions:
    - "<blocking reason if any>"
  required_reading:
    - "<required_reading list>"
  next_skill: survey-context
```

---

### `.planning/spikes/SPIKE-NNN/README.md` → `specs/archive/spikes/SPIKE-{name}.md`

GSD spike README has: YAML frontmatter (verdict, validates, related), methodology, findings, recommendation.

Transform:
- Flatten directory into `specs/archive/spikes/SPIKE-{name}.md`
- Preserve frontmatter as YAML block at top
- Keep verdict prominently: `**Verdict:** ADOPTED / REJECTED / DEFERRED`

---

## Skip List

These GSD artifacts are not migrated — they are execution records, not planning inputs:

| Artifact | Reason |
|----------|--------|
| `.planning/phases/XX/XX-YY-SUMMARY.md` | Execution log; no bigpowers equivalent |
| `.planning/phases/XX/XX-DISCUSSION-LOG.md` | Audit trail only; not consumed by agents |
| `.planning/USER-PROFILE.md` | User calibration; bigpowers has no profile system |
| `.planning/sketches/` | Visual exploration; not spec artifacts |

---

# migrate-spec Reference — spec-kit, BMAD, Learnings

Transformation rules for spec-kit and BMAD projects, plus learnings to adopt and output formats.

See [REFERENCE-GSD.md](./REFERENCE-GSD.md) for full GSD → bigpowers YAML mapping.

---

## spec-kit → bigpowers Mapping

### Artifact Locations

```
project-root/
├── spec.md         ← user journeys, success criteria, scope
├── plan.md         ← technology, architecture, constraints
├── tasks.md        ← atomic task list
└── .specify/
    ├── workflow-catalogs.yml
    └── workflows/runs/<id>/
        ├── state.json
        └── log.jsonl
```

### `spec.md` → `specs/product/SCOPE_LATEST.yaml` + `specs/tech-architecture/TECH_STACK_LATEST.md`

spec-kit `spec.md` focuses on: who uses it, user journeys, success criteria, what's in/out of scope.

Transform:
- User journeys → `SCOPE_LATEST.yaml` success criteria / `in_scope` entries
- In/out of scope → `in_scope` / `out_of_scope` sections
- Domain terms / glossary → `requirements/GLOSSARY_LATEST.yaml`
- Problem statement / vision → `requirements/VISION_LATEST.yaml`

### `plan.md` → `specs/tech-architecture/TECH_STACK_LATEST.md` + `specs/release-plan.yaml` + `specs/epics/`

spec-kit `plan.md` covers: technology stack, architectural patterns, implementation constraints.

Transform:
- Technology decisions → `plans/TECH_STACK_LATEST.md` Technology section
- Architecture patterns → Architecture section
- Hard decisions with trade-offs → `specs/adr/NNNN-{slug}.md`
- Phased approach / milestones → `release-plan.yaml` epic entries
- Implementation steps → `epics/eNN-*.yaml` task list with `verify:`

### `tasks.md` → `specs/epics/` (via slice-tasks)

spec-kit tasks are atomic, verifiable in isolation — same principle as bigpowers `verify:` mandate.

Transform:
- Copy tasks into epic shard `tasks[]`; preserve task numbers
- Add `verify:` line if spec-kit task has an acceptance criterion
- Group into epics matching `release-plan.yaml` entries

### `.specify/` state

Discard — workflow engine state; not meaningful in the bigpowers skill model.

---

## BMAD → bigpowers Mapping

### Artifact Locations

```
project-root/
├── _bmad/bmm/config.yaml
├── _bmad-output/
│   ├── product-brief.md
│   ├── prfaq-{project}.md
│   ├── prd.md
│   ├── addendum.md
│   ├── decision-log.md
│   ├── ux-spec.md
│   └── architecture.md
├── project-context.md
└── docs/
    ├── epic-{slug}.md
    └── story-{slug}.md
```

### `product-brief.md` / `prfaq-{project}.md` → `specs/product/VISION_LATEST.yaml`

Transform:
- Vision + core value → `VISION_LATEST.yaml` north_star / success_criteria
- Target users → notes in VISION or SCOPE
- prfaq customer FAQ → can inform success criteria in SCOPE

### `prd.md` → `specs/product/SCOPE_LATEST.yaml` + `GLOSSARY_LATEST.yaml`

BMAD `prd.md` has: Glossary, FR-XX functional requirements, UJ-XX user journeys, NFRs, assumptions.

Transform:
- Glossary → `GLOSSARY_LATEST.yaml`
- FR-XX items → `in_scope` with IDs preserved
- UJ-XX user journeys → success criteria
- NFRs → `constraints` section
- `[ASSUMPTION: ...]` inline tags → collected in scope YAML
- Out-of-scope features → `out_of_scope`

### `addendum.md` + `decision-log.md` → `specs/adr/` + `specs/DECISION-LOG.md`

Transform:
- Hard, irreversible, surprising decisions → individual `specs/adr/NNNN-{slug}.md`
- Lightweight decisions → `specs/DECISION-LOG.md` (date | decision | rationale)
- `addendum.md` change signals → note in `SCOPE_LATEST.yaml` metadata

### `architecture.md` → `specs/tech-architecture/TECH_STACK_LATEST.md` + `specs/adr/`

Transform:
- ADR sections → individual `specs/adr/NNNN-{slug}.md` files
- System overview / data models → TECH_STACK Architecture section
- API contracts → keep at `docs/api.md` or similar; link from TECH_STACK

### `epic-*.md` → `specs/release-plan.yaml` + `specs/epics/eNN-*.yaml`

Each epic → one release-plan entry + one epic shard. Acceptance criteria → story tasks with `verify:`.

### `story-*.md` → `specs/epics/` stories

Each story → one story entry in epic shard. Acceptance criteria → `verify:` lines.

### `project-context.md` → `CLAUDE.md`

Add a "## Project Context" section to `CLAUDE.md`. Copy tech stack, coding rules, preferences verbatim.

---

## Learnings to Adopt

Optional enhancements to offer the user after migration. Present as checkboxes.

### From GSD

- [ ] **`specs/tech-architecture/METHODOLOGY_LATEST.md`** — Standing analytical lenses. Agents read before planning.
- [ ] **`handoff` block in state.yaml** — Last skill, last step, required reading for next session.
- [ ] **ID tracking in SCOPE_LATEST.yaml** — FR/UJ IDs for spec → plan → verification traceability.

### From spec-kit

- [ ] **Two-pass spec writing** — User-journey pass first, then technical-decisions pass.
- [ ] **Explicit inter-phase gate** — "Approve to proceed?" at end of `elaborate-spec`.
- [ ] **Epic task isolation** — Each task completable in isolation; `depends-on` explicit in epic YAML.

### From BMAD

- [ ] **FR-XX + UJ-XX in SCOPE_LATEST.yaml** — Rigorous traceability.
- [ ] **`specs/DECISION-LOG.md`** — Lightweight decisions below ADR threshold.
- [ ] **Adversarial review pass** — Critique epic shard before `develop-tdd`.

---

## Output Formats

### ADR format (bigpowers)

Use `model-domain/ADR-FORMAT.md`. Only create when all three apply: hard to reverse, surprising without context, result of a real trade-off.

```markdown
# ADR-NNNN: {Title}

**Status:** Accepted
**Date:** YYYY-MM-DD

## Context
[What situation forced this decision?]

## Decision
[What was decided?]

## Consequences
[What becomes easier or harder?]
```

### DECISION-LOG.md format

For lightweight decisions that don't warrant a full ADR:

```markdown
# Decision Log

| Date | Decision | Rationale | Alternatives |
|------|----------|-----------|--------------|
| 2026-05-19 | Use Postgres | Existing ops expertise | SQLite (limited), DynamoDB (no local dev) |
```

### `specs/state.yaml` template format

Generated during Step 4 of migration. Regenerate from scratch in bigpowers format:

```markdown
# Session State: <project name>

## Current Milestone

Migrated from <framework> on <date>. Next: review generated specs and run plan-work.

## Git Metadata

- **Branch**: <current branch>
- **Hash**: <git rev-parse HEAD>

## Completed Releases

(none — migration starting point)

## Pending Releases

- [ ] Review migrated specs
- [ ] Run elaborate-spec to validate scope
- [ ] Run plan-work to produce first release plan
```
