---
name: survey-context
model: haiku
description: Per-task context bootstrap — reads existing specs/ and tech-architecture docs to map the current lifecycle phase and suggest the next skill. Use at the start of any task, when returning after a break, or when unsure what to do next. For deriving a tech-stack doc from scratch, use map-codebase first.
---

# Survey Context

Read the project's current state and give a phase map + next-skill recommendation. This is the "where am I?" skill — run it at the start of every task.

> **Use this vs map-codebase:** `survey-context` consumes existing specs and docs (fast; does not re-derive). `map-codebase` builds the tech-stack doc from scratch by scanning the codebase. Run `map-codebase` when `specs/tech-architecture/tech-stack.md` doesn't exist yet; run `survey-context` when it does.

> **HARD GATE** — Read specs/ files before suggesting next steps. If state.yaml is stale or contradicts the codebase, request clarification rather than assuming intent.

Orchestrate-project 6 phases: Phase 1 Discover - Phase 2 Elaborate - Phase 3 Plan - Phase 4 Build - Phase 5 Verify - Phase 6 Release

## Process

> **Timing:** `bash scripts/bp-timing.sh start survey-context` at invocation; `bash scripts/bp-timing.sh end survey-context` before handoff.

### 1. Read CONVENTIONS.md

If `CONVENTIONS.md` exists at the project root, read it first. It contains the rules all agents must follow in this project.

### 2. Read specs/ (YAML-first)

Scan the `specs/` directory if it exists:

```
specs/
├── state.yaml                  → session: active_flow, epic, git, handoff
├── release-plan.yaml           → target version, WSJF epic index
├── execution-status.yaml       → flat story/epic status
├── planning-status.yaml        → discover-phase checklist (optional)
├── requirements/
│   ├── VISION_LATEST.yaml
│   ├── SCOPE_LATEST.yaml
│   └── GLOSSARY_LATEST.yaml
├── plans/                      → TECH_STACK, TEST_PLAN, etc.
├── epics/                      → eNN shards (flat yaml or eNN/stories/)
└── bugs/                       → BUG-*.md + registry.yaml
```

For each YAML file found, note: exists? keys populated? `handoff.next_skill`?

Legacy markdown (`specs/archive/STATE.md`, `RELEASE-PLAN.md`) is **not** SoT if YAML exists.

→ verify: `bash scripts/validate-specs-yaml.sh 2>/dev/null || echo "YAML layout incomplete"`

### 3. Read CLAUDE.md

If `CLAUDE.md` exists at the project root, read it for project context (stack, commands, architecture, conventions).

### 4. Check git state

```bash
git status --short
git log --oneline -5
git branch --show-current
```

Note: is there a feature branch active? Are there uncommitted changes? Do they match `specs/state.yaml` `git` block?

### 5. Map the lifecycle phase

Based on what you've found, identify which PMBOK phase this project is currently in:

| Phase | Signals |
|-------|---------|
| **Discover** | No `requirements/SCOPE_LATEST.yaml` yet, or only rough notes |
| **Design** | SCOPE exists but no `release-plan.yaml` |
| **Plan** | `release-plan.yaml` exists; on `main`/`master` branch |
| **Initiate** | On a feature branch; no code changes yet |
| **Execute** | `state.yaml` `active_flow: build_epic`; epic capsule in progress |
| **Verify** | Implementation done; run `verify-work` or `run-evals` |
| **Bug** | `state.yaml` `active_flow: fix_bug` or open `specs/bugs/BUG-*.md` |
| **Review** | All code written; no PR yet |
| **Integrate** | PR open; tests passing |
| **Sustain** | Ongoing; no active task |

Prefer `specs/state.yaml` `active_flow` and `handoff.next_skill` when present.

### 6. Suggest next skill

Based on the phase and state, recommend the most useful next step:

- **If in Plan/Bug phase and on `main`**: Suggest `kickoff-branch` next.
- **If in Initiate phase**: Suggest `develop-tdd` or `execute-plan` or `ship-epic`.
- **If in Execute phase**: Suggest `ship-epic` (resume) or `develop-tdd` for `active_story_id`.
- **If in Verify phase**: Suggest `verify-work` (UAT) or `run-evals`.

Example:
```
Phase: Execute
Active branch: feat/e02-verify (state.yaml matches)
release-plan.yaml: v3.0.0, 10 epics
active_epic_id: e02

Suggested next: ship-epic (resume e02s01 at develop-tdd)
```

Be specific — name the exact skill and why. If multiple options exist, list them in priority order.

### 7. Surface blockers

If something looks wrong:
- Broken tests in the baseline
- Open `specs/bugs/BUG-*.md` with no active fix branch
- Epic shards missing `verify:` on tasks
- `validate-specs-yaml.sh` fails
- Git hash in `state.yaml` stale vs `git rev-parse`

Report blockers first, before recommendations.

### 8. Record story start timestamp

At story start, write `metrics.story_start` with the current ISO 8601 timestamp to `specs/state.yaml` for cycle-time tracking.

## Utility outputs

### list-epics (absorbed)

Loop through all `specs/epics/*/epic.yaml` files and print a summary of story counts per epic. Useful for understanding overall project scope and epic distribution.

### check-gates (absorbed)

Print the current `active_flow` from `specs/state.yaml`, run `bash scripts/validate-specs-yaml.sh` to verify YAML integrity, and show `git status` to report uncommitted changes and branch state. Use before handoffs or context transitions.

## Handoff

Gate: READY -> next: plan-work
Writes: state.yaml handoff.next_skill = plan-work
