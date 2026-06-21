---
name: orchestrate-project
model: sonnet
description: Meta-skill that enforces the 6-phase core loop (discover → elaborate → plan → build → verify → release) with hard gates. Use to coordinate multi-phase projects with guaranteed quality checkpoints. One-time command for the entire project lifecycle.
---

# Orchestrate
> **HARD GATE** — **HARD GATE** — Do NOT invoke orchestrate-project unless you have a clear multi-phase workflow. Single-skill tasks should use dedicated skills instead. Orchestrate is for complex, multi-stage work that requires coordination across phases.


The orchestrate skill coordinates projects through a prescriptive 6-phase core loop with hard gates, ensuring consistent quality and preventing scope creep.

## Quick Start

```bash
# Start a new project (initializes specs/ YAML cockpit and begins discover phase)
claude /orchestrate --mode standard

# Or resume an existing project at the current phase
claude /orchestrate --mode standard --resume

# For low-risk scenarios (hotfixes, refactors on well-tested code)
claude /orchestrate --mode fast-track
```

## The 6-Phase Core Loop

1. **DISCOVER** (3-6 hours): Understand problem. Deliverables: `requirements/VISION_LATEST.yaml`, `requirements/SCOPE_LATEST.yaml`, `plans/TECH_STACK_LATEST.md`.
2. **ELABORATE** (3-6 hours): Research solutions. Deliverables: Prior art in scope YAML, ADRs in `specs/adr/`.
3. **PLAN** (2-4 hours): Write verifiable plan. Deliverables: `release-plan.yaml`, `epics/eNN-*.yaml` with `verify:` per task.
4. **BUILD** (1-8 hours): Execute plan. Runs build-epic once per story in WSJF order. Deliverables: Code; update `execution-status.yaml`.
5. **VERIFY** (1-3 hours): Validate success criteria. Deliverables: UAT evidence, `specs/EVALS-*.md` if used.
6. **RELEASE** (30 min - 2 hours): Ship to production. Deliverables: Release tag (vX.Y.Z), `state.yaml` `release.last_tag`.

### Checkpoint / resume

Track progress via `specs/state.yaml` `project_cycle`:
- `project_cycle.current_phase`: current phase (1–6)
- `project_cycle.completed_phases`: completed phase numbers
- `handoff.next_skill`: skill for the current phase
- On resume, read `project_cycle.current_phase` and continue from there

See [REFERENCE.md](REFERENCE.md) for detailed phase specifications and gate types.

## How Orchestrate Works

1. **Maintains state.yaml** — Tracks current phase, `active_epic`, `active_flow`, decisions, risks.
2. **Spawns appropriate skills** — Routes by `model:` frontmatter. Decisions pass only via `specs/state.yaml` `handoff` between spawns.
3. **Methodology lenses** — If `specs/tech-architecture/test.md` or ADRs exist, apply at phase gates.
4. **Enforces gates** — Hard stops if success criteria not met.
5. **The Gatekeeper** — Between stories in BUILD: read `specs/execution-status.yaml`; previous story must be `done` before starting the next; use `build-epic` for the 8-step epic cycle.
6. **Pauses for confirmation** — After each phase, asks "Ready to proceed?".
7. **Snapshots** — `bash scripts/bp-yaml-snapshot.sh` before major release cuts.

## Orchestration Modes

- **Standard**: Enforce all gates. Use for new features and major refactors.
- **Fast-Track**: Skip negotiable gates. Use for hotfixes and minor improvements.
- **Ad-Hoc**: Warnings only. Use for prototyping and spikes (non-production).

See [REFERENCE.md](REFERENCE.md) for full mode behaviors.

## Verification

All phases complete with artifacts:
```bash
verify: test -f specs/state.yaml && test -f specs/release-plan.yaml && test -f specs/product/SCOPE_LATEST.yaml && ls specs/epics/*.yaml 1>/dev/null && echo "✅ All phases complete"
```
