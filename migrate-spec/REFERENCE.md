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

- [x] **`specs/tech-architecture/METHODOLOGY_LATEST.md`** — Standing analytical lenses. Agents read before planning. (adopted: optional Step 8 template scaffold)
- [x] **`handoff` block in state.yaml** — Last skill, last step, required reading for next session. (adopted: mandatory in Step 4 output)
- [x] **ID tracking in SCOPE_LATEST.yaml** — FR/UJ IDs for spec → plan → verification traceability. (adopted in Step 3 transform)

### From spec-kit

- [x] **Two-pass spec writing** — User-journey pass first, then technical-decisions pass. (adopted: optional post-migration gate)
- [ ] **Explicit inter-phase gate** — "Approve to proceed?" at end of `elaborate-spec`.
- [ ] **Epic task isolation** — Each task completable in isolation; `depends-on` explicit in epic YAML.

### From BMAD

- [x] **FR-XX + UJ-XX in SCOPE_LATEST.yaml** — Rigorous traceability. (adopted: REQUIREMENTS_TRACE.yaml emitted on migration)
- [ ] **`specs/DECISION-LOG.md`** — Lightweight decisions below ADR threshold.
- [x] **Adversarial review pass** — Critique epic shard before `develop-tdd`. (adopted: optional Step 6 in migration)

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

### MIGRATION-AUDIT.md format

Post-migration adversarial review report. Written to `specs/archive/MIGRATION-AUDIT.md` when Step 6 runs:

```markdown
# Migration Audit — <project-name>

**Source Framework:** <GSD|spec-kit|BMAD>  
**Date:** <ISO 8601>  
**Status:** <Pass|Findings|Critical>

## Summary

- TODO markers: N
- FIXME markers: N
- MISSING markers: N
- Epics without verify: N

## High Priority Findings

- **Artifact:** specs/epics/e02-auth-ui/epic.yaml
  **Issue:** Story e02s01 has no verify: commands in tasks
  **Recommendation:** Add runnable verify command before develop-tdd

- **Artifact:** specs/state.yaml
  **Issue:** open_decisions list empty without comment explanation
  **Recommendation:** Add # comment if all decisions were resolved during migration

## Information

- Artifact specs/epics/e01-auth/epic.yaml contains TODO: "Define Neon Auth client URL injection" (normal for fresh migration)

## Next Steps

1. Address high-priority findings before plan-work
2. Run bash scripts/audit-compliance.sh to enforce code quality gates
3. Begin develop-tdd on highest-WSJF epic
```

### in_scope format with ID tracking

Source IDs (REQ-XX, FR-XX, UJ-XX) are emitted as first-class YAML fields:

```yaml
in_scope:
  - id: REQ-001
    description: "User can register with email and password"
    source: "REQUIREMENTS.md"
  - id: FR-015
    description: "Auth service must support OAuth2 token flow"
    source: "prd.md"
  - id: REQ-AUTO-002  # auto-generated when source had no ID
    description: "Dashboard displays user profile"
    # auto-generated: true  (optional comment for tracking)
```

**When source has no IDs:** If the user opts in, auto-generated IDs follow the `REQ-{NNN}` format with an optional `# auto-generated` comment.

**When source has mixed IDs:** Entries with source IDs get `id:` fields; entries without IDs receive auto-generated IDs. A comment block at the top of `in_scope` documents which IDs were auto-generated.

### REQUIREMENTS_TRACE.yaml format

Emitted when source has FR-XX (functional requirement) or UJ-XX (user journey) IDs. Maps source requirements to bigpowers epic/story structure and verification commands:

```yaml
trace:
  # Functional Requirements
  - id: FR-001
    type: functional_requirement
    description: "User can register with email/password"
    source_artifact: "prd.md"
    epic: "e02-auth-ui"
    story: "e02s01"
    verify: "grep -q 'FR-001' specs/product/SCOPE_LATEST.yaml && echo OK"

  # User Journeys
  - id: UJ-001
    type: user_journey
    description: "New user completes registration flow"
    source_artifact: "epic-auth-ui.md"
    epic: "e02-auth-ui"
    story: "e02s01"
    verify: "grep -q 'UJ-001' specs/epics/e02-auth-ui/epic.yaml && echo OK"

metadata:
  source_framework: "BMAD"
  migrated_at: "2026-06-26T12:00:00Z"
  total_requirements: 2
  coverage: "All FR-XX and UJ-XX IDs from source mapped"
```

**When source has no FR-XX/UJ-XX:** Skip REQUIREMENTS_TRACE.yaml. Add note to `state.yaml` handoff: "No FR-XX/UJ-XX IDs found — traceability file skipped".

**Existing trace file:** If REQUIREMENTS_TRACE.yaml exists, prompt user: "Overwrite? [yes / merge / skip]". Merge appends new entries; skip leaves existing file intact.

### `specs/state.yaml` template format

Generated during Step 4 of migration. Regenerate from scratch in bigpowers YAML format. The **handoff block is mandatory**:

```yaml
active_flow: null
active_epic_id: null
active_story_id: null
completed_epic: false

epic_cycle:
  current_step: null
  next_skill: null
  story_bcps: null
  completed_steps: []
  audit_result: null

bug_cycle:
  current_step: null
  completed_steps: []

release:
  target_version: null
  last_tag: null
  last_publish: null
  ci_verified: false

metrics:
  story_start: null
  story_end: null
  cycle_minutes: null
  bcp_per_hour: null

git:
  branch: <current branch>
  hash: <git rev-parse HEAD>
  pushed: false

handoff:
  last_step_completed: "Migrated from <framework> on <date>"
  open_decisions: []  # Empty if all decisions resolved during migration
  required_reading:
    - specs/product/VISION_LATEST.yaml
    - specs/product/SCOPE_LATEST.yaml
    - specs/tech-architecture/TECH_STACK_LATEST.md
    - specs/release-plan.yaml
  next_skill: survey-context

two_pass_spec:  # Optional: only if user activates two-pass spec writing gate
  journey_pass: pending
  technical_pass: pending
  approved_at: null
```
