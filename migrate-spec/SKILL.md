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

> **HARD GATE** — Never overwrite an existing `specs/` file without explicit user confirmation. Merge into it if it exists; don't clobber.
>
> → verify: `git diff --name-only HEAD -- specs/ 2>/dev/null | head -20`

→ verify: `ls specs/*.md 2>/dev/null | head -15`

### Step 4 — Generate state.yaml

Always regenerate `specs/state.yaml` from scratch in bigpowers format:

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

→ verify: `[ -f specs/state.yaml ] && echo "ok" || echo "MISSING: specs/state.yaml not created"`

### Step 5 — Surface learnings (optional)

After migration, offer the user a brief analysis of what the source framework did that bigpowers doesn't have yet.

Use the learnings table from [REFERENCE.md](./REFERENCE.md#learnings-to-adopt). Present as checkboxes so the user can decide which to adopt.

→ verify: `grep -c "\- \[ \]" specs/state.yaml 2>/dev/null && echo "pending items recorded" || echo "no pending items in state.yaml"`

---

## Artifact Mapping Summary

Full mapping tables: [REFERENCE-GSD.md](./REFERENCE-GSD.md) (GSD) · [REFERENCE.md](./REFERENCE.md) (spec-kit, BMAD, learnings).

| Source | Target |
|--------|--------|
| GSD `ROADMAP.md` | `specs/release-plan.yaml + epic shards` |
| GSD `REQUIREMENTS.md` | `specs/requirements/SCOPE_LATEST.yaml` |
| GSD `CONTEXT.md` (phases) | `specs/plans/TECH_STACK_LATEST.md` + `specs/adr/` |
| GSD `PLAN.md` | `specs/epics/eNN-*.yaml` (tasks with verify) |
| GSD `METHODOLOGY.md` | `specs/plans/METHODOLOGY_LATEST.md` |
| spec-kit `spec.md` | `specs/requirements/SCOPE_LATEST.yaml` + `specs/plans/TECH_STACK_LATEST.md` |
| spec-kit `plan.md` | `specs/plans/TECH_STACK_LATEST.md` + `specs/release-plan.yaml` + `specs/epics/` |
| spec-kit `tasks.md` | `specs/epics/ (see slice-tasks)` |
| BMAD `prd.md` | `specs/requirements/SCOPE_LATEST.yaml` |
| BMAD `architecture.md` | `specs/plans/TECH_STACK_LATEST.md` + `specs/adr/` |
| BMAD `epic-*.md` | `specs/release-plan.yaml + epic shards` |
| BMAD `story-*.md` | `specs/epics/ (see slice-tasks)` |
| BMAD `project-context.md` | `CLAUDE.md` (append project-specific section) |
| BMAD `decision-log.md` | `specs/adr/` (one ADR per logged decision) |

---

## Rules

- **Preserve source IDs** — REQ-XX, FR-XX, UJ-XX become inline comments in bigpowers targets. Never silently renumber.
- **Never merge contradictory docs** — if source has both `CONTEXT.md` and `architecture.md`, create sections in bigpowers `CONTEXT.md`; don't collapse them.
- **ADRs are opt-in** — only create an ADR when: hard to reverse, surprising without context, result of a real trade-off. Lightweight decisions go to `specs/DECISION-LOG.md`.
- **state.yaml is always regenerated** — never migrate source STATE verbatim; bigpowers state.yaml needs its own format.
- **specs/ is the only output location** — no files are created outside `specs/` and `CLAUDE.md`.
