# Migrate Spec — Reference

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

### `addendum.md` + `decision-log.md` → `specs/adr/` + `specs/DECISION-LOG_LATEST.md`

Transform:
- Hard, irreversible, surprising decisions → individual `specs/adr/NNNN-{slug}.md`
- Lightweight decisions → `specs/DECISION-LOG_LATEST.md` (date | decision | rationale)
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
- [ ] **`specs/DECISION-LOG_LATEST.md`** — Lightweight decisions below ADR threshold.
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

---

## Reference block 1

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

---

## Reference block 2

```yaml
# CORRECT — first-class id: field
in_scope:
  - id: REQ-001
    description: "User can register with email/password"
    source: "REQUIREMENTS.md"

# DEPRECATED — comment-only
in_scope:
  - "User can register with email/password"  # REQ-001
```

---

## Reference block 3

```yaml
trace:
  - id: FR-001
    type: functional_requirement
    description: "User can register with email/password"
    epic: e02-auth-ui
    story: e02s01
    verify: "grep -q 'FR-001' specs/product/SCOPE_LATEST.yaml && echo OK"
  - id: UJ-001
    type: user_journey
    description: "New user completes registration flow"
    epic: e02-auth-ui
    story: e02s01
```

---

## Reference block 4

```yaml
active_flow: null
active_epic_id: null
active_story_id: null

# ... other state fields ...

handoff:
  last_step_completed: "Migrated from <framework> on <date>"
  open_decisions:
    - "decision text here"
  required_reading:
    - specs/product/VISION_LATEST.yaml
    - specs/product/SCOPE_LATEST.yaml
    - specs/tech-architecture/TECH_STACK_LATEST.md
    - specs/release-plan.yaml
  next_skill: survey-context
```

---

## Reference block 5

```markdown
# Migration Audit — <project-name> from <framework>

**Date:** <ISO 8601 timestamp>
**Status:** Pass / Fail with findings

## Findings

### High Priority
- Artifact: specs/epics/e02-auth-ui/epic.yaml
  Finding: No verify: commands in story tasks
  Recommendation: Add `verify:` to each task before develop-tdd

### Information
- Count of TODO markers: 3 (normal for fresh migration)
```

---

## Reference block 6

```
Which lenses to include in specs/tech-architecture/METHODOLOGY_LATEST.md?

[x] Cost of Delay (CD3)           — Priority & trade-off assessment
[ ] STRIDE                        — Security threat modeling
[ ] F.I.R.S.T                     — Test quality principles
[ ] Bayesian Updating            — Probabilistic decision-making
[ ] OWASP Top 10                 — Web security framework
```

---

### Step 7 — Post-migration: Optional two-pass spec writing gate

After Steps 1–6, offer the user an optional two-pass spec writing workflow (spec-kit learning):

Prompt: "Use two-pass spec writing (user journeys first, then technical)? [yes / no]"

If **yes**, initialize the gate in `specs/state.yaml`:

```yaml
two_pass_spec:
  journey_pass: pending
  technical_pass: pending
  approved_at: null
```

The journey pass must be marked "complete" by the user (after stakeholder approval of user-journey specs) before the technical pass begins:

```yaml
two_pass_spec:
  journey_pass: complete
  approved_at: "2026-06-26T12:00:00Z"
  technical_pass: pending
```

Inform the user: "Journey pass is pending. Run `elaborate-spec` for user journeys, get stakeholder approval, then update `two_pass_spec.journey_pass: complete` in state.yaml before proceeding to technical specs."

If **no**, skip the two-pass gate. Proceed directly to plan-work.

→ verify: `grep -q 'two_pass_spec:' specs/state.yaml && echo "two-pass gate initialized" || echo "two-pass gate not activated"`


---

### Step 8 — Post-migration: Optional methodology doc template

After Steps 1–7, offer the user an optional analytical framework scaffold (GSD learning):

Prompt: "Create a methodology doc? [yes / no]"

If **yes**, present a checklist of analytical lenses:

```
Which lenses to include in specs/tech-architecture/METHODOLOGY_LATEST.md?

[x] Cost of Delay (CD3)           — Priority & trade-off assessment
[ ] STRIDE                        — Security threat modeling
[ ] F.I.R.S.T                     — Test quality principles
[ ] Bayesian Updating            — Probabilistic decision-making
[ ] OWASP Top 10                 — Web security framework
```

Copy the template from `migrate-spec/templates/METHODOLOGY_LATEST.md` to `specs/tech-architecture/METHODOLOGY_LATEST.md`.
- Active lenses remain uncommented
- Unselected lenses are left commented out
- Populate `{{project_name}}` with the migrated project's name

If **no**, skip. Add note to handoff: "Methodology doc: skipped — can be added later via `cp migrate-spec/templates/METHODOLOGY_LATEST.md specs/tech-architecture/`"

→ verify: `test -f specs/tech-architecture/METHODOLOGY_LATEST.md && echo "methodology doc created" || echo "methodology doc skipped"`

---


---

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

---


---

## Rules

- **Preserve source IDs** — REQ-XX, FR-XX, UJ-XX are emitted as first-class `id:` fields in bigpowers YAML targets (e.g., `in_scope` entries). Never silently renumber. See Step 3 ID Tracking subsection for details.
- **Never merge contradictory docs** — if source has both `CONTEXT.md` and `architecture.md`, create sections in bigpowers `CONTEXT.md`; don't collapse them.
- **ADRs are opt-in** — only create an ADR when: hard to reverse, surprising without context, result of a real trade-off. Lightweight decisions go to `specs/DECISION-LOG_LATEST.md`.
- **state.yaml is always regenerated** — never migrate source STATE verbatim; bigpowers state.yaml needs its own format.
- **specs/ is the only output location** — no files are created outside `specs/` and `CLAUDE.md`.

---

### Step 5 — Surface learnings (optional)

After migration, offer the user a brief analysis of what the source framework did that bigpowers doesn't have yet.

Use the learnings table from [REFERENCE.md](./REFERENCE.md#learnings-to-adopt). Present as checkboxes so the user can decide which to adopt.

→ verify: `grep -c "\- \[ \]" specs/state.yaml 2>/dev/null && echo "pending items recorded" || echo "no pending items in state.yaml"`


---

### Step 6 — Adversarial review (optional)

Before the user runs `plan-work`, offer an optional lightweight audit of the migrated artifacts. This catches common migration errors early — incomplete specs, missing verification commands, unresolved decisions.

Prompt: "Run adversarial review of migrated artifacts? [yes / skip]"

If yes, perform these checks:

1. **Scan for incomplete markers** — Find TODO, FIXME, MISSING in specs/
2. **Verify every epic has `verify:` commands** — Parse all `eNN-*/epic.yaml` files
3. **Check state.yaml handoff** — Ensure `open_decisions` is documented (even if empty)

Collect findings and write to `specs/archive/MIGRATION-AUDIT.md`:

```markdown
# Migration Audit — <project-name> from <framework>

**Date:** <ISO 8601 timestamp>
**Status:** Pass / Fail with findings


---

## Findings

### High Priority
- Artifact: specs/epics/e02-auth-ui/epic.yaml
  Finding: No verify: commands in story tasks
  Recommendation: Add `verify:` to each task before develop-tdd

### Information
- Count of TODO markers: 3 (normal for fresh migration)
```

If findings exist, the handoff block should note: "Adversarial review: N findings — see `specs/archive/MIGRATION-AUDIT.md`"

If skip is chosen, add to handoff: "Adversarial review: skipped — review manually before plan-work"

→ verify: `test -f specs/archive/MIGRATION-AUDIT.md && echo "audit completed" || echo "audit skipped or not performed"`
