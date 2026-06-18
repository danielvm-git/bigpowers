---
description: "RELEASE-INDEX BUILDER — Sequence elaborated epics into specs/release-plan.yaml with WSJF ordering and BCP baselines. NOT a planning-spine substitute: it does not scope work (scope-work) or write story tasks (plan-work). Use after elaborate-spec when the user wants a versioned release index of epics."
---


# Plan Release

> **HARD GATE** — Do NOT run this skill unless `elaborate-spec` has produced a clear spec or the user has already defined the feature in detail. If the problem is still fuzzy, run `elaborate-spec` first.

> **HARD GATE** — `specs/product/SCOPE_LATEST.yaml` (or legacy `specs/product/SCOPE_LATEST.yaml`) must exist. If missing, run `scope-work` first.

Synthesize the conversation context into `specs/release-plan.yaml` (index) and shard detail under `specs/epics/`. No new interview — only clarify if something is genuinely ambiguous.

## Outputs

| File | Content |
|------|---------|
| `specs/release-plan.yaml` | `release.version`, semver bump hint, WSJF-ordered epic list with `id`, `capsule_dir`, `wsjf`, `bcps` — **no story status** |
| `specs/epics/eNN-<slug>/epic.yaml` | Epic manifest: `id`, `title`, `wsjf`, `total_bcps`, `status`, `stories[]` list |
| `specs/epics/eNN-<slug>/eNNsYY-<slug>.md` | Story spec in [countable-story-format.md](file:///Users/danielvm/Developer/bigpowers/countable-story-format.md) with 20 sections and Gherkin acceptance criteria |
| `specs/epics/eNN-<slug>/eNNsYY-tasks.yaml` | Decoupled task checklist with `verify:` commands per task |
| `specs/execution-status.yaml` | Flat key-value store for story status (`eNNsYY: todo`) |

## Epic Capsule Structure

All epics use capsule directories (no flat/folder distinction):

```
specs/epics/e01-auth-system/
├── epic.yaml              # Epic manifest
├── adr/                   # Epic-local ADRs (created lazily)
├── e01s01-login.md        # Story spec (countable-story-format)
├── e01s01-tasks.yaml      # Decoupled task checklist
├── e01s02-jwt.md          # Story spec
└── e01s02-tasks.yaml      # Decoupled task checklist
```

**Rationale:** Capsule dirs achieve change isolation (C9), enable archive pruning (C2/C6), and enforce SRP by decoupling spec `.md` from execution `-tasks.yaml` (C1). See `sdd-adequacy-ranking.md` for the full 10-criteria scoring.

## Process

### 1. Draft epics and stories

From the conversation context, define:
- **Epics** — `e01`, `e02`, … (stable IDs; WSJF order in `release-plan.yaml` only)
- **Stories** — `e01s01`, `e01s02`, … with Gherkin acceptance criteria

WSJF-sort epics: score = (Business Value + Time Criticality + Risk Reduction) / Job Size. Highest score first.

### 2. Write acceptance criteria (Gherkin)

For each story, write at least one happy-path and one edge-case scenario (countable format §17 if maturity ≥ 3).

### 3. Write tasks with verify commands

Every task must have a `verify:` command. No verify command = not a task.

### 4. Save specs/release-plan.yaml

```yaml
release:
  version: "3.0.0"
  codename: "Feature Name"
  status: planning          # planning | in_progress | released
  semantic_release: true
  bump_hint: minor          # patch | minor | major — CI decides at merge
epics:
  - id: e01
    title: Auth System
    wsjf: 4.5
    capsule_dir: epics/e01-auth-system
  - id: e02
    title: User Profile
    wsjf: 3.8
    capsule_dir: epics/e02-user-profile
```

### 5. Save epic manifest (`epic.yaml`)

Each epic capsule directory contains an `epic.yaml` manifest:

```yaml
id: e01
title: Auth System
wsjf: 4.5
total_bcps: 8
status: in_progress
stories:
  - id: e01s01
    title: Login
    bcps: 3
    status: todo
    spec: e01s01-login.md
    tasks: e01s01-tasks.yaml
  - id: e01s02
    title: JWT Token Management
    bcps: 5
    status: todo
    spec: e01s02-jwt.md
    tasks: e01s02-tasks.yaml
```

### 6. Save story specs (countable-story-format .md)

Each story becomes a standalone `.md` file following [countable-story-format.md](file:///Users/danielvm/Developer/bigpowers/countable-story-format.md). Minimum: maturity 3 (Countable) with all 20 sections present. Acceptance criteria in §17 use Gherkin scenarios.

### 7. Save decoupled task files (`-tasks.yaml`)

Each story has a decoupled `-tasks.yaml` with implementation steps:

```yaml
story_id: e01s01
title: Login
status: todo
bcps: 3
tasks:
  - id: 1
    description: "Add login form component tests"
    verify: "npm test -- login-form.test.tsx"
    status: todo
  - id: 2
    description: "Implement login form with validation"
    verify: "npm test -- login-form.test.tsx"
    status: todo
```

> **HARD GATE** — Every task MUST have a runnable `verify:` command. No `verify:` = not a task.

→ verify: `bash scripts/validate-specs-yaml.sh`

### 8. Sync execution status

```bash
bash scripts/sync-status-from-epics.sh
```

### 9. Snapshot on planning close (optional)

Copy to `specs/product/snapshots/release-<version>/` when the user approves the plan.

### 10. Suggest next steps

- Run `assess-impact` before `plan-work` for any story touching existing modules.
- Run `plan-work` per story for detailed steps inside the epic shard.
- Run `change-request` if a new requirement arrives mid-flight.
