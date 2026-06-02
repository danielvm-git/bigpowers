---
name: orchestrate-project
model: sonnet
description: Meta-skill that enforces the 6-phase core loop (discover → elaborate → plan → build → verify → release) with hard gates. Use to coordinate multi-phase projects with guaranteed quality checkpoints. One-time command for the entire project lifecycle.
---

# Orchestrate

The orchestrate skill coordinates projects through a prescriptive 6-phase core loop with hard gates, ensuring consistent quality and preventing scope creep.

## Quick Start

```bash
# Start a new project (creates PROJECT.md and begins discover phase)
claude /orchestrate --mode standard

# Or resume an existing project at the current phase
claude /orchestrate --mode standard --resume

# For low-risk scenarios (hotfixes, refactors on well-tested code)
claude /orchestrate --mode fast-track
```

## The 6-Phase Core Loop

1. **DISCOVER** (3-6 hours): Understand problem. Deliverables: PROJECT.md, CONTEXT.md.
2. **ELABORATE** (3-6 hours): Research solutions. Deliverables: RESEARCH.md.
3. **PLAN** (2-4 hours): Write verifiable plan. Deliverables: PLAN.md.
4. **BUILD** (1-8 hours): Execute plan. Deliverables: Code, SUMMARY.md.
5. **VERIFY** (1-3 hours): Validate success criteria. Deliverables: VERIFICATION.md.
6. **RELEASE** (30 min - 2 hours): Ship to production. Deliverables: Release tag.

See [REFERENCE.md](REFERENCE.md) for detailed phase specifications and gate types.

## How Orchestrate Works

1. **Maintains state.yaml** — Tracks current phase, `active_epic`, `active_flow`, decisions, risks.
2. **Spawns appropriate skills** — Routes by `model:` frontmatter. Decisions pass only via `specs/state.yaml` `handoff` between spawns.
3. **Methodology lenses** — If `specs/plans/TEST_PLAN_LATEST.md` or ADRs exist, apply at phase gates.
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
verify: test -f specs/PROJECT.md && test -f specs/PLAN.md && test -f specs/VERIFICATION.md && echo "✅ All phases complete"
```
