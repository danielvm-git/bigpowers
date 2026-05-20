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
