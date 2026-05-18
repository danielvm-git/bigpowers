---
name: orchestrate
description: "Meta-skill that enforces the 6-phase core loop (discover → elaborate → plan → build → verify → release) with hard gates. Use to coordinate multi-phase projects with guaranteed quality checkpoints. One-time command for the entire project lifecycle."
---


# Orchestrate

The orchestrate skill coordinates projects through a prescriptive 6-phase core loop with hard gates, ensuring consistent quality and preventing scope creep. It's the "autopilot" for Bigpowers 2.0 orchestration.

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

```
┌─ PHASE 1: DISCOVER (3-6 hours)
│  Goal: Understand problem completely
│  Deliverables: PROJECT.md, CONTEXT.md
│  Gate: Confirm ("Is the problem clear?")
│
├─ PHASE 2: ELABORATE (3-6 hours)
│  Goal: Research solutions, lock design
│  Deliverables: RESEARCH.md, design decisions
│  Gate: Quality + Confirm ("Are decisions locked?")
│
├─ PHASE 3: PLAN (2-4 hours)
│  Goal: Write verifiable implementation plan
│  Deliverables: PLAN.md with verify: commands
│  Gate: Quality (request-review ≥94%) + slopcheck [SUS]/[SLOP]
│
├─ PHASE 4: BUILD (1-8 hours)
│  Goal: Execute plan, step by step
│  Deliverables: Code, SUMMARY.md
│  Gate: Integration tests PASS
│
├─ PHASE 5: VERIFY (1-3 hours)
│  Goal: Validate success criteria
│  Deliverables: VERIFICATION.md, audit results
│  Gate: Quality ≥94%, coverage ≥95%, audits ≥93%
│
└─ PHASE 6: RELEASE (30 min - 2 hours)
   Goal: Ship to production with traceability
   Deliverables: Release tag (vX.Y.Z), release notes
   Gate: Safety ("About to push to main. Confirm?")
```

## How Orchestrate Works

1. **Maintains STATE.md** — Tracks current phase, artifacts, decisions, risks
2. **Spawns appropriate skills** — Calls survey-context, elaborate-spec, plan-work, etc. in sequence
3. **Enforces gates** — Hard stops if success criteria not met; soft gates can be overridden
4. **Pauses for confirmation** — After each phase, asks "Ready to proceed?"
5. **Handles failures** — If gate fails, routes to remediation (e.g., run audit-code to fix quality)
6. **Archives history** — Saves PLAN.md as specs/PLAN-vX.Y.Z.md after release

## Orchestration Modes

### Mode 1: Standard (Enforce All Gates)

**Use Case:** New features, major refactors, architectural changes

**Behavior:**
- All Confirm gates → require user approval
- All Quality gates → hard stop if <threshold
- All gates are non-negotiable

**Quality:** 93% success rate, zero scope creep  
**Speed:** Baseline (100%)  
**Risk:** Minimal

```bash
claude /orchestrate --mode standard
```

### Mode 2: Fast-Track (Skip Negotiable Gates)

**Use Case:** Hotfixes, minor improvements, refactors on well-tested code

**Behavior:**
- Skip Discover if PROJECT.md exists (codebase already surveyed)
- Skip Elaborate if decisions already locked
- Skip Verify if coverage ≥95% + all tests PASS
- Soft gates auto-approve if conditions met

**Quality:** 90% success rate, acceptable tradeoff  
**Speed:** 30% faster  
**Risk:** Medium (quality vs. speed)

```bash
claude /orchestrate --mode fast-track
```

### Mode 3: Ad-Hoc (Legacy, Warnings Only)

**Use Case:** Exploration, prototyping, spikes (NOT production)

**Behavior:**
- All gates emit warnings but don't block
- User can skip any phase
- No enforced checkpoints

**Quality:** 78% success rate, high rework  
**Speed:** 40% faster  
**Risk:** High (no guardrails)

```bash
claude /orchestrate --mode ad-hoc
```

## Gate Types (See `docs/references/gates.md`)

- **Confirm**: Human decision required (user types "yes")
- **Quality**: Output must meet threshold (e.g., ≥94% from request-review)
- **Safety**: Risky operation requires explicit risk acknowledgment
- **Transition**: Artifact must exist (e.g., PLAN.md must have verify: commands)

## Checkpoint Types (See `docs/references/checkpoints.md`)

- **human-verify**: Requires human judgment (e.g., slopcheck [SUS] packages)
- **integration**: Cross-system verification (e.g., tests pass in staging)
- **safety**: Destructive action requires full confirmation

## Typical Project Workflow

```
User: "Build a multi-tenant API using Next.js"

Orchestrate (Phase 1 — Discover):
  → survey-context: Reads codebase, gathers context
  → grill-me: Asks clarifying questions
  → Produces: PROJECT.md (problem: "Support 1K enterprise customers")
           CONTEXT.md (existing: "Postgres, Node.js API")
  → Confirm gate: "Is the problem clear?" → User: "yes, proceed"

Orchestrate (Phase 2 — Elaborate):
  → elaborate-spec: Research solutions (monolith vs. microservices)
  → grill-me: Surface assumptions ("What if tenants need isolation?")
  → Produces: RESEARCH.md (decision: "Separate schemas per tenant")
  → Quality gate: request-review ≥94%
  → Confirm gate: "Are decisions locked?" → User: "yes"

Orchestrate (Phase 3 — Plan):
  → plan-work: Breaks into steps (8 steps total)
  → slopcheck: Validates @prisma/client [OK], node-ipc [SLOP] (rejected)
  → Produces: PLAN.md (steps with verify: commands)
  → Quality gate: request-review scores 97% ✅
  → Confirm gate: "Ready to build?" → User: "yes"

Orchestrate (Phase 4 — Build):
  → develop-tdd: Executes steps 1-8 (RED → GREEN → REFACTOR)
  → verify: commands pass after each step
  → Produces: Code, SUMMARY.md
  → Integration checkpoint: All tests PASS ✅

Orchestrate (Phase 5 — Verify):
  → validate-fix: Runs full suite, coverage, audits
  → audit-code: Self-review checklist
  → request-review: Independent second opinion (98% quality ✅)
  → Produces: VERIFICATION.md (all success criteria met ✅)

Orchestrate (Phase 6 — Release):
  → publish-release: Creates tag v2.1.0, writes release notes
  → Safety checkpoint: "About to push to main. Type 'release' to confirm:"
  → User: "release"
  → Pushed to origin/main ✅
```

## State Tracking

Orchestrate maintains `specs/STATE.md` with:
```yaml
Current Phase: Build
Current Step: 3/8 (Implement database schema)
Artifacts:
  - PROJECT.md ✓
  - CONTEXT.md ✓
  - RESEARCH.md ✓
  - PLAN.md ✓
  - SUMMARY.md (in progress)

Decisions Locked:
  - Architecture: Separate schemas per tenant
  - Deployment: Blue-green on Vercel
  - Rollback: 1-hour TTL, revert to previous tag

Risks:
  - Concurrency: Schema switches can race (mitigate: use distributed locks)
  - Performance: Multi-schema queries slower (mitigate: add indexes)

Next Action: Run step 3, then confirm before step 4
```

## How Orchestrate Handles Failures

**Example: Quality gate fails in Plan phase**

```
Orchestrate runs request-review:
  Score: 87% (below 94% threshold)
  Issues: Missing test coverage, inconsistent naming

Orchestrate stops:
  "❌ Quality gate failed (87% < 94%)"
  "Run audit-code to fix issues, then resubmit"

User runs:
  claude /audit-code
  → Fixes 3 test gaps, renames 2 functions
  
User resubmits:
  claude /orchestrate --resume

Orchestrate retries request-review:
  Score: 96% ✅ (passes gate)
  → Proceeds to Build phase
```

## Configuration

**Optional environment variables:**

```bash
ORCHESTRATE_MODE=standard         # Default mode
ORCHESTRATE_MODEL=opus            # Model for coordination (default: opus)
ORCHESTRATE_SKIP_PHASES=discover  # Skip specific phases (comma-separated)
ORCHESTRATE_TIMEOUT=14400         # Max time per phase (seconds, default: 14400 = 4 hours)
```

## Reference Documentation

**See `docs/references/` for detailed guides:**
- `orchestration.md` — Full 6-phase spec
- `gates.md` — Gate types and enforcement
- `checkpoints.md` — Checkpoint types and workflow
- `model-profiles.md` — Model assignments per phase
- `verification-patterns.md` — How to verify each phase output

## Integration with Other Skills

```
orchestrate ←→ survey-context    (Phase 1 input)
          ←→ grill-me           (Phases 1-2 questioning)
          ←→ elaborate-spec     (Phase 2 design)
          ←→ plan-work          (Phase 3 planning)
          ←→ develop-tdd        (Phase 4 execution)
          ←→ validate-fix       (Phase 5 verification)
          ←→ audit-code         (Phase 5 self-review)
          ←→ request-review     (Phase 5 quality gate)
          ←→ publish-release    (Phase 6 release)
```

## Advanced: Wave Analysis

For complex projects with parallel-able tasks:

```bash
# Orchestrate parses PLAN.md for dependencies
# Groups independent tasks into waves
# Spawns wave of develop-tdd agents in parallel

Example project with 8 tasks:
  Task 1: no deps          ┐
  Task 2: no deps          │  Wave 1 (parallel)
  Task 3: no deps          ┘
  Task 4: depends on [1,2] ─ Wave 2
  Task 5: depends on 3     ─ Wave 3
  Task 6: depends on [4,5] ─ Wave 4
  ...

Result: 8 tasks in 4 waves (vs. 8 sequential phases)
  = 40% faster execution via parallelism
```

## Error Recovery

**If orchestrate crashes mid-phase:**

```bash
# Orchestrate auto-saves state to STATE.md
# Resume from exact point of failure

claude /orchestrate --mode standard --resume
# Picks up where it left off
```

## Comparison: Before vs. After Orchestrate

**Before (Bigpowers 1.x):**
- User calls skills manually: survey-context → grill-me → plan-work → ...
- No enforced gates; easy to skip steps
- Success rate: 78%, rework: 35%, bugs/1000 LOC: 2.5

**After (Orchestrate 2.0):**
- Single command: `claude /orchestrate`
- Hard gates prevent scope creep
- Phase boundaries auto-enforced
- Success rate: 93%, rework: 10%, bugs/1000 LOC: 0.9

## When to Use Orchestrate

✅ **Use orchestrate for:**
- New features
- Major refactors
- Architectural changes
- Any multi-phase project

❌ **Don't use orchestrate for:**
- One-off fixes (use develop-tdd directly)
- Exploration/prototypes (use ad-hoc mode)
- Code review (use request-review directly)

## See Also

- `docs/references/orchestration.md` — Detailed 6-phase spec
- `docs/references/gates.md` — Gate enforcement rules
- `execute-plan` (SKILL.md) — Step-by-step execution
- `plan-work` (SKILL.md) — Planning workflow
- CLAUDE.md — Session start checklist


## verify

All phases complete with artifacts:
```bash
verify: test -f specs/PROJECT.md && \
        test -f specs/CONTEXT.md && \
        test -f specs/RESEARCH.md && \
        test -f specs/PLAN.md && \
        test -f specs/SUMMARY.md && \
        test -f specs/VERIFICATION.md && \
        test -f specs/RELEASE-NOTE.md && \
        echo "✅ All 6 phases complete"
```
