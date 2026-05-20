
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

1. **Maintains STATE.md** — Tracks current phase, artifacts, decisions, risks.
2. **Spawns appropriate skills** — Calls survey-context, elaborate-spec, plan-work, etc.
3. **Enforces gates** — Hard stops if success criteria not met.
4. **Pauses for confirmation** — After each phase, asks "Ready to proceed?".
5. **Archives history** — Saves PLAN.md as specs/PLAN-vX.Y.Z.md.

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

---

# Orchestrate Reference: Phases, Modes, and Workflows

Detailed documentation for the `orchestrate-project` meta-skill.

## The 6-Phase Core Loop

### PHASE 1: DISCOVER
- **Goal**: Understand the problem completely and map existing context.
- **Deliverables**: `PROJECT.md`, `CONTEXT.md`.
- **Skills**: `survey-context`, `elaborate-spec`, `grill-me`.
- **Gate**: Confirm ("Is the problem clear?").

### PHASE 2: ELABORATE
- **Goal**: Research solutions and lock architectural design.
- **Deliverables**: `RESEARCH.md`, ADRs (Architecture Decision Records).
- **Skills**: `model-domain`, `define-language`, `challenge-design`.
- **Gate**: Quality ≥94% (via `request-review`) + Confirm ("Are decisions locked?").

### PHASE 3: PLAN
- **Goal**: Write a verifiable implementation plan with success criteria.
- **Deliverables**: `PLAN.md` with `verify:` commands.
- **Skills**: `scope-work`, `slice-tasks`, `define-success`, `plan-work`.
- **Gate**: Quality (request-review ≥94%) + slopcheck [SUS]/[SLOP].

### PHASE 4: BUILD
- **Goal**: Execute the plan step-by-step using TDD and vertical slices.
- **Deliverables**: Code, `SUMMARY.md`.
- **Skills**: `kickoff-branch`, `develop-tdd`, `delegate-task`, `execute-plan`.
- **Gate**: Integration tests PASS.

### PHASE 5: VERIFY
- **Goal**: Validate success criteria and ensure production readiness.
- **Deliverables**: `VERIFICATION.md`, audit results.
- **Skills**: `validate-fix`, `audit-code`, `request-review`.
- **Gate**: Quality ≥94%, coverage ≥95%, audits ≥93%.

### PHASE 6: RELEASE
- **Goal**: Ship to production with full traceability.
- **Deliverables**: Release tag (vX.Y.Z), release notes.
- **Skills**: `commit-message`, `release-branch`.
- **Gate**: Safety ("About to push to main. Confirm?").

---

## Orchestration Modes

### Mode 1: Standard (Enforce All Gates)
**Use Case**: New features, major refactors, architectural changes.
**Behavior**:
- All Confirm gates require explicit user approval.
- All Quality gates are hard stops if threshold is not met.
- No shortcuts or phase skipping.

### Mode 2: Fast-Track (Skip Negotiable Gates)
**Use Case**: Hotfixes, minor improvements, refactors on well-tested code.
**Behavior**:
- Skip Discover if `PROJECT.md` exists.
- Skip Elaborate if design decisions are already locked.
- Skip Verify if coverage ≥95% + all tests PASS.
- Soft gates auto-approve if baseline conditions are met.

### Mode 3: Ad-Hoc (Legacy, Warnings Only)
**Use Case**: Exploration, prototyping, spikes (NOT for production).
**Behavior**:
- Gates emit warnings but do not block execution.
- User can manually skip any phase.
- No enforced quality thresholds.

---

## Gate & Checkpoint Types
*See `docs/references/gates.md` and `docs/references/checkpoints.md` for full specs.*

- **Confirm**: Requires human "yes/no" decision.
- **Quality**: Automated threshold check (e.g., coverage, audit score).
- **Safety**: Destructive actions require risk acknowledgment.
- **Transition**: Mandatory artifact presence check.
- **slopcheck**: Identification of [SUS] (Suspicious) or [SLOP] (High-risk) packages.

---

## Error Recovery & State
Orchestrate maintains `specs/STATE.md` to track:
- **Current Phase**: Position in the loop.
- **Artifacts**: Checklist of completed deliverables.
- **Decisions**: Audit trail of architectural choices.
- **Risks**: Active project risks and mitigation status.

In the event of a crash or exit, run `claude /orchestrate --resume` to pick up exactly where the session left off.
