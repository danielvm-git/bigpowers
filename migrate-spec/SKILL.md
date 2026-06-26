---
name: migrate-spec
model: sonnet
description: Detect GSD, spec-kit, or BMAD spec artifacts and transform them into bigpowers YAML layout (state.yaml, release-plan.yaml, epics/, requirements/, plans/, ADRs). Use when migrating foreign spec docs.
---

# Migrate Spec

Transform existing GSD, spec-kit, or BMAD planning artifacts into the bigpowers `specs/` model. No code is written — the output is a set of bigpowers-format spec files the user can use immediately.

## Quick start

1. Run this skill from the root of the project being migrated (not the bigpowers repo itself).
2. The skill auto-detects the source framework and presents its findings before transforming anything.
3. All output goes to `specs/` at the project root.

---

## Red flags — stop and ask

Before proceeding, check for these rationalization traps:

- **Partial artifact set** — only one fingerprint file found (e.g. just `spec.md` with no `plan.md`). Don't assume it's a complete project. Ask: "I found only X — is this the full set of your spec artifacts?"
- **Wrong trigger** — user said "migrate my code" or "migrate the database", not "migrate my specs". Confirm before running.
- **Stale source** — source artifacts have commit dates older than 6 months with no recent activity. Flag: "These specs appear inactive since <date>. Are they still the source of truth?"
- **Active divergence** — source `state.yaml` or `sprint-status.yaml` shows in-progress work. Flag: "There is active work in flight. Migrating now may lose in-progress context. Proceed?"

If any red flag fires: surface it, wait for explicit user confirmation before continuing.

---

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

#### ID Tracking (REQ-XX, FR-XX, UJ-XX)

When source artifacts contain IDs (REQ-XX, FR-XX, UJ-XX), emit them as **first-class YAML fields** in `in_scope` entries, not YAML comments:

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

**When source has no IDs:** Prompt the user: "No IDs found. Assign auto-generated IDs? [yes / no]". If yes, emit `REQ-{NNN}` with `# auto-generated` annotation.

**When source has MIXED IDs:** Items with IDs get `id:` fields; items without IDs receive auto-generated `REQ-NNN` entries. Document which were auto-generated in a comment block at the top of `in_scope`.

See [REFERENCE.md — in_scope format with ID tracking](./REFERENCE.md#in_scope-format-with-id-tracking) for examples.

#### Traceability Output (FR-XX, UJ-XX)

When source has FR-XX or UJ-XX IDs, emit `specs/product/REQUIREMENTS_TRACE.yaml` for end-to-end requirement traceability:

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

**Existing trace file:** If `REQUIREMENTS_TRACE.yaml` already exists, prompt: "REQUIREMENTS_TRACE.yaml exists. [overwrite / merge / skip]"

**No FR-XX/UJ-XX found:** Skip trace file; add note to state.yaml handoff: "No FR-XX/UJ-XX IDs found — traceability file skipped".

See [REFERENCE.md — REQUIREMENTS_TRACE.yaml format](./REFERENCE.md#requirements_traceyaml-format) for the complete schema.

> **HARD GATE** — Never overwrite an existing `specs/` file without explicit user confirmation. Merge into it if it exists; don't clobber.
>
> → verify: `git diff --name-only HEAD -- specs/ 2>/dev/null | head -20`

→ verify: `ls specs/*.md 2>/dev/null | head -15`

### Step 4 — Generate state.yaml

Always regenerate `specs/state.yaml` from scratch in bigpowers YAML format (see REFERENCE.md for template). The **handoff block is mandatory** and must include all four fields:

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

If no open decisions were found during migration, the `open_decisions` list may be empty with an explanatory comment:

```yaml
handoff:
  last_step_completed: "..."
  open_decisions: []  # None — all decisions resolved during migration
  required_reading: [...]
  next_skill: survey-context
```

→ verify: `grep -q 'handoff:' specs/state.yaml && grep -q 'last_step_completed' specs/state.yaml && echo "ok" || echo "MISSING or INCOMPLETE: handoff block"`

### Step 5 — Surface learnings (optional)

After migration, offer the user a brief analysis of what the source framework did that bigpowers doesn't have yet.

Use the learnings table from [REFERENCE.md](./REFERENCE.md#learnings-to-adopt). Present as checkboxes so the user can decide which to adopt.

→ verify: `grep -c "\- \[ \]" specs/state.yaml 2>/dev/null && echo "pending items recorded" || echo "no pending items in state.yaml"`

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

## Rules

- **Preserve source IDs** — REQ-XX, FR-XX, UJ-XX are emitted as first-class `id:` fields in bigpowers YAML targets (e.g., `in_scope` entries). Never silently renumber. See Step 3 ID Tracking subsection for details.
- **Never merge contradictory docs** — if source has both `CONTEXT.md` and `architecture.md`, create sections in bigpowers `CONTEXT.md`; don't collapse them.
- **ADRs are opt-in** — only create an ADR when: hard to reverse, surprising without context, result of a real trade-off. Lightweight decisions go to `specs/DECISION-LOG.md`.
- **state.yaml is always regenerated** — never migrate source STATE verbatim; bigpowers state.yaml needs its own format.
- **specs/ is the only output location** — no files are created outside `specs/` and `CLAUDE.md`.
