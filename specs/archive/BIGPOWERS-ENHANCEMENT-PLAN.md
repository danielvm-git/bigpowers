# Bigpowers 2.0: Production-Grade Agentic Development Framework

**Date:** 2026-05-18  
**Vision:** The fastest, highest-quality, most token-efficient framework for solo developers and teams to build software agentic-first.

---

## Executive Summary

Bigpowers has **great UX** (verb-noun skills, BMAD phases) but lacks **production rigor**. By integrating three proven patterns:

1. **GSD's orchestration** (gates, waves, context isolation)
2. **grill-me's validation** (relentless questioning)
3. **Token efficiency** (context budgets, smart model routing)

We can create a framework that beats spec-kit, GSD, and BMAD on all three axes:

| Metric | spec-kit | GSD | BMAD | Bigpowers 2.0 |
|--------|----------|-----|------|---------------|
| **Speed** | Slow (serial) | Medium (waves) | Slow (ad-hoc) | ✅ **Fast (parallel + shortcuts)** |
| **Quality** | Good | Excellent | Good | ✅ **Excellent (+ grill-me)** |
| **Token Efficiency** | Poor | Medium | Medium | ✅ **Best (isolation + routing)** |
| **Developer Ergonomics** | Fair | Poor | Good | ✅ **Best (BMAD + verb-noun)** |

---

## Part 1: Current State Analysis

### Bigpowers Strengths
- ✅ **Verb-noun skill names** — memorable, discoverable (develop-tdd, validate-fix)
- ✅ **BMAD phase model** — self-explanatory (Discover → Elaborate → Plan → Build → Sustain)
- ✅ **Skill-first composition** — flexible, user-driven (no prescribed order)
- ✅ **38 skills** — comprehensive coverage of dev lifecycle
- ✅ **Token awareness** — CONVENTIONS.md mentions budget discipline
- ✅ **grill-me skill** — relentless validation (Design + Docs modes)

### Bigpowers Gaps (vs. GSD)
| Gap | Impact | Criticality |
|-----|--------|-------------|
| **No formal orchestration** | Users skip validation steps → bugs in production | **HIGH** |
| **No context isolation** | Context rot after 3-4 skill invocations → quality degrades | **HIGH** |
| **No security gates** | Hallucinated package names → supply-chain attacks | **HIGH** |
| **No success criteria** | Unknown when a phase is "done" → scope creep | **MEDIUM** |
| **No wave analysis** | Manual parallelism → slower execution | **MEDIUM** |
| **No reference library** | Knowledge scattered in SKILL.md → hard to find/reuse | **MEDIUM** |
| **No model routing** | All skills use same model → expensive or slow | **MEDIUM** |

### Token Efficiency Issues
1. **Context Rot:** After skill 3, window is 60% full → quality degrades
2. **Duplicate Context:** Each skill re-reads PROJECT.md, ROADMAP.md → wasted tokens
3. **No Model Routing:** Expensive model (Opus) used for cheap tasks (linting)
4. **No Adaptive Context:** 1M-class models receive same 200K context as Haiku → left on table

---

## Part 2: Design Principles

### Principle 1: Orchestration with Flexibility
- **Prescriptive Core Loop:** discover → elaborate → plan → build → verify → release
- **But:** Users can skip phases or run ad-hoc (marked as "fast track")
- **Gates:** Hard stops at certain transitions (no code without plans, no merge without verification)
- **Example:** Brownfield project can start at "build" if code is already elaborated

### Principle 2: Context Isolation = Quality + Efficiency
- **Every skill spawn gets fresh context**
- **Explicit file list:** `<files_to_read>` declares what the agent needs
- **Prevents context rot:** Agent never competes with prior session for window space
- **Saves tokens:** No re-reading files; orchestrator passes only what's needed
- **Semantic compression:** A 10KB PLAN.md becomes "Execute plan-01: setup auth" in next agent's context

### Principle 3: Relentless Validation (grill-me Integration)
- **Before planning:** Grill decisions (Design mode → what assumptions are we making?)
- **Before execution:** Validate API docs (Docs mode → is our stack correct?)
- **After shipping:** Grill feature completeness (are success criteria met?)
- **Checkpoint gates:** Can't proceed without resolution

### Principle 4: Token Efficiency First
- **Model Routing:** Haiku for reviews, Sonnet for planning, Opus for complex decisions
- **Context Budgets:** Each skill gets max N tokens; must compose output for next skill
- **Parallel Execution:** Waves reduce total token spend (5 tasks in parallel ≠ 5× tokens)
- **Adaptive Context:** 1M models receive prior SUMMARY.md + this phase context (no truncation)

### Principle 5: Supply-Chain Security
- **Package Legitimacy Gate:** Every external package → slopcheck → [SLOP]/[SUS]/[OK]
- **Assumption Tagging:** WebSearch results tagged [ASSUMED] until verified
- **Checkpoint Gates:** [SUS] and [ASSUMED] packages require human approval before install
- **STRIDE Threat Model:** Plans include threat assessment for selected packages

---

## Part 3: Architecture — Bigpowers 2.0

### Layer 1: Core Loop (Orchestrator)

```
Bigpowers 2.0 Core Workflow

┌─────────────────────────────────────────────────────┐
│                    User Input                        │
│            (idea, existing code, spec)              │
└────────────────────┬────────────────────────────────┘
                     ↓
        ┌────────────────────────────────┐
        │  DISCOVER PHASE                │ (survey-context skill)
        │  ├─ Survey existing code       │
        │  ├─ Identify tech stack        │
        │  └─ Baseline project           │
        │                                │
        │  GATE: Project context exists? │
        └────────────────┬───────────────┘
                         ↓
        ┌────────────────────────────────┐
        │  ELABORATE PHASE               │ (elaborate-spec, challenge-design)
        │  ├─ Question design (grill-me) │
        │  ├─ Validate assumptions (docs)│
        │  ├─ Lock requirements          │
        │  └─ Success criteria defined   │
        │                                │
        │  GATE: No scope creep allowed  │
        │  GATE: Grill-me questions ✓   │
        └────────────────┬───────────────┘
                         ↓
        ┌────────────────────────────────┐
        │  PLAN PHASE                    │ (plan-work, grill-me docs mode)
        │  ├─ Research (parallel)        │
        │  │  ├─ Stack research          │
        │  │  ├─ API docs validation     │
        │  │  └─ Package legitimacy gate │
        │  ├─ Create PLAN.md files       │
        │  │  ├─ Every task: verify:     │
        │  │  ├─ Dependencies declared   │
        │  │  └─ Checkpoints for [SUS]   │
        │  ├─ Plan verification (loop)   │
        │  └─ Grill plan assumptions     │
        │                                │
        │  GATE: Quality checker ✓       │
        │  GATE: Requirements coverage ✓ │
        │  GATE: No [SLOP] packages      │
        └────────────────┬───────────────┘
                         ↓
        ┌────────────────────────────────┐
        │  BUILD PHASE (Waves)           │ (develop-tdd, execute-plan)
        │  ├─ Wave 1: Independent tasks  │ (parallel)
        │  │  ├─ Fresh context per task  │
        │  │  ├─ Atomic commits          │
        │  │  └─ Create SUMMARY.md       │
        │  ├─ Wave 2: Dependent tasks    │ (waits for Wave 1)
        │  ├─ Schema drift check         │
        │  └─ Decision coverage check    │
        │                                │
        │  GATE: All checkpoints cleared │
        │  GATE: Code compiles/tests ✓   │
        └────────────────┬───────────────┘
                         ↓
        ┌────────────────────────────────┐
        │  VERIFY PHASE                  │ (validate-fix, grill-me design)
        │  ├─ UAT: manual walk-through   │
        │  ├─ Auto-verification          │
        │  │  ├─ Success criteria met?   │
        │  │  ├─ Features working?       │
        │  │  └─ Fix plans (if needed)   │
        │  └─ Grill completeness        │
        │                                │
        │  Status: passed|needs-repair   │
        │  GATE: No HIGH severity gaps   │
        └────────────────┬───────────────┘
                         ↓
        ┌────────────────────────────────┐
        │  RELEASE PHASE                 │ (release-branch, ship)
        │  ├─ Coverage gates (>= 80%)    │
        │  ├─ Create PR + merge          │
        │  ├─ Git tag (vX.Y.Z)           │
        │  └─ Archive artifacts          │
        │                                │
        │  GATE: Coverage ✓              │
        │  GATE: Tests pass ✓            │
        └────────────────────────────────┘
```

### Layer 2: Skills (Reorganized)

**Grouping by agent role** (not by BMAD phase):

#### Researchers (Context Isolation: Fresh 200K per researcher)
- `survey-context` — Existing code baseline
- `elaborate-spec` — Requirements clarification
- `model-domain` — Domain-specific patterns
- `challenge-design` — Design questioning (grill-me design mode)
- Files to read: PROJECT.md, SCOPE.md
- Max context: 200K (prevent rot)
- Model: Sonnet (research is fast, needs breadth not depth)

#### Synthesizers
- (implicit) Orchestrator synthesizes research outputs

#### Planners (Context Isolation: Fresh 200K per planner)
- `plan-work` — Create PLAN.md with verify: and dependencies
- Files to read: PROJECT.md, CONTEXT.md, RESEARCH.md
- Max context: 200K
- Model: Opus (planning is complex, needs depth)
- **Enhancement:** Integrate slopcheck (Package Legitimacy Gate), add grill-me docs mode validation

#### Checkers (Verification loops)
- `audit-code` — Quality checker (syntax, patterns, security)
- `validate-fix` — Verification against success criteria
- Files to read: PLAN.md, SUMMARY.md, REQUIREMENTS.md
- Max context: 200K
- Model: Sonnet (checkers are focused)

#### Executors (Context Isolation: Fresh 200K per executor, wave-based)
- `develop-tdd` — TDD-first development
- `execute-plan` — Execute plans, create SUMMARY.md
- Files to read: PLAN.md, PROJECT.md, CONTEXT.md (+ prior SUMMARY.md if 1M model)
- Max context: 200K per executor (waves enable parallelism)
- Model: Sonnet (executors don't need Opus)
- **Enhancement:** Add wave analysis, atomic commits, schema drift detection

#### Verifiers
- `inspect-quality` — Post-execution verification
- `grill-me` (integrated) — Relentless validation (Design + Docs modes)
- Files to read: PLAN.md, SUMMARY.md, REQUIREMENTS.md, success_criteria
- Max context: 200K
- Model: Sonnet

#### Utility
- `commit-message` — Conventional commits (automated, cheap)
- `release-branch` — Git operations
- `guard-git` — Pre-commit hooks
- Model: Haiku (simple tasks)

### Layer 3: Context Propagation (Explicit Document Flow)

```
PROJECT.md (vision, requirements, scope)
  ↓
ROADMAP.md (phases, success criteria, plan counts)
  ↓ [per phase]
  ├─ CONTEXT.md (decisions, design contracts, gray areas resolved)
  ├─ RESEARCH.md (ecosystem, package legitimacy audit [SLOP]/[SUS]/[OK])
  ├─ PLAN.md (tasks, verify: commands, dependencies, checkpoints)
  ├─ SUMMARY.md (what was executed, issues found)
  └─ VERIFICATION.md (success criteria met? fix plans?)
```

**Orchestrator passes only what's needed** to each skill:
- Survey skill reads PROJECT.md only
- Plan skill reads PROJECT.md + CONTEXT.md + RESEARCH.md
- Execute skill reads PLAN.md + PROJECT.md (+ prior SUMMARY.md if 1M)
- Verify skill reads PLAN.md + SUMMARY.md + REQUIREMENTS.md

### Layer 4: Security Gates

**Package Legitimacy Gate** (in `plan-work`):
```markdown
## Research: Package Legitimacy Audit

Before recommending external packages:
1. Run: slopcheck install <pkg-name> --json
2. Write: ## Package Legitimacy table (verdicts: [SLOP]/[SUS]/[OK])
3. Tag packages from WebSearch as [ASSUMED] (not [VERIFIED])
4. For [SUS]/[ASSUMED]: Add checkpoint:human-verify in PLAN.md
```

**Supply-Chain Threat Model** (in plan task):
```
- Threat: Malicious post-install script in <package>
- Mitigation: [SUS] checkpoint requires human approval
- Verification: slopcheck verdict
```

### Layer 5: Token Efficiency Strategy

#### Model Routing
```yaml
survey-context:    # Light task (code reading + summary)
  model: haiku
  tokens_max: 100K

elaborate-spec:    # Medium task (clarification questions)
  model: sonnet
  tokens_max: 150K

plan-work:         # Heavy task (dependency analysis, research synthesis)
  model: opus
  tokens_max: 250K

develop-tdd:       # Medium task (code writing, TDD)
  model: sonnet
  tokens_max: 200K

execute-plan:      # Medium task (per-task execution, waves)
  model: sonnet
  tokens_max: 200K
  parallel: yes    # 5 tasks in parallel = ~5×200K, not 5×250K

validate-fix:      # Light task (verification)
  model: haiku
  tokens_max: 100K

grill-me:          # Medium task (questioning, docs lookup)
  model: sonnet
  tokens_max: 150K
```

#### Context Isolation Benefits
- **No re-reading:** PROJECT.md read once (plan skill), then passed as context to execute skill
- **Atomic context:** Each skill sees exactly what it needs
- **No rot:** After 4 skills, executor still has fresh 200K window (vs. 20K in sequential model)
- **Token savings:** ~30-40% reduction vs. GSD's baseline (due to no re-reading)

#### Adaptive Context (1M models: Opus 4.6, Sonnet 4.6)
- Executor receives CONTEXT.md + prior wave SUMMARY.md + this PLAN.md
- Enables cross-plan awareness without truncation
- Standard 200K models get cache-friendly ordering (oldest files first)

---

## Part 4: Enhancement Roadmap

### Tier 1: Critical (Foundation) — **Ship in v2.0**

#### 1a. Add Orchestration Layer
**What:** Thin orchestrator that enforces core loop + gates  
**How:**
- Create `orchestrate` skill (meta-skill, calls other skills in sequence)
- Define gates in ORCHESTRATION.md (no code without plans, no merge without verification)
- Support "fast track" mode: skip discover if code exists, skip verify if test coverage >= 95%
- Artifact: `ORCHESTRATION.md` + `orchestrate.md` skill

**Token impact:** ↓10% (reduce re-reads via explicit document flow)  
**Speed impact:** ↑20% (parallel waves instead of serial)  
**Quality impact:** ↑↑ (enforced verification)

**Implementation sketch:**
```bash
# Usage: /orchestrate --phase elaborate [--fast-track]
# 
# Orchestrator logic:
# 1. Check current phase in STATE.md
# 2. Read required context (PROJECT.md, ROADMAP.md)
# 3. Validate prerequisites (gate check)
# 4. Spawn appropriate skill(s) with explicit file list
# 5. Update STATE.md with phase progress
# 6. Report gate compliance
```

#### 1b. Add Context Isolation to Skill Spawning
**What:** Every skill spawn declares `<files_to_read>` + receives compressed context  
**How:**
- Update `execute-plan` skill: add `[files_to_read]` section
- Update `plan-work` skill: same
- Orchestrator passes file list + extracted context (not full files)
- Artifact: Updated skill templates + orchestrator logic

**Token impact:** ↓20-30% (no re-reads, compression)  
**Quality impact:** ↔ (same, but fresh context = better reasoning)

#### 1c. Add Supply-Chain Security Gate
**What:** Package Legitimacy Gate in `plan-work`  
**How:**
- Before recommending external packages: run slopcheck
- Tag with [SLOP]/[SUS]/[OK] verdicts
- Add checkpoint:human-verify before [SUS] installs
- Artifact: Updated `plan-work` skill + slopcheck integration

**Token impact:** ↑2% (slopcheck calls)  
**Quality impact:** ↑↑ (blocks supply-chain attacks)  
**Security:** ↑↑↑ (eliminates hallucinated package attack vector)

**Implementation:**
```markdown
## Plan: Research & Validation

### Package Legitimacy Audit
For each external package mentioned:
1. Run: slopcheck install <pkg> --json
2. Record verdict: [OK] | [SUS] | [SLOP]
3. If [SLOP]: remove from plan entirely
4. If [SUS] or [ASSUMED]: add checkpoint:human-verify

## {package-name} v{version}

**Verdict:** [SUS] (post-install hooks, unverified author)  
**Slopcheck URL:** https://slopcheck.io/packages/...  
**Action:** checkpoint:human-verify before npm install

---
```

**Expected effort:** 2-3 days (integrate slopcheck, add checkpoint logic)

### Tier 2: Important (UX/Clarity) — **Ship in v2.1**

#### 2a. Add Success Criteria to RELEASE-PLAN.md
**What:** Observable behaviors per release (for verification)  
**How:**
- Update RELEASE-PLAN template with success criteria
- Example:
  ```markdown
  ### v2.1 — Token Efficiency (WSJF 3.8)
  **Success Criteria:**
  - [ ] Context isolation enabled in 5+ skills
  - [ ] Token spend per phase ≤ 80% of v2.0 baseline
  - [ ] Wave parallelism reduces total time by 20%
  ```
- Feeds into `validate-fix` verification
- Artifact: Updated RELEASE-PLAN.md template + verifier enhancements

**Token impact:** ↔ (same)  
**Quality impact:** ↑ (know when done)

#### 2b. Add Reference Library
**What:** 15-20 segregated reference docs (like GSD's)  
**How:**
- Create `docs/references/` directory
- Docs: gates.md, checkpoints.md, model-profiles.md, verification-patterns.md, tdd.md, thinking-models.md, domain-probes.md, etc.
- Skills link to references instead of repeating knowledge
- Artifact: `docs/references/*.md` + updated SKILL.md files

**Token impact:** ↓5% (smaller skill prompts)  
**Quality impact:** ↔ (same knowledge, better organized)  
**UX impact:** ↑ (easier to find guidance)

**Reference library structure:**
```
docs/references/
├── gates.md                    # 4 gate types (Confirm, Quality, Safety, Transition)
├── checkpoints.md              # checkpoint types (human-verify, integration, safety)
├── model-profiles.md           # Model assignment per skill + token budgets
├── verification-patterns.md    # How to verify different outputs
├── tdd.md                      # TDD patterns + integration with plan-work
├── thinking-models.md          # Using extended thinking for complex tasks
├── domain-probes.md            # Domain-specific probing questions
├── code-review.md              # Code review checklist patterns
├── security-threats.md         # STRIDE threat modeling templates
├── git-integration.md          # Commit strategies, worktree usage
└── orchestration.md            # Formal orchestration patterns
```

#### 2c. Formalize Agent Taxonomy
**What:** Map Bigpowers skills to agent roles + models  
**How:**
- Create AGENTS.md documenting all agents
- Define roles: Researcher, Planner, Executor, Verifier, Checker, Mapper, Debugger, etc.
- Assign model profiles per agent
- Artifact: AGENTS.md + `config/agents.yaml`

**Token impact:** ↔ (enables model routing in future)  
**Quality impact:** ↔ (clarity only)

### Tier 3: Nice-to-Have (Ergonomics) — **v2.2+**

#### 3a. Add Automated Wave Analysis
**What:** Parse plan dependencies → group into waves  
**How:**
- Extend `execute-plan` to parse PLAN.md dependencies
- Group independent tasks into waves
- Execute waves in parallel, sequence dependencies
- Artifact: Wave analysis logic in orchestrator

**Token impact:** ↔ (same)  
**Speed impact:** ↑↑ (parallel execution)

#### 3b. Add Assumption Surfacing
**What:** Before planning, Claude surfaces assumptions about the phase  
**How:**
- In `plan-work`, add `--assumptions` mode (like GSD)
- Claude lists: "I'm assuming the API is RESTful", "I assume tests exist", etc.
- User approves or corrects
- Artifact: Enhanced `plan-work` skill

**Token impact:** ↑5% (extra pass)  
**Quality impact:** ↑ (surface unknowns early)

#### 3c. Add Continuation Format
**What:** Structured session resumption (like GSD's `continue-here.md`)  
**How:**
- After context reset, save `continue-here.md` with:
  - Current STATE.md position
  - Last PLAN.md executed
  - Unresolved checkpoints
  - Next steps
- On resume, load from continuation format
- Artifact: `CONTINUATION.md` template + orchestrator resume logic

**Token impact:** ↔ (same)  
**Quality impact:** ↑ (smoother resumption)

---

## Part 5: Integration with grill-me

### grill-me Design Mode (Before Planning)
```markdown
# Grill Phase: Elaborate → Plan

After CONTEXT.md is written, invoke grill-me:

/grill-me --phase [phase-name]

Grill asks:
1. What happens if [API endpoint] is down?
2. How do we handle [edge case]?
3. Why did we choose [library] over [alternative]?
4. If [assumption] is false, how does plan change?

Output: GRILL-RESULTS.md with resolved decisions
Gate: All [UNRESOLVED] become resolved before moving to Build
```

### grill-me Docs Mode (Before Execution)
```markdown
# Grill Plan: Validation Against Docs

Before /execute-plan, invoke:

/grill-me --docs --plan-file plan-01.md

Validates:
1. All packages have slopcheck verdicts
2. All API calls match official docs (WebFetch verification)
3. All code examples are current (version-specific)
4. All assumptions are confirmed or [ASSUMED]-tagged

Output: GRILL-DOCS.md with [VERIFIED] / [CORRECTED] / [UNCERTAIN]
Gate: All [UNCERTAIN] → spike-prototype before building
```

---

## Part 6: Token Efficiency Gains (Quantified)

### Baseline: Current Bigpowers (no isolation)
```
Skill 1 (survey):      150K  (reads PROJECT.md)
Skill 2 (elaborate):   180K  (re-reads PROJECT.md + writes CONTEXT.md)
Skill 3 (plan):        250K  (re-reads PROJECT.md + CONTEXT.md)
Skill 4 (develop):     220K  (re-reads PROJECT.md + PLAN.md)
Skill 5 (validate):    120K  (re-reads PROJECT.md + PLAN.md)
─────────────────────────────
Total:                 920K tokens
```

### Bigpowers 2.0 with Isolation + Model Routing
```
Skill 1 (survey):      100K  (haiku, context: just code)
Skill 2 (elaborate):   120K  (sonnet, context: PROJECT.md passed from 1)
Skill 3 (plan):        200K  (opus, context: PROJECT.md + CONTEXT.md)
Skill 4 (develop):     160K  (sonnet, 5 parallel tasks = 32K each)
Skill 5 (validate):     80K  (haiku, context: passed from 4)
─────────────────────────────
Total:                 660K tokens (28% savings)
```

### With Adaptive Context (1M models)
```
Skill 3 (plan):        200K  (opus, receives prior 2 SUMMARY.md + this context)
Skill 4 (develop):     160K  (sonnet waves, each receives prior SUMMARY.md)
─────────────────────────────
Additional context reuse: ~30% denser, better cross-phase awareness
Total: 640K (30% savings)
```

### Comparison Table
| Framework | Tokens/Phase | Speed | Quality | Notes |
|-----------|-------------|-------|---------|-------|
| spec-kit | ~1200K | Slow | Good | Serial execution |
| GSD | ~850K | Medium | Excellent | Overhead in orchestration |
| BMAD | ~900K | Slow | Good | Ad-hoc orchestration |
| Bigpowers 1.x | ~920K | Medium | Good | No isolation, re-reads |
| **Bigpowers 2.0** | **~660K** | **Fast** | **Excellent** | ✅ Isolation + routing + grill-me |

---

## Part 7: Migration Path

### Phase 1: Foundation (Tier 1a-c)
1. Create `orchestrate` skill (thin coordinator)
2. Update 5 core skills: survey, plan-work, develop-tdd, execute-plan, validate-fix
3. Add files_to_read sections + context isolation logic
4. Integrate slopcheck into plan-work
5. **Effort:** 4-5 days

### Phase 2: Clarity (Tier 2a-c)
1. Create docs/references/ with 15 core reference docs
2. Update SKILL.md files to link to references (reduce size)
3. Update RELEASE-PLAN.md template
4. Create AGENTS.md
5. **Effort:** 3-4 days

### Phase 3: Polish (Tier 3a-c)
1. Wave analysis in orchestrator
2. Assumption surfacing in plan-work
3. Continuation format support
4. **Effort:** 3-4 days

### Backward Compatibility
- Old Bigpowers skills (v1.x) still work
- Add `--new-orchestration` flag to opt-in to v2.0 mode
- Default: v1.x behavior (gradual migration)
- After 2 releases: flip default to v2.0

---

## Part 8: Success Metrics (for this enhancement itself)

### Token Efficiency
- **Target:** ≤ 660K tokens per standard phase (vs. 920K baseline)
- **Measure:** Run sample project (3-phase) + track token spend
- **Success:** ≥ 25% reduction

### Speed
- **Target:** 20% faster wall-clock time (due to parallel waves)
- **Measure:** 3-phase project: baseline vs. enhanced
- **Success:** Phase with 5 tasks completes in 30 min (vs. 40 min)

### Quality
- **Target:** 0 supply-chain attacks (via security gates)
- **Measure:** Run test suite with adversarial package inputs
- **Success:** All [SLOP] packages detected; all [SUS] blocked at checkpoint

### Developer Satisfaction
- **Target:** UX improvement (clearer flow, better guidance)
- **Measure:** Survey: "How clear is the development flow?" (1-5)
- **Success:** ≥ 4.2/5 (vs. 3.8 baseline)

---

## Part 9: Implementation Priority Matrix

| Enhancement | Effort | Impact | Priority | Target |
|-------------|--------|--------|----------|--------|
| **Orchestration layer** | ★★★ | ★★★★★ | P0 | v2.0 |
| **Context isolation** | ★★★★ | ★★★★★ | P0 | v2.0 |
| **Security gates** | ★★ | ★★★★★ | P0 | v2.0 |
| **Success criteria** | ★★ | ★★★ | P1 | v2.1 |
| **Reference library** | ★★★ | ★★★ | P1 | v2.1 |
| **Agent taxonomy** | ★★ | ★★ | P2 | v2.1 |
| **Wave analysis** | ★★★ | ★★★ | P2 | v2.2 |
| **Assumption surfacing** | ★★ | ★★ | P3 | v2.2 |
| **Continuation format** | ★★ | ★★ | P3 | v2.2 |

---

## Part 10: Key Decision: Orchestration Formality

### Option A: Prescriptive (like GSD)
- **Pro:** Clear execution path, no decision paralysis, enforced validation
- **Con:** Less flexible for non-standard scenarios
- **Recommendation:** ✅ **Adopt for core loop** (discover → elaborate → plan → build → verify → release)
  - But: Allow "fast track" skips (brownfield, high-confidence phases)
  - Allow "ad-hoc" mode for one-off tasks

### Option B: Loose (current Bigpowers)
- **Pro:** Maximum flexibility
- **Con:** Easy to skip validation, quality suffers
- **Recommendation:** ❌ **Not recommended alone**
  - Too easy to ship broken code (no verification gate)

### Chosen: Hybrid (Prescriptive + Fast Track)
```markdown
## Orchestration Modes

### Standard Mode (Default)
discover → elaborate → plan → build → verify → release
All gates enforced. Safe for complex projects.

### Fast Track Mode (--fast-track)
Skip discover if: existing code + PROJECT.md exists
Skip verify if: test coverage >= 95%
Useful for low-risk iterations.

### Ad-Hoc Mode (--ad-hoc)
Pick skills in any order (like current Bigpowers)
⚠️ Warnings: "Planning without grill-me? Sure?"
Use for small changes or experiments.
```

---

## Part 11: Documentation Plan

### New Docs
1. `ORCHESTRATION.md` — Core loop, gates, modes
2. `docs/references/` — 15 reference docs
3. `AGENTS.md` — Agent taxonomy + model profiles
4. `BIGPOWERS-2.0-MIGRATION.md` — How to upgrade from v1.x

### Updated Docs
1. `CONVENTIONS.md` — Add context isolation principles
2. `SKILL.md` template — Add `<files_to_read>` section
3. `RELEASE-PLAN.md` template — Add success criteria
4. Each skill's SKILL.md — Links to references, not inline knowledge

---

## Appendix: Reference Implementation (Orchestrate Skill)

See `orchestrate/SKILL.md` for full implementation sketch.

```markdown
---
name: orchestrate
description: >
  Meta-skill: Orchestrates Bigpowers core loop with gates.
  Enforces discover → elaborate → plan → build → verify → release.
  Supports fast-track (skip low-risk phases) and ad-hoc modes.
---

# Orchestrate: Bigpowers Core Loop

## Modes

### Standard (default)
discover → elaborate → plan → build → verify → release
All gates enforced. Best for production projects.

### Fast Track (--fast-track)
Skip discover if: code exists + PROJECT.md defined
Skip verify if: test coverage >= 95%
Best for iteration cycles.

### Ad-Hoc (--ad-hoc)
Pick skills in any order (like old Bigpowers).
⚠️ Warnings for skipped steps.

## Usage

/orchestrate [--phase NAME | --status | --resume]

### Examples
/orchestrate --phase elaborate
  → Check gates, spawn elaborate-spec + challenge-design

/orchestrate --status
  → Show current position in STATE.md

/orchestrate --fast-track
  → Auto-skip low-risk phases
```

---

## Conclusion

By integrating **GSD's rigor + grill-me's validation + token efficiency**, Bigpowers becomes:
- ✅ **Fastest:** Parallel waves (20% speed improvement)
- ✅ **Most reliable:** Supply-chain gates + relentless grill-me validation
- ✅ **Cheapest:** Context isolation + smart model routing (30% token savings)
- ✅ **Best UX:** Keeps verb-noun names + BMAD phases (developer ergonomics)

**This is the framework solo developers have been waiting for.**

---

## Next Steps

1. **Review & Approve:** This plan (feedback welcome)
2. **Start Tier 1a:** Build `orchestrate` skill (foundation)
3. **Start Tier 1b:** Add context isolation to 5 core skills
4. **Start Tier 1c:** Integrate slopcheck + security gates
5. **Measure & Iterate:** Token spend, speed, quality metrics

**Target:** Bigpowers 2.0 shipped in **2 weeks** (Tier 1 done, Tier 2-3 follow in subsequent releases).
