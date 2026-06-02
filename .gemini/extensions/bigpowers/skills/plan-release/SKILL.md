---
name: plan-release
description: "Convert elaborated specs into a structured release plan with Gherkin acceptance criteria and WSJF-sorted epics. Produces specs/release-plan.yaml and specs/epics/eNN-*.yaml. Use when a spec is clear and ready to plan, after elaborate-spec, or when the user wants a release plan broken into epics and stories."
---


# Plan Release

> **HARD GATE** — Do NOT run this skill unless `elaborate-spec` has produced a clear spec or the user has already defined the feature in detail. If the problem is still fuzzy, run `elaborate-spec` first.

> **HARD GATE** — `specs/requirements/SCOPE_LATEST.yaml` (or legacy `specs/requirements/SCOPE_LATEST.yaml`) must exist. If missing, run `scope-work` first.

Synthesize the conversation context into `specs/release-plan.yaml` (index) and shard detail under `specs/epics/`. No new interview — only clarify if something is genuinely ambiguous.

## Outputs

| File | Content |
|------|---------|
| `specs/release-plan.yaml` | `release.version`, semver bump hint, WSJF-ordered epic list (`id: e01`, `file:`, `mode:`) — **no story status** |
| `specs/epics/eNN-<slug>.yaml` | Epic metadata, `covers: [fr-x]`, stories with tasks and `verify:` |
| `specs/execution-status.yaml` | Regenerate keys via `bash scripts/sync-status-from-epics.sh` after epics exist |

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
    title: Security
    wsjf: 4.5
    file: epics/e01-security.yaml
    mode: flat              # flat | folder (folder if >5 stories)
  - id: e02
    title: Verification
    wsjf: 4.3
    file: epics/e02-verification/epic.yaml
    mode: folder
```

### 5. Save epic shards

**Flat** (`mode: flat`, ≤ ~5 stories):

```yaml
id: e01
title: Security
wsjf: 4.5
covers: [fr-08]
stories:
  - id: e01s01
    title: Guard git hooks
    tasks:
      - desc: Block push on main
        verify: "grep -q guard-git .cursor/rules/guard-git.mdc"
```

**Folder GSD** (`mode: folder`): `epics/e02-verification/epic.yaml` + `stories/e02s01-*.md` with YAML frontmatter for tasks.

→ verify: `bash scripts/validate-specs-yaml.sh`

→ verify: `grep -c 'id: e' specs/release-plan.yaml`

### 6. Sync execution status

```bash
bash scripts/sync-status-from-epics.sh
```

### 7. Snapshot on planning close (optional)

Copy to `specs/requirements/snapshots/release-<version>/` when the user approves the plan.

### 8. Suggest next steps

- Run `assess-impact` before `plan-work` for any story touching existing modules.
- Run `plan-work` per story for detailed steps inside the epic shard.
- Run `change-request` if a new requirement arrives mid-flight.
