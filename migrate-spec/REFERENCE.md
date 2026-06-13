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
