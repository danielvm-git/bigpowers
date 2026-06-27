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

See [REFERENCE.md](REFERENCE.md) — `Detected: GSD...`

→ verify: `find . -maxdepth 4 \( -name "ROADMAP.md" -o -name "spec.md" -o -name "prd.md" -o -name "REQUIREMENTS.md" \) 2>/dev/null | grep -v ".git" | head -15`

### Step 3 — Transform (one artifact at a time, show diffs)

Apply the mapping from [REFERENCE.md](./REFERENCE.md) and [REFERENCE-GSD.md](./REFERENCE-GSD.md). For each target file:

1. Show what will be created or appended (title + first 20 lines).
2. Ask: "Create this? [yes / edit / skip]"
3. On yes: write to `specs/`.

#### ID Tracking (REQ-XX, FR-XX, UJ-XX)

When source artifacts contain IDs (REQ-XX, FR-XX, UJ-XX), emit them as **first-class YAML fields** in `in_scope` entries, not YAML comments:

See [REFERENCE.md](REFERENCE.md) — `# CORRECT — first-class id: field...`

**When source has no IDs:** Prompt the user: "No IDs found. Assign auto-generated IDs? [yes / no]". If yes, emit `REQ-{NNN}` with `# auto-generated` annotation.

**When source has MIXED IDs:** Items with IDs get `id:` fields; items without IDs receive auto-generated `REQ-NNN` entries. Document which were auto-generated in a comment block at the top of `in_scope`.

See [REFERENCE.md — in_scope format with ID tracking](./REFERENCE.md#in_scope-format-with-id-tracking) for examples.

#### Traceability Output (FR-XX, UJ-XX)

When source has FR-XX or UJ-XX IDs, emit `specs/product/REQUIREMENTS_TRACE.yaml` for end-to-end requirement traceability:

See [REFERENCE.md](REFERENCE.md) — `trace:...`

**Existing trace file:** If `REQUIREMENTS_TRACE.yaml` already exists, prompt: "REQUIREMENTS_TRACE.yaml exists. [overwrite / merge / skip]"

**No FR-XX/UJ-XX found:** Skip trace file; add note to state.yaml handoff: "No FR-XX/UJ-XX IDs found — traceability file skipped".

See [REFERENCE.md — REQUIREMENTS_TRACE.yaml format](./REFERENCE.md#requirements_traceyaml-format) for the complete schema.

> **HARD GATE** — Never overwrite an existing `specs/` file without explicit user confirmation. Merge into it if it exists; don't clobber.
>
> → verify: `git diff --name-only HEAD -- specs/ 2>/dev/null | head -20`

→ verify: `ls specs/*.md 2>/dev/null | head -15`

### Step 4 — Generate state.yaml

Always regenerate `specs/state.yaml` from scratch in bigpowers YAML format (see REFERENCE.md for template). The **handoff block is mandatory** and must include all four fields:

See [REFERENCE.md](REFERENCE.md) — `active_flow: null...`

If no open decisions were found during migration, the `open_decisions` list may be empty with an explanatory comment:

See [REFERENCE.md](REFERENCE.md) — `handoff:...`

→ verify: `grep -q 'handoff:' specs/state.yaml && grep -q 'last_step_completed' specs/state.yaml && echo "ok" || echo "MISSING or INCOMPLETE: handoff block"`
