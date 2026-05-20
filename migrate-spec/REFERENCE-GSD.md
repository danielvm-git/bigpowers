# migrate-spec Reference — GSD

Full artifact transformation rules for migrating GSD projects to bigpowers.

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

### `.planning/ROADMAP.md` → `specs/RELEASE-PLAN.md`

GSD ROADMAP has: milestone name, phases, success criteria per phase, plan count.

bigpowers RELEASE-PLAN needs: release version, status, WSJF, focus, objective.

Transform:
- Each GSD phase → one release entry in RELEASE-PLAN.md
- Phase name → release name (add version number e.g. v1.0.0)
- GSD success criteria → "Success Criteria" subsection under each release entry
- Phase plan count → "Job Size" hint for WSJF (ask user to score)
- Completed phases → `✅` status; active phase → `⏳`; future phases → `📋`

---

### `.planning/REQUIREMENTS.md` → `specs/SCOPE.md`

GSD REQUIREMENTS has: REQ-XX IDs, Validated/Active/Out-of-Scope categories, traceability.

Transform:
- Copy REQ-XX IDs as-is (preserve for cross-referencing)
- Validated requirements → "In Scope" section
- Out-of-Scope → "Out of Scope" section
- Active (in-progress) → "In Scope (WIP)" section
- Add header: `# Scope — migrated from GSD REQUIREMENTS.md`

---

### `.planning/phases/XX-name/XX-CONTEXT.md` → `specs/CONTEXT.md` + `specs/adr/`

GSD CONTEXT.md has 6 sections: domain, decisions, canonical_refs, code_context, specifics, deferred.

Transform:
- `domain` → `specs/CONTEXT.md` Domain section (domain model, terms, aggregates)
- `decisions` → scan each: if hard-to-reverse + surprising → `specs/adr/NNNN-{slug}.md`; if lightweight → `specs/DECISION-LOG.md`
- `canonical_refs` → Reference links in CONTEXT.md
- `code_context` → `specs/CONTEXT.md` Architecture section
- `specifics` → merge into relevant CONTEXT.md section
- `deferred` → `specs/SCOPE.md` Out-of-Scope section (with "(deferred from GSD)" note)

---

### `.planning/phases/XX-name/XX-YY-PLAN.md` → `specs/PLAN-vX.Y.Z.md`

GSD PLAN has: frontmatter (depends-on, verify), objective, typed tasks, success criteria, output spec.

Transform:
- Preserve task structure
- Keep `verify: <command>` lines (same format bigpowers uses)
- Map GSD `depends-on` to a "Dependencies" note in bigpowers PLAN header
- Add bigpowers frontmatter with release version
- SUMMARY.md (execution record) → append as "## Execution Record" if needed; otherwise skip

---

### `.planning/METHODOLOGY.md` → `specs/SPIKE-methodology.md`

GSD METHODOLOGY.md is a standing reference for analytical lenses (Bayesian updating, STRIDE, cost-of-delay). bigpowers has no direct equivalent.

Transform:
- Copy each lens as a section in `specs/SPIKE-methodology.md`
- Add header: `# Project Methodology — migrated from GSD`
- Note: "These lenses should inform `plan-work` and `audit-code` sessions."

---

### `.planning/HANDOFF.json` + `.continue-here.md` → `specs/STATE.md` (resume block)

GSD HANDOFF has: current phase, last plan, blocking reason, required reading list.

Transform — add a "## Session Resume" block to `specs/STATE.md`:

```markdown
## Session Resume

- Last active: <phase/plan from HANDOFF>
- Blocking: <reason if any>
- Required reading before next session: <required_reading list>
```

---

### `.planning/spikes/SPIKE-NNN/README.md` → `specs/SPIKE-{name}.md`

GSD spike README has: YAML frontmatter (verdict, validates, related), methodology, findings, recommendation.

Transform:
- Flatten directory into single `specs/SPIKE-{name}.md`
- Preserve frontmatter as YAML block comment at top
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
