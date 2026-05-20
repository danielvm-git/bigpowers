# migrate-spec Reference — spec-kit, BMAD, Learnings

Transformation rules for spec-kit and BMAD projects, plus learnings to adopt and output formats.

See [REFERENCE-GSD.md](./REFERENCE-GSD.md) for full GSD → bigpowers mapping.

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

### `spec.md` → `specs/SCOPE.md` + `specs/CONTEXT.md`

spec-kit `spec.md` focuses on: who uses it, user journeys, success criteria, what's in/out of scope.

Transform:
- User journeys → `specs/SCOPE.md` "Success Criteria" subsection (observable behaviors)
- In/out of scope → `specs/SCOPE.md` main sections
- Domain terms / glossary → `specs/CONTEXT.md` glossary section
- Problem statement / vision → first paragraph of `specs/CONTEXT.md`

### `plan.md` → `specs/CONTEXT.md` + `specs/PLAN.md`

spec-kit `plan.md` covers: technology stack, architectural patterns, implementation constraints.

Transform:
- Technology decisions → `specs/CONTEXT.md` "Technology" section
- Architecture patterns → `specs/CONTEXT.md` "Architecture" section
- Hard decisions with trade-offs → `specs/adr/NNNN-{slug}.md`
- Phased approach / milestones → `specs/RELEASE-PLAN.md` release entries
- Implementation steps → `specs/PLAN.md` task list

### `tasks.md` → `specs/TASKS.md`

spec-kit tasks are atomic, verifiable in isolation — same principle as bigpowers `verify:` mandate.

Transform:
- Copy tasks directly; preserve task numbers
- Add `verify:` line if spec-kit task has an acceptance criterion
- Group into phases matching `specs/RELEASE-PLAN.md` releases

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

### `product-brief.md` / `prfaq-{project}.md` → `specs/CONTEXT.md` (Vision)

Transform:
- Vision + core value → `specs/CONTEXT.md` Vision section (first section)
- Target users → personas list in CONTEXT.md
- prfaq customer FAQ → can inform success criteria in SCOPE.md

### `prd.md` → `specs/SCOPE.md`

BMAD `prd.md` has: Glossary, FR-XX functional requirements, UJ-XX user journeys, NFRs, assumptions.

Transform:
- Glossary → `specs/CONTEXT.md` Glossary section (keep exactly; it's domain language)
- FR-XX items → `specs/SCOPE.md` "In Scope" with IDs preserved as comments: `<!-- FR-3 -->`
- UJ-XX user journeys → `specs/SCOPE.md` "Success Criteria" section
- NFRs → `specs/SCOPE.md` "Constraints" section
- `[ASSUMPTION: ...]` inline tags → `specs/SCOPE.md` "Assumptions" section (collected)
- Out-of-scope features → `specs/SCOPE.md` "Out of Scope" section

### `addendum.md` + `decision-log.md` → `specs/adr/` + `specs/DECISION-LOG.md`

Transform:
- Hard, irreversible, surprising decisions → individual `specs/adr/NNNN-{slug}.md`
- Lightweight decisions → `specs/DECISION-LOG.md` (date | decision | rationale)
- `addendum.md` change signals → note at top of SCOPE.md: "PRD amended: see decision-log"

### `architecture.md` → `specs/CONTEXT.md` + `specs/adr/`

Transform:
- ADR sections → individual `specs/adr/NNNN-{slug}.md` files
- System overview / data models → `specs/CONTEXT.md` Architecture section
- API contracts → keep at `docs/api.md` or similar; link from CONTEXT.md

### `epic-*.md` → `specs/RELEASE-PLAN.md`

Each epic → one release entry. Epic acceptance criteria → "Success Criteria" subsection.

### `story-*.md` → `specs/TASKS.md`

Each story → one entry. Acceptance criteria → `verify:` lines. Story tasks → subtask checklist.

### `project-context.md` → `CLAUDE.md`

Add a "## Project Context" section to `CLAUDE.md` (or create `PROJECT-CONTEXT.md` if CLAUDE.md is bigpowers-managed). Copy tech stack, coding rules, preferences verbatim. Note: `<!-- Migrated from BMAD project-context.md -->`.

---

## Learnings to Adopt

Optional enhancements to offer the user after migration. Present as checkboxes.

### From GSD

- [ ] **`specs/METHODOLOGY.md`** — Standing analytical lenses (Bayesian updating, STRIDE, cost-of-delay). Agents read this before planning.
- [ ] **Session Resume block in STATE.md** — Last skill used, last step completed, required reading for next session.
- [ ] **ID tracking in SCOPE.md** — Add SCOPE-XX IDs to requirements for spec → plan → verification traceability.

### From spec-kit

- [ ] **Two-pass spec writing** — User-journey pass first (what/why, no technical details), then technical-decisions pass. Cleaner specs.
- [ ] **Explicit inter-phase gate** — "Approve to proceed?" checkpoint at end of `elaborate-spec` before starting `plan-work`.
- [ ] **`specs/TASKS.md` isolation guarantee** — Each task entry completable and verifiable in isolation; declared dependencies explicit.

### From BMAD

- [ ] **FR-XX + UJ-XX in SCOPE.md** — Functional requirement + user journey numbering for rigorous traceability.
- [ ] **`specs/DECISION-LOG.md`** — Lightweight decision log for PRD-level choices below the ADR threshold. Format: `date | decision | rationale | alternatives`.
- [ ] **`PROJECT-CONTEXT.md`** — Project-specific constitution read by all implementation agents. Generated from `model-domain` output.
- [ ] **Adversarial review pass** — Dedicated critique pass on the plan before `develop-tdd`. Critic checks for gaps, edge cases, contradictions with SCOPE.md.

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
