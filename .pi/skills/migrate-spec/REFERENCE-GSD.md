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
- Preserve REQ-XX IDs as **first-class `id:` fields** in `in_scope` entries (see [REFERENCE.md — ID tracking format](./REFERENCE.md#in_scope-format-with-id-tracking))
- Validated requirements → `in_scope` entries with `id:`, `description:`, `source:` fields
- Out-of-Scope → `out_of_scope` entries (preserve IDs if present)
- Active (in-progress) → `in_scope` with status note

---

### `.planning/phases/XX-name/XX-CONTEXT.md` → `specs/tech-architecture/TECH_STACK_LATEST.md` + `specs/adr/`

GSD CONTEXT.md has 6 sections: domain, decisions, canonical_refs, code_context, specifics, deferred.

Transform:
- `domain` → `plans/TECH_STACK_LATEST.md` Domain section
- `decisions` → scan each: if hard-to-reverse + surprising → `specs/adr/NNNN-{slug}.md`; if lightweight → `specs/DECISION-LOG_LATEST.md`
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
