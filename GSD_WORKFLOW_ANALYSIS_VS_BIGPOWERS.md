# GSD Workflow Analysis vs. Bigpowers: Complete Mapping & Gaps

**Date:** 2026-05-18  
**Scope:** Comprehensive analysis of GSD's 6-command core loop, each step's practices, and gaps vs. Bigpowers

---

## Executive Summary

**GSD (Get Shit Done)** is a **meta-prompting + multi-agent orchestration framework** with:
- 6 core commands (new-project → discuss → plan → execute → verify → ship)
- 31+ specialized agents (researchers, planners, checkers, executors, verifiers)
- 93+ total workflows + 60+ references
- Context isolation (fresh 200K window per agent)
- Wave-based parallel execution
- Supply-chain security gates (package legitimacy)

**Bigpowers** is a **skill-centric lifecycle framework** with:
- 38 skills (verb-noun pairs)
- Inline prompts in SKILL.md
- BMAD phases (Discover → Elaborate → Plan → Build → Sustain)
- Ad-hoc skill composition (no formal orchestration)
- Manual subagent dispatch via `delegate-task` / `dispatch-agents`

**Key insight:** GSD is **orchestration-first** (workflow → agents); Bigpowers is **skill-first** (agent picks skill). They solve the same problem from different angles.

---

## 1. The GSD Core Loop (6 Commands)

### Step 1: `/gsd-new-project` — Project Initialization

**Purpose:** Transform vague idea → concrete project definition (PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md)

**Workflow:**
```
Input (idea)
  ↓
Questioning (domain-probes.md philosophy)
  ↓
4× Parallel Researchers (Stack, Features, Architecture, Pitfalls)
  ↓
Research Synthesizer
  ↓
Requirements extraction
  ↓
Roadmapper (creates ROADMAP.md with phases, success criteria, plans)
  ↓
User approval
  ↓
STATE.md initialized
```

**Key Practices:**

1. **Questioning Philosophy:**
   - User is the visionary; Claude is the builder
   - Extract VISION, not implementation
   - Avoid generic categories; generate domain-specific questions
   - Scope is locked (no scope creep during discussion)

2. **Parallel Research:**
   - 4 independent researchers spawn simultaneously (Stack, Features, Architecture, Pitfalls)
   - Fresh context window per agent
   - Results feed into synthesis (no early convergence)

3. **Synthesizer Role:**
   - Unifies 4 parallel outputs into SUMMARY.md
   - Identifies gaps, contradictions, consensus
   - Produces requirements extraction input

4. **ROADMAP Artifact:**
   - Phases with dependencies (Phase 2 depends on Phase 1)
   - Decimal sub-phases for urgent insertions (2.1 inserted between 2 and 3)
   - **Success Criteria:** Observable behaviors (user-perspective) per phase
   - Plan count estimation per phase
   - Progress table
   - Wave analysis for execution planning

5. **Auto Mode (`--auto @file.md`):**
   - Skip deep questioning if PRD/idea doc provided
   - Extract context automatically
   - Still run research and synthesis
   - Useful for brownfield projects or time-constrained work

**Artifacts Created:**
- `PROJECT.md` — Vision, Core Value, Requirements (Validated/Active/Out of Scope), Constraints, Key Decisions
- `REQUIREMENTS.md` — Scoped, traceable (REQ-01, REQ-02, ...)
- `ROADMAP.md` — Phases with success criteria and plans
- `STATE.md` — Current position, performance metrics (< 100 lines)
- `research/` — STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, SUMMARY.md
- `config.json` — Workflow config (mode, model profiles, parallelization)
- `CLAUDE.md` — Project-level Claude Code integration (optional)

---

### Step 2: `/gsd-discuss-phase [N]` — Phase Context Gathering

**Purpose:** Capture implementation decisions before planning (CONTEXT.md)

**Workflow:**
```
Read ROADMAP.md phase description
  ↓
Identify gray areas (ambiguities, design choices)
  ↓
Present gray areas to user (or batch/auto)
  ↓
Deep-dive selected areas → CONTEXT.md
  ↓
Git commit discussion log
```

**Key Practices:**

1. **Gray Area Identification:**
   - Not generic categories (UI/UX/Behavior)
   - Phase-specific decisions (e.g., for auth: session handling, error responses, multi-device policy, recovery flow)
   - Driven by domain understanding (what users SEE / CALL / RUN / READ)

2. **Mode Options:**
   - `--all`: Discuss all gray areas without selection step
   - `--auto`: Auto-select recommended defaults
   - `--batch`: Group questions for batch intake
   - `--analyze`: Add trade-off analysis during discussion
   - `--power`: File-based bulk question answering
   - `--assumptions`: Surface Claude's assumptions without interactive session
   - Default: Interactive one-by-one

3. **Scope Guardrails (CRITICAL):**
   - Phase boundary is FIXED (from ROADMAP.md)
   - Allowed: Clarifying ambiguity ("How should posts be displayed?")
   - Not allowed: Scope creep ("Should we add comments?")
   - Heuristic: Does this clarify how we implement what's scoped, or add a new capability?
   - When creep detected: Note in "Deferred Ideas", don't act on it

4. **Output Structure:**
   - `{phase}-CONTEXT.md` — Decisions, locked choices, design contracts
   - `{phase}-DISCUSSION-LOG.md` — Audit trail of what was discussed
   - Questions are validated: empty responses are rejected

**Key Reference:** `domain-probes.md` — Phase-specific probe questions per domain type

---

### Step 3: `/gsd-plan-phase [N]` — Research, Plan, Verify

**Purpose:** Create executable PLAN.md files with integrated research and verification

**Workflow:**
```
Research Gate (if needed)
  ↓
Phase Researcher → RESEARCH.md
  │  ├── Package Legitimacy Audit (slopcheck)
  │  │   ├── [SLOP] = remove entirely
  │  │   ├── [SUS] = checkpoint before install
  │  │   └── [OK] = approved
  │  └── Ecosystem research, tech stack validation
  ↓
Planner → PLAN.md files (01-01, 01-02, ...)
  │  ├── Every task has `verify: <runnable command>`
  │  ├── Dependencies declared (Plan 02 depends on 01)
  │  ├── Checkpoints for [ASSUMED]/[SUS] packages
  │  └── STRIDE threat model for supply chain
  ↓
Plan Checker → Verify loop (max 3 iterations)
  │  ├── Check plans are executable
  │  ├── Check requirements coverage (REQ-IDs)
  │  ├── Check decision coverage (CONTEXT.md)
  │  └── If issues: replan until clean
  ↓
STATE.md → "Planned" status
```

**Key Practices:**

1. **Package Legitimacy Gate (v1.42.1):**
   - Researcher runs `slopcheck install <pkg> --json` on each package
   - Writes `## Package Legitimacy Audit` table to RESEARCH.md
   - Verdicts: `[SLOP]` (remove), `[SUS]` (checkpoint), `[OK]` (approved)
   - Packages from WebSearch are tagged `[ASSUMED]` (not `[VERIFIED]`)
   - Planner inserts `checkpoint:human-verify` before `[ASSUMED]`/`[SUS]` installs
   - **Supply-chain attack prevention:** Blocks hallucinated package names pre-registered with malicious post-install scripts

2. **Plan Task Structure:**
   - Every task has: title, description, acceptance criteria, `verify: <runnable command>`
   - Dependencies: "Plan 03 depends on 01" → affects wave grouping
   - Checkpoints: human-verify gates before risky operations

3. **Plan Checker Verification Loop:**
   - Max 3 iterations (prevents infinite loops)
   - Gates:
     - **Quality Gate:** Plan clarity, completeness
     - **Requirements Coverage Gate:** Every REQ-ID is addressed
     - **Decision Coverage Gate:** Every decision in CONTEXT.md is implemented
     - **Safety Gate:** No obvious pitfalls or security issues
   - If any gate fails: planner revises until clean

4. **TDD Mode (`workflow.tdd_mode: true`):**
   - Planner applies `type: tdd` to eligible tasks
   - Test-first approach integrated into planning
   - References `tdd.md` for integration patterns

5. **Adaptive Context (1M models):**
   - When context window >= 500K (Opus 4.6, Sonnet 4.6)
   - Planner receives prior phase CONTEXT.md + SUMMARY.md + explicit dependencies
   - Enables cross-phase awareness within a phase

6. **Flags:**
   - `--skip-research`: Skip research if domain is familiar
   - `--auto`: Non-interactive planning
   - `--validate`: Validate state before planning
   - `--bounce`: External plan bounce validation (custom script)
   - `--ingest <ADR-file>`: Use ADR instead of discuss-phase
   - `--reviews`: Replan with cross-AI review feedback

**Artifacts Created:**
- `{phase}-RESEARCH.md` — Ecosystem research, package legitimacy audit, technical findings
- `{phase}-{N}-PLAN.md` — Executable plan files (01-01, 01-02, ...)
- `{phase}-VALIDATION.md` — Verification coverage (Nyquist sampling)

---

### Step 4: `/gsd-execute-phase [N]` — Wave-Based Parallel Execution

**Purpose:** Execute all plans in parallel waves (fresh context per executor)

**Workflow:**
```
Parse args + initialize context
  ↓
Analyze dependencies → Wave grouping
  ├── Plan 01 (no deps) ─┐
  ├── Plan 02 (no deps) ─┤ Wave 1 (parallel)
  ├── Plan 03 (dep: 01) ─┤ Wave 2 (waits for Wave 1)
  └── Plan 04 (dep: 02) ─┘
  ↓
Per-wave: Spawn executors in parallel
  │  ├── Fresh 200K context window per executor
  │  ├── Project context (PROJECT.md, STATE.md)
  │  ├── Phase context (CONTEXT.md, RESEARCH.md)
  │  ├── Specific PLAN.md to execute
  │  ├── Commit atomically per task (conventional commits)
  │  └── Create SUMMARY.md per plan
  ↓
Post-wave: Run pre-commit hooks once (not per-agent)
  ↓
All waves complete → Verifier
```

**Key Practices:**

1. **Wave Analysis:**
   - Grouping independent plans for parallel execution
   - Dependency graph: Plan B cannot start until Plan A commits
   - If 10 plans with no deps: all run in Wave 1 simultaneously
   - Adaptive: can execute specific wave with `--wave N`

2. **Executor Agent:**
   - Fresh 200K context (or adaptive up to 1M)
   - Receives: PLAN.md, project context, phase context
   - Creates code + SUMMARY.md per plan
   - Commits atomically per task (conventional commits: feat, fix, refactor, docs)
   - Never blocks — next wave starts immediately after prior wave completes

3. **Parallel Safety Mechanisms:**
   - **--no-verify commits:** Executors skip pre-commit hooks (prevents lock contention in Rust projects)
   - **Orchestrator runs hooks once per wave:** After all parallel tasks complete
   - **STATE.md locking:** Atomic creation (O_EXCL) + stale lock detection (10s timeout) + spin-wait with jitter
   - Prevents read-modify-write race condition

4. **Context Enrichment (1M Models):**
   - Executor receives all prior wave SUMMARY.md + phase CONTEXT.md
   - Enables cross-plan awareness (Plan 03 knows what Plan 01-02 shipped)
   - Standard 200K windows get truncated prompts (cache-friendly ordering)

5. **Checkpoint Handling:**
   - If a task has `checkpoint:human-verify`: pause execution, ask user
   - User approves or rejects (blocks proceeding until resolved)

6. **Post-Execution Gates:**
   - **Schema Drift Gate:** Compare `.planning/codebase/STRUCTURE.md` (last mapped commit) vs HEAD
     - Detects new directories, barrel exports, migrations, route modules
     - Warns or auto-remaps based on `workflow.drift_action`
   - **Decision Coverage Gate (non-blocking):** CONTEXT.md decisions → shipped artifacts

**Artifacts Created:**
- `{phase}-{N}-SUMMARY.md` — Per-plan execution outcome, what was shipped
- `.planning/codebase/STRUCTURE.md` updated (drift detection)
- Git commits (one per task, conventional format)

---

### Step 5: `/gsd-verify-work [N]` — Post-Execution Verification

**Purpose:** Walk through what was built, diagnose failures, generate fix plans

**Workflow:**
```
User acceptance testing (manual)
  ├── Walk through phase features
  ├── Test acceptance criteria from ROADMAP.md success criteria
  ├── Note issues found
  ↓
Verifier agent
  ├── Reads all PLAN.md, SUMMARY.md, REQUIREMENTS.md
  ├── Checks against phase goals
  ├── Detects failures with dedicated debug agents
  └── Creates VERIFICATION.md with:
      ├── status: (passed | needs-review | needs-repair)
      ├── Results per success criterion
      └── Fix plans (if needed)
  ↓
If repairs needed:
  └── `/gsd-execute-phase --gaps-only` → Re-execute only gap-closure plans
```

**Key Practices:**

1. **UAT (User Acceptance Testing):**
   - Manual walk-through by user
   - Test against phase success criteria (from ROADMAP.md)
   - Document issues as you find them

2. **Verifier Agent:**
   - Independent review of execution
   - Cross-checks PLAN.md against SUMMARY.md and shipped code
   - Identifies gaps or misalignments
   - Generates fix plans if needed (not imperative — just plans)

3. **Verification Status:**
   - `passed` → Phase is complete, move to next
   - `needs-review` → Borderline; requires second opinion
   - `needs-repair` → Failures detected; fix plans generated

4. **Gap Closure:**
   - If `needs-repair`: Run `/gsd-plan-phase --gaps` (replanning with VERIFICATION.md as input)
   - Then `/gsd-execute-phase --gaps-only` (execute only the closure plans)
   - Verify again

**Artifacts Created:**
- `{phase}-VERIFICATION.md` — Status, results, fix plans (if needed)
- `{phase}-UAT.md` — UAT session notes (optional user-written)

---

### Step 6: `/gsd-ship [N]` — Release & Complete Milestone

**Purpose:** Create PR, merge, archive completed phase, tag release

**Workflow:**
```
Coverage check (>= 80% overall, >= 95% business logic)
  ↓
Git branching strategy:
  ├── If interactive: user chooses (merge/keep/discard)
  ├── If auto: merge if all checks pass
  ↓
Create PR (gh pr create)
  ├── Links PLAN.md, SUMMARY.md, VERIFICATION.md
  ├── Auto-suggests reviewers (if enabled)
  ├── Conventional title + body
  ↓
Merge to main
  ↓
Git cleanup (worktree removal if isolation used)
  ↓
If phase is last in milestone:
  ├── Archive all phase artifacts
  ├── Move to `<details>` in ROADMAP.md
  ├── Create git tag (vX.Y.Z)
  └── Update MILESTONES.md
```

**Key Practices:**

1. **Coverage Gates:**
   - Overall coverage must be >= 80%
   - Business logic coverage must be >= 95%
   - Blocks merge if gates fail

2. **PR Quality:**
   - Conventional Commits title (feat, fix, refactor, docs)
   - Linked artifacts (test results, deployment evidence)
   - Auto-linked to REQUIREMENTS.md (REQ-IDs mentioned)

3. **Worktree Cleanup:**
   - If `workflow.use_worktrees: true`: removes git worktree
   - Returns to main checkout
   - State clean for next phase

4. **Milestone Completion:**
   - Last phase in milestone triggers archival
   - All phase artifacts collapsed in ROADMAP.md
   - Tag created (v1.0, v1.1, etc.)
   - MILESTONES.md updated (shipped date, summary)

---

## 2. GSD Agent Taxonomy (31 Agents)

GSD has **31 specialized agents**, organized by spawn category:

### Researchers (4 parallel agents)
- `gsd-project-researcher` — Project-level decisions (stack, frameworks, patterns)
- `gsd-phase-researcher` — Phase-specific ecosystem research
- `gsd-ui-researcher` — UI/UX research for design phases
- `gsd-advisor-researcher` — User-profiling advisor (spawned during discuss-phase if profile exists)

### Synthesizers
- `gsd-research-synthesizer` — Unifies 4 parallel research outputs

### Planners
- `gsd-planner` — Creates detailed PLAN.md files
- `gsd-roadmapper` — Creates ROADMAP.md from requirements

### Checkers (sequential verification loop, max 3 iterations)
- `gsd-plan-checker` — Reviews plans for quality, completeness, gate coverage
- `gsd-integration-checker` — Cross-phase integration validation
- `gsd-ui-checker` — UI implementation quality review
- `gsd-nyquist-auditor` — Verification coverage validation (Nyquist sampling)

### Executors
- `gsd-executor` — Executes plan tasks, commits, creates SUMMARY.md (parallel within waves)

### Verifiers
- `gsd-verifier` — Post-execution verification, identifies gaps

### Mappers
- `gsd-codebase-mapper` — Analyzes codebase, produces `.planning/codebase/*.md` (4 parallel: tech, arch, quality, concerns)

### Debuggers & Auditors
- `gsd-debugger` — Interactive debugging for live issues
- `gsd-ui-auditor` — Visual audit and accessibility checks
- `gsd-security-auditor` — Security-specific audit

### Doc Writers
- `gsd-doc-writer` — Documentation generation
- `gsd-doc-verifier` — Documentation validation

### Analyzers & Profilers
- `gsd-assumptions-analyzer` — Surfaces implementation assumptions
- `gsd-user-profiler` — User behavioral profiling

### Specialized
- `gsd-pattern-mapper` — Detects codebase patterns
- `gsd-code-reviewer` — Code quality review
- `gsd-code-fixer` — Fixes code issues
- `gsd-ai-researcher` — AI-specific research
- `gsd-domain-researcher` — Domain-specific research
- `gsd-eval-planner` — Evaluation planning
- `gsd-eval-auditor` — Evaluation audit
- `gsd-framework-selector` — Framework selection
- `gsd-debug-session-manager` — Debug session tracking
- `gsd-intel-updater` — Intelligence updates

**Agent Lifecycle:**
1. Orchestrator reads `agents/*.md` (YAML frontmatter: name, description, tools, color)
2. Model resolution: `gsd-sdk query resolve-model <agent-name>` → returns opus|sonnet|haiku|inherit
3. Spawn: `Agent(subagent_type="gsd-executor", prompt=..., model=resolved_model)`
4. Fresh context: 200K tokens (or 500K+ for 1M-class models with context_window config)
5. Tools available: Read, Write, Edit, Bash, Grep, Glob, WebSearch, etc. (agent frontmatter declares)

---

## 3. GSD References (60+ Shared Knowledge Docs)

GSD has segregated technical knowledge into `get-shit-done/references/*.md` (workflows and agents reference these, not inline):

**Core:**
- `checkpoints.md` — Checkpoint types (human-verify, integration, safety)
- `gates.md` — 4 canonical gate types (Confirm, Quality, Safety, Transition)
- `model-profiles.md` — Model tier assignments per agent
- `verification-patterns.md` — How to verify different artifact types
- `planning-config.md` — Full config.json schema
- `git-integration.md` — Commit and branching patterns
- `questioning.md` — Dream extraction philosophy (how to elicit vision)
- `tdd.md` — TDD integration patterns

**Thinking Model References:**
- `thinking-models-planning.md` — Thinking class model usage for planning
- `thinking-models-execution.md` — Thinking class usage for execution
- `thinking-models-debug.md` — Thinking class usage for debugging
- `thinking-models-verification.md` — Thinking class usage for verification
- `thinking-models-research.md` — Thinking class usage for research

**Workflow Mechanics:**
- `agent-contracts.md` — Formal interface between orchestrators and agents
- `context-budget.md` — Context window budget allocation
- `revision-loop.md` — Plan revision iteration patterns
- `universal-anti-patterns.md` — Common anti-patterns to detect
- `gate-prompts.md` — Gate/checkpoint prompt templates
- `domain-probes.md` — Domain-specific probing questions
- `artifact-types.md` — Planning artifact definitions
- `phase-argument-parsing.md` — Phase number parsing conventions

**Security:**
- `slopcheck` integration for package legitimacy (see ARCHITECTURE.md)
- Prompt injection detection (`gsd-prompt-guard.js`)
- Supply-chain threat modeling (STRIDE in plans)

---

## 4. Bigpowers Skill Inventory (38 Skills)

For reference, Bigpowers skills mapped by BMAD phase:

| Phase | Skill | Equivalent in GSD |
|-------|-------|-------------------|
| **Discover** | survey-context | (no 1:1; orchestrator reads STATE.md) |
| | elaborate-spec | `/gsd-discuss-phase` (gate discussions) |
| **Elaborate** | model-domain | `/gsd-new-project` → PROJECT.md |
| | define-language | (embedded in PROJECT.md / REQUIREMENTS.md) |
| | challenge-design | (embedded in `/gsd-discuss-phase`) |
| | grill-with-docs | `gsd-ui-researcher` + doc grilling |
| | deepen-architecture | `gsd-codebase-mapper` (4 parallel) |
| **Plan** | scope-work | `/gsd-new-project` → SCOPE (via REQUIREMENTS) |
| | slice-tasks | `/gsd-plan-phase` → PLAN.md files |
| | define-success | ROADMAP.md success criteria |
| | plan-work | `/gsd-plan-phase` → PLAN.md with verify: |
| | plan-refactor | (no explicit skill; embedded in plan-phase) |
| **Spike** | spike-prototype | (embedded in `/gsd-new-project` research phase) |
| **Build** | kickoff-branch | `/gsd-execute-phase` → git branch |
| | guard-git | (no 1:1; GSD uses git hooks) |
| | hook-commits | (GSD has pre-commit integration) |
| | develop-tdd | `workflow.tdd_mode: true` in plan-phase |
| | delegate-task | (no 1:1; orchestrators are thin) |
| | dispatch-agents | `/gsd-execute-phase` (wave-based parallel) |
| | execute-plan | `/gsd-execute-phase` → `gsd-executor` agents |
| | wire-observability | (embedded in executor + status-line hooks) |
| **Bug** | investigate-bug | `/gsd-debug` workflow |
| | diagnose-root | `gsd-debugger` agent |
| | validate-fix | (embedded in verify-phase) |
| **Review** | audit-code | (embedded in plan-checker + execution) |
| | request-review | `/gsd-code-review` workflow |
| | respond-review | (embedded in plan-phase --reviews) |
| **Integrate** | commit-message | Conventional Commits (automated in executors) |
| | release-branch | `/gsd-ship` workflow |
| **Sustain** | inspect-quality | `/gsd-verify-work` → `gsd-verifier` |
| | organize-workspace | `/gsd-workspace` for multi-repo isolation |
| **Utility** | terse-mode | (no 1:1; token budgets prevent need) |
| | craft-skill | (no 1:1; GSD doesn't support skill authoring) |
| | edit-document | (embedded in orchestrators, not a skill) |
| **Bootstrap** | using-bigpowers | `/gsd-new-project` (intro to GSD) |
| | seed-conventions | (CLAUDE.md generated during new-project) |

---

## 5. Gap Analysis: Bigpowers vs. GSD

### 5.1 GSD Has (Bigpowers Lacks)

#### 1. **Formal Orchestration Layer**
- **GSD:** Workflows are explicit state machines with gate definitions
- **Bigpowers:** Orchestration is implicit in skill selection flow
- **Gap:** Bigpowers skills don't declare dependencies or gates; orchestration is manual

#### 2. **Parallel Agent Spawning with Isolation**
- **GSD:** `execute-phase` spawns N executors with fresh 200K context each, parallel within waves
- **Bigpowers:** `dispatch-agents` and `delegate-task` exist, but orchestration is left to the user
- **Gap:** No built-in wave analysis or dependency management

#### 3. **Supply-Chain Security Gates**
- **GSD:** Package Legitimacy Audit (slopcheck) + [SLOP]/[SUS]/[OK] verdicts
- **Bigpowers:** No security gate for package recommendations
- **Gap:** Hallucinated package names can slip through

#### 4. **Success Criteria in Roadmap**
- **GSD:** ROADMAP.md has observable success criteria per phase
- **Bigpowers:** RELEASE-PLAN.md has WSJF and focus area, but no observable criteria
- **Gap:** Verification success is not pre-defined; harder to know when a phase is done

#### 5. **Comprehensive Reference Library**
- **GSD:** 60+ segregated references (gates, patterns, thinking models, domain probes)
- **Bigpowers:** Practices embedded in CONVENTIONS.md + inline SKILL.md comments
- **Gap:** Knowledge is distributed; harder to find and reuse

#### 6. **Context Propagation Model**
- **GSD:** Explicit document flow (PROJECT.md → ROADMAP.md → CONTEXT.md → RESEARCH.md → PLAN.md → VERIFICATION.md)
- **Bigpowers:** Ad-hoc file creation (specs/*.md) with no declared propagation
- **Gap:** Agents don't know which docs to read in which order

#### 7. **Model Profiles & Adaptive Context**
- **GSD:** Model assignment per agent (opus for planning, sonnet for research) + 1M context enrichment
- **Bigpowers:** Model is inherited from session; no per-skill assignment
- **Gap:** No cost-aware model routing; no adaptive context for large models

#### 8. **Package Discovery & Legitimacy**
- **GSD:** Slopcheck integration with verdicts
- **Bigpowers:** Manual package selection in plan
- **Gap:** No automated legitimacy checking

#### 9. **Assumption Surfacing**
- **GSD:** `/gsd-discuss-phase --assumptions` surfaces Claude's assumptions about the phase
- **Bigpowers:** No equivalent; assumptions are implicit
- **Gap:** User doesn't see what Claude thinks before planning begins

#### 10. **Automated Code Analysis**
- **GSD:** `gsd-codebase-mapper` (4 parallel agents) produce `.planning/codebase/*.md`
- **Bigpowers:** `survey-context` is manual or light
- **Gap:** No systematic codebase analysis before planning starts

---

### 5.2 Bigpowers Has (GSD Lacks)

#### 1. **Verb-Noun Skill Names**
- **Bigpowers:** `develop-tdd`, `validate-fix`, `challenge-design` (Uncle Bob naming)
- **GSD:** Commands are `/gsd-command-name` (hyphenated, not verb-noun consistent)
- **Win for Bigpowers:** Names are more discoverable and memorable

#### 2. **BMAD Phase Clarity**
- **Bigpowers:** Discover → Elaborate → Plan → Build → Sustain (explicit phase model)
- **GSD:** Phases are numbered (1, 2, 3, ...) without semantic labeling
- **Win for Bigpowers:** Phases are self-explanatory

#### 3. **Explicit Verification Commands**
- **Bigpowers:** `validate-fix` skill with runnable verify steps
- **GSD:** Embedded in `gsd-verifier` agent
- **Win for Bigpowers:** Verification is a first-class skill, not an embedded step

#### 4. **Skill-Driven Composition**
- **Bigpowers:** User picks skills in any order (flexible)
- **GSD:** Workflows are prescriptive (new-project → discuss → plan → execute → verify → ship)
- **Win for Bigpowers:** More flexible for non-standard workflows

#### 5. **No Prescribed Session Structure**
- **Bigpowers:** Skills can be invoked in any order; flexible orchestration
- **GSD:** `/gsd-new-project` is always first (hard requirement)
- **Win for Bigpowers:** Better for brownfield projects or partial workflows

#### 6. **Explicit Consolidation (SKILL-INDEX.md)**
- **Bigpowers:** Single canonical skill index (our analysis proposal)
- **GSD:** Skills must be discovered from CLI listing or docs
- **Win for Bigpowers:** Easier inventory management

---

### 5.3 Critical Gaps in Both

#### 1. **Brownfield Project Support**
- **GSD:** `/gsd-map-codebase` exists (4 parallel mappers)
- **Bigpowers:** Minimal; `survey-context` is light
- **Missing:** Systematic codebase analysis for existing codebases
- **Recommendation:** Both need deeper codebase-first planning

#### 2. **Async/Offline Handoff**
- **GSD:** `continue-here.md` for session resumption
- **Bigpowers:** STATE.md is static; no resumption format
- **Missing:** Structured handoff between sessions or agents
- **Recommendation:** Define continuation format (like GSD's)

#### 3. **Cross-AI Review Loops**
- **GSD:** `/gsd-plan-review-convergence` (replan until no HIGH concerns)
- **Bigpowers:** `request-review` → `respond-review` (one cycle)
- **Missing:** Automated convergence loops
- **Recommendation:** Add convergence loop to Bigpowers

#### 4. **Versioning & Branching Strategy**
- **GSD:** `branching_strategy` in config.json (merge/keep/discard)
- **Bigpowers:** CONVENTIONS.md mentions `gh pr` but no strategy config
- **Missing:** Formal branching strategy management
- **Recommendation:** Add to CLAUDE.md or config equivalent

---

## 6. Detailed Practice Comparison by Step

### Step: Project Initialization

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **Entry Point** | `/gsd-new-project` (interactive) | `using-bigpowers` → `elaborate-spec` + `model-domain` |
| **Questioning** | Deep domain-specific probes (questioning.md philosophy) | Conversational; no prescribed probes |
| **Research** | 4 parallel agents (Stack, Features, Architecture, Pitfalls) | No systematic research step |
| **Requirements** | Explicit REQ-XX tracking, Validated/Active/Out of Scope | Via SCOPE.md, no explicit tracking |
| **Roadmap** | Phases with success criteria, plan counts, wave analysis | RELEASE-PLAN.md with WSJF, no success criteria |
| **Scope Guardrails** | HARD GATE: No scope creep, even if user suggests | No guardrail; user can add scope freely |
| **Auto Mode** | `--auto @prd.md` skips questions, keeps research | No equivalent |
| **Artifacts** | PROJECT.md, REQUIREMENTS.md, ROADMAP.md, research/, STATE.md, config.json | CLAUDE.md, CONVENTIONS.md, SCOPE.md (manual) |

### Step: Phase Context (Discuss/Plan)

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **Gray Area ID** | Phase-specific (not generic categories) | `challenge-design` is conversational |
| **Decision Capture** | CONTEXT.md with locked choices | No explicit decision artifact |
| **Scope Boundaries** | HARD GATE: Clarify vs. creep distinction | Ad-hoc |
| **Documentation** | DISCUSSION-LOG.md (audit trail) | No equivalent |
| **Mode Flexibility** | 6+ modes (--auto, --batch, --analyze, --power, --all, --assumptions) | Single conversational mode |
| **Artifacts** | {phase}-CONTEXT.md, {phase}-DISCUSSION-LOG.md | No explicit artifact |

### Step: Planning

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **Research** | Mandatory (unless --skip-research) | Not explicitly in skill |
| **Package Security** | Slopcheck + [SLOP]/[SUS]/[OK] gates | No security check |
| **Task Format** | Every task has `verify: <command>` | Plan.md uses `→ verify:` per Karpathy |
| **Dependency Management** | Plans declare dependencies; affects wave grouping | Not declared; affects execution order |
| **Plan Verification** | Max 3-iteration checker loop | One-pass execution; no loop |
| **Checkpoints** | `checkpoint:human-verify` before [ASSUMED] packages | No checkpoint mechanism |
| **TDD Integration** | `workflow.tdd_mode: true` applies type:tdd to tasks | `develop-tdd` skill exists |
| **Artifacts** | {phase}-RESEARCH.md, {phase}-{N}-PLAN.md, {phase}-VALIDATION.md | PLAN.md (single file) |

### Step: Execution

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **Wave Analysis** | Automatic grouping by dependencies | No grouping; sequential or manual parallelism |
| **Parallel Agents** | Multiple executors per wave; fresh context each | `dispatch-agents` requires manual call |
| **Context Isolation** | Fresh 200K per executor | Inherited from orchestrator |
| **Adaptive Context** | 1M models receive prior wave SUMMARY.md + CONTEXT.md | No adaptive enrichment |
| **Commit Safety** | --no-verify per executor + hooks once per wave | Ad-hoc; no formal safety mechanism |
| **STATE.md Locking** | Atomic writes with O_EXCL + stale detection | Not formalized |
| **Checkpoint Handling** | Pause execution, ask user, resume | No equivalent |
| **Post-Execution Gates** | Schema Drift Gate + Decision Coverage Gate | Not formalized |
| **Artifacts** | {phase}-{N}-SUMMARY.md, git commits | Code commits; SUMMARY.md manual |

### Step: Verification

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **UAT** | Manual walk-through + Verifier agent | Not formalized |
| **Verifier Agent** | Reads PLAN.md, SUMMARY.md, REQUIREMENTS.md; identifies gaps | `validate-fix` is manual |
| **Status Tracking** | VERIFICATION.md with passed|needs-review|needs-repair | No formal status |
| **Gap Closure** | `/gsd-plan-phase --gaps` + `/gsd-execute-phase --gaps-only` | `validate-fix` then re-execute manually |
| **Artifacts** | {phase}-VERIFICATION.md, (optional) {phase}-UAT.md | No formal artifact |

### Step: Release

| Aspect | GSD | Bigpowers |
|--------|-----|-----------|
| **Coverage Gates** | >= 80% overall, >= 95% business logic | Not formalized |
| **PR Creation** | Automatic `gh pr create` with linked artifacts | Manual `release-branch` skill |
| **Branching Strategy** | Config-driven (merge/keep/discard) | User decides |
| **Worktree Cleanup** | Automatic if `use_worktrees: true` | Manual (via `guard-git`) |
| **Milestone Archival** | Automatic collapse + tag creation | Manual (via `complete-milestone`) |
| **Artifacts** | PR linked to PLAN.md, SUMMARY.md, VERIFICATION.md | Commit with message (via `commit-message`) |

---

## 7. Key Insights & Recommendations

### 7.1 Architecture Philosophy

**GSD: Orchestration-first**
- User calls `/gsd-command` → Orchestrator loads context → Spawn agents → Collect → Update state
- Workflows are state machines with explicit gates
- Agents are thin specialists (each does one role)
- Decision flow is: orchestrator controls the sequence, agents execute within that sequence

**Bigpowers: Skill-first**
- User calls skill → Skill prompt runs → Ad-hoc agent spawning if needed
- Skills are user-facing entry points (verb-noun names)
- Orchestration is manual (user chains skills)
- Decision flow is: user picks the next skill, skill runs to completion

**Hybrid Opportunity:** Bigpowers could keep skill-first naming but add thin orchestrators that call skills in sequence. e.g.:
```
/gsd-new-project → survey-context → elaborate-spec → model-domain → ... → plan-work
```

### 7.2 Context Isolation

**GSD:** Fresh 200K per agent is a killer feature.
- Prevents context rot (quality degradation as context window fills)
- Each agent starts clean with only what it needs
- Requires explicit context propagation (orchestrator loads + passes)

**Bigpowers:** Relies on inherited session context
- No context rot protection
- Simpler for small projects, breaks down as complexity grows

**Recommendation:** Adopt context isolation in Bigpowers via orchestrators
- Each skill spawn gets `<files_to_read>` + `<context>` sections
- Orchestrator manages handoff between skills

### 7.3 Security Gates

**GSD's supply-chain gate is unique:**
- Blocks hallucinated package names (major AI coding risk)
- Integrated into research → plan → execute pipeline
- Easy to add to Bigpowers: extend `plan-work` with slopcheck call

**Recommendation:** Add to Bigpowers `plan-work`:
```markdown
## Package Legitimacy
Before recommending external packages:
1. Run slopcheck on each package
2. Tag results: [SLOP] remove, [SUS] add checkpoint, [OK] approve
3. Add to plan: checkpoint:human-verify before [SUS] installs
```

### 7.4 Success Criteria & Verification

**GSD:** ROADMAP.md success criteria are user-perspective observable behaviors.
- Phase 1 Goal: "User can sign up with email"
- Success Criteria: 1. "Signup form displays" 2. "Email validation works" 3. "Password reset works"
- Verifier checks these explicitly

**Bigpowers:** RELEASE-PLAN.md has "Objective" but no success criteria
- "v1.17.0 — Guardrails" (what is success here?)
- Harder to know when a release is done

**Recommendation:** Add success criteria to RELEASE-PLAN.md per release:
```markdown
### v1.17.0 — Guardrails (WSJF 3.2)

**Success Criteria:**
- [ ] "Zoom-out mandate" implemented in plan-work as HARD-GATE
- [ ] Surgical changes checklist in audit-code passes 100% tests
- [ ] CONVENTIONS.md explicitly forbids "touch unrelated code"
```

### 7.5 Orchestration Formality

**GSD:** Workflows are rigid (new-project → discuss → plan → execute → verify → ship)
- Pro: Clear execution path, no decision paralysis
- Con: Less flexible for non-standard scenarios

**Bigpowers:** Skills are flexible (user picks next skill)
- Pro: Adapts to any workflow
- Con: Easy to skip steps, hard to enforce mandatory gates

**Recommendation:** Bigpowers could add "orchestration modes":
- **Standard:** Enforce discover → elaborate → plan → build → verify → release flow
- **Brownfield:** Skip discover, start from `survey-context`
- **Ad-hoc:** Pick skills freely (current Bigpowers behavior)

### 7.6 Agent Specialization

**GSD:** 31 specialized agents
- Researchers, Planners, Checkers, Executors, Verifiers, Mappers, Debuggers, Auditors
- Each agent has a single role
- Model profile per agent (opus for planning, sonnet for research)

**Bigpowers:** 38 skills, each invokes implicit agents
- No predefined agent catalog
- Skill is the entry point; agent role is implied

**Recommendation:** Define Bigpowers agent taxonomy (like GSD's):
```
Researchers: survey-context, elaborate-spec, model-domain
Planners: plan-work, plan-refactor
Checkers: audit-code, request-review
Executors: develop-tdd, execute-plan
Verifiers: validate-fix, inspect-quality
Mappers: deepen-architecture
Debuggers: investigate-bug, diagnose-root
```

---

## 8. Bigpowers Enhancements (Priority Order)

### **Tier 1: Critical (Foundation)**

1. **Add Orchestration Layer** (like GSD workflows)
   - Define prescriptive core loop: survey → elaborate → plan → build → verify → ship
   - Add gates: No code without plans, no plans without research, no shipping without verification
   - Deliverable: `ORCHESTRATION.md` + thin coordinator skills

2. **Add Context Isolation to Skill Spawning**
   - Each skill spawn gets `<files_to_read>` + `<context>` sections
   - Prevents context rot
   - Deliverable: Update `execute-plan`, `plan-work`, `develop-tdd` with isolation

3. **Add Supply-Chain Security Gate**
   - Integrate slopcheck into `plan-work`
   - Tag packages [SLOP]/[SUS]/[OK]
   - Add checkpoint:human-verify before [SUS] installs
   - Deliverable: Updated `plan-work` skill + security reference

### **Tier 2: Important (UX/Clarity)**

4. **Add Success Criteria to RELEASE-PLAN.md**
   - Per-release observable behaviors
   - Feeds into `validate-fix` verification
   - Deliverable: Updated RELEASE-PLAN template

5. **Add Reference Library (like GSD's)**
   - Segregate knowledge from SKILL.md into `references/`
   - Examples: gates.md, verification-patterns.md, tdd.md, thinking-models-*.md
   - Deliverable: `references/` directory with 15-20 core docs

6. **Formalize Agent Taxonomy**
   - Map Bigpowers skills to agent roles (Researcher, Planner, Executor, Verifier, etc.)
   - Define model profiles (opus for planning, sonnet for research)
   - Deliverable: `AGENTS.md` documenting all agents + roles

### **Tier 3: Nice-to-Have (Ergonomics)**

7. **Add Automated Wave Analysis**
   - Parse plan dependencies; group into waves for parallel execution
   - Deliverable: Enhancement to `execute-plan`

8. **Add Assumption Surfacing**
   - Like `/gsd-discuss-phase --assumptions`
   - Before planning, Claude surfaces what it's assuming about the phase
   - Deliverable: Enhancement to `plan-work` or dedicated skill

9. **Add Package Discovery & Legitimacy**
   - Automated package recommendation with verification
   - Deliverable: Enhancement to research step of `plan-work`

10. **Add Continuation Format**
    - Like GSD's `continue-here.md`
    - Structured session resumption between context resets
    - Deliverable: `continuation-format.md` + tool support

---

## 9. Conclusion

**GSD is engineered for production reliability:**
- Orchestration is explicit and auditable
- Context isolation prevents rot
- Security gates prevent supply-chain attacks
- Verification is multi-step and rigorous

**Bigpowers is engineered for developer ergonomics:**
- Skill names are memorable (verb-noun)
- BMAD phases are self-explanatory
- Skill composition is flexible
- Perfect for solo developers who know what they want

**Hybrid Approach:** Bigpowers + GSD orchestration + GSD security gates would be ideal:
- Keep Bigpowers' verb-noun skill names and BMAD phases
- Add GSD's orchestration layer and context isolation
- Add GSD's security gates and reference library
- Result: Bigpowers' usability + GSD's production reliability

---

## 10. Full GSD Workflow Call Map (6 Commands)

```
START
  ↓
/gsd-new-project
  ├── Questions + 4 parallel researchers
  ├── Synthesizer
  ├── Roadmapper
  ├── User approval
  └── → PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, research/, config.json
  ↓
LOOP [for each phase]:
  ├── /gsd-discuss-phase [N]
  │   ├── Gray area identification
  │   ├── User discussion (6+ modes: --auto, --batch, --analyze, --power, --all, --assumptions)
  │   └── → {phase}-CONTEXT.md, {phase}-DISCUSSION-LOG.md
  │   ↓
  ├── /gsd-plan-phase [N]
  │   ├── Research (if needed)
  │   │   ├── Phase Researcher
  │   │   ├── Package Legitimacy Audit (slopcheck)
  │   │   └── → {phase}-RESEARCH.md with [SLOP]/[SUS]/[OK] verdicts
  │   │   ↓
  │   ├── Planning (max 3 iterations if issues found)
  │   │   ├── Planner
  │   │   │   ├── Every task: verify: <command>
  │   │   │   ├── Dependencies declared
  │   │   │   ├── Checkpoints for [ASSUMED]/[SUS]
  │   │   │   └── STRIDE threat model
  │   │   │   ↓
  │   │   └── Plan Checker (loop until clean)
  │   │       ├── Quality Gate
  │   │       ├── Requirements Coverage Gate (REQ-IDs)
  │   │       ├── Decision Coverage Gate (CONTEXT.md)
  │   │       └── Safety Gate
  │   │   ↓
  │   └── → {phase}-{N}-PLAN.md files
  │   ↓
  ├── /gsd-execute-phase [N]
  │   ├── Wave analysis (dependency grouping)
  │   ├── Per-wave: spawn executors in parallel
  │   │   ├── Fresh 200K context per executor
  │   │   ├── Execute task
  │   │   ├── Commit atomically (conventional)
  │   │   └── Create SUMMARY.md
  │   ├── Post-wave: run pre-commit hooks once
  │   ├── Schema Drift Gate
  │   └── → {phase}-{N}-SUMMARY.md, git commits
  │   ↓
  ├── /gsd-verify-work [N]
  │   ├── User acceptance testing (manual)
  │   ├── Verifier agent review
  │   │   ├── Read PLAN.md, SUMMARY.md, REQUIREMENTS.md
  │   │   ├── Identify gaps
  │   │   ├── Generate fix plans (if needed)
  │   │   └── Status: passed | needs-review | needs-repair
  │   ├── If needs-repair:
  │   │   ├── /gsd-plan-phase --gaps
  │   │   ├── /gsd-execute-phase --gaps-only
  │   │   └── Re-verify
  │   └── → {phase}-VERIFICATION.md
  │   ↓
  ├── /gsd-ship [N]
  │   ├── Coverage gates (>= 80%, >= 95% business logic)
  │   ├── Create PR (gh pr create)
  │   ├── Merge to main
  │   ├── Worktree cleanup (if used)
  │   ├── If last phase in milestone:
  │   │   ├── Archive phase artifacts
  │   │   ├── Create git tag (vX.Y.Z)
  │   │   └── Update MILESTONES.md
  │   └── → Release shipped
  │   ↓
END LOOP
```

This is the core GSD workflow. Optional workflows exist for debugging, code review, documentation, workspace management, etc.

