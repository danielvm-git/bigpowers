# HARD GATE Enforcement Reference

**Purpose:** Canonical HARD GATEs for each BMAD phase — critical decision points and constraints that must be enforced during skill execution.

**Format:** Blockquote markdown `> **HARD GATE** — [constraint description]` followed by optional context paragraph(s).

**Examples:** See `plan-work/SKILL.md`, `develop-tdd/SKILL.md`, `verify-work/SKILL.md`

---

## Bootstrap Phase

**Skills:** `using-bigpowers`

### Canonical HARD GATE
> **HARD GATE** — This skill is the entry point. Do NOT skip it when onboarding new users or starting a new session. It establishes the bigpowers methodology, lifecycle phases, and conventions.

**Rationale:** Ensures users understand the methodology before diving into specific skills.

---

## Orchestrate Phase

**Skills:** `orchestrate-project`

### Canonical HARD GATE
> **HARD GATE** — Do NOT invoke orchestrate-project unless you have a clear multi-phase workflow. Single-skill tasks should use dedicated skills instead. Orchestrate is for complex, multi-stage work that requires coordination across phases.

**Rationale:** Prevents over-engineered solutions for simple tasks.

---

## Discover Phase

**Skills:** `survey-context`, `research-first`, `elaborate-spec`, `map-codebase`

### Canonical HARD GATE (Context Understanding)
> **HARD GATE** — Do NOT proceed with planning or design until the problem space is clearly understood. If context is missing (no SCOPE, no VISION, no glossary), run survey-context or research-first first to establish shared understanding.

**Rationale:** Prevents misaligned work; saves rework downstream.

### Additional Gates (by skill)

**survey-context:**
> **HARD GATE** — Read specs/ files before suggesting next steps. If state.yaml is stale or contradicts the codebase, request clarification rather than assuming intent.

**research-first:**
> **HARD GATE** — If this task exists or is similar to prior work, document prior art references and delta from baseline. Do NOT proceed as if this is greenfield.

**map-codebase:**
> **HARD GATE** — Cold analysis only. Do NOT assume architectural patterns without reading the code. If the codebase structure surprises you, call out the delta.

---

## Elaborate Phase

**Skills:** `model-domain`, `define-language`, `grill-me`, `grill-with-docs`, `deepen-architecture`, `design-interface`

### Canonical HARD GATE (Domain Clarity)
> **HARD GATE** — Do NOT design a solution until the domain model is explicit. Entities, invariants, state machines, and glossary must be articulated before interface/architecture design.

**Rationale:** Domain clarity prevents architectural misalignment.

### Additional Gates (by skill)

**model-domain:**
> **HARD GATE** — Capture invariants (what MUST always be true) and state machines (what transitions are legal) for core entities. If these are fuzzy, design will fail.

**define-language:**
> **HARD GATE** — Ubiquitous language is NOT optional. Every term in the domain that could be misunderstood must be glossed. Ambiguity = rework.

**grill-me / grill-with-docs:**
> **HARD GATE** — Do NOT accept a design until every hard decision has been stress-tested. "Seems right" is not a decision. Grilling must identify and resolve tensions before build begins.

**deepen-architecture:**
> **HARD GATE** — Deep modules must solve a forcing function, not just be "nice abstractions." If you cannot articulate why the abstraction exists, it is premature.

**design-interface:**
> **HARD GATE** — Multiple design options must be explored. Do NOT settle on first idea. Compare trade-offs (UX, complexity, extensibility, performance) before committing.

---

## Spike Phase

**Skills:** `spike-prototype`

### Canonical HARD GATE
> **HARD GATE** — Spikes are time-boxed experiments, not shipping code. Results must be throwaway or clearly isolated. Do NOT merge a spike without a plan to integrate it or replace it with a proper implementation.

**Rationale:** Prevents technical debt from experimental work.

---

## Plan Phase

**Skills:** `assess-impact`, `change-request`, `scope-work`, `slice-tasks`, `define-success`, `plan-work`, `plan-refactor`, `plan-release`

### Canonical HARD GATE (Planning Discipline)
> **HARD GATE** — Do NOT proceed with a plan until the task's success criteria are clear and unambiguous. If success is unclear, run `define-success` first. Every step must pair with a `verify: <runnable command>` proof.

**Rationale:** Prevents vague planning; ensures work is measurable.

### Additional Gates (by skill)

**assess-impact:**
> **HARD GATE** — Before modifying an existing module, state: (1) the module's purpose, (2) its callers, (3) the contracts it maintains. If you cannot answer all three without deep archaeology, stop and clarify scope.

**scope-work:**
> **HARD GATE** — Scope boundaries must be explicit. In-scope and out-of-scope must be listed. Do NOT merge in-scope items discovered mid-execution without replanning.

**define-success:**
> **HARD GATE** — Success criteria must be testable and user-observable. "Code should be fast" is not testable. "Pageload latency < 2s" is testable.

**plan-work:**
> **HARD GATE** — Do NOT write code without a step-by-step plan in the active epic shard. Every step must be verifiable with a single runnable command. "I think it works" is not verification.

**plan-refactor:**
> **HARD GATE** — Before refactoring, document the current behavior and why it is wrong. Extract one invariant that must be preserved. If you skip this, you will break things you don't expect.

---

## Initiate Phase

**Skills:** `kickoff-branch`, `guard-git`, `hook-commits`, `seed-conventions`

### Canonical HARD GATE (Branch Protection)
> **HARD GATE** — Do NOT proceed with work on main/master. Run `kickoff-branch` first to create a feature branch or worktree. All code changes must flow through feature branches.

**Rationale:** Prevents accidental pushes to main; enforces code review.

### Additional Gates (by skill)

**guard-git:**
> **HARD GATE** — Before committing, verify: branch is not main/master, author is correct, git user is configured. Bad commits are hard to fix.

**hook-commits:**
> **HARD GATE** — Pre-commit and commit-msg hooks must run before any commit lands. Skipping hooks (`--no-verify`) is forbidden unless explicitly authorized for a specific commit and documented.

**seed-conventions:**
> **HARD GATE** — Before any new code lands, confirm the project conventions are understood. Ask: "What does a good commit message look like in this project?"

---

## Build Phase

**Skills:** `develop-tdd`, `enforce-first`, `delegate-task`, `dispatch-agents`, `execute-plan`, `build-epic`, `run-planning`, `fix-bug`

### Canonical HARD GATE (Build Discipline)
> **HARD GATE** — Do NOT write code before you have a plan. New feature: run `plan-work` first, epic shard tasks required. Bug: run `investigate-bug` first, specs/bugs/BUG-*.md required. Do NOT guess the root cause.

**Rationale:** Prevents unplanned coding; ensures work is traceable.

### Additional Gates (by skill)

**develop-tdd:**
> **HARD GATE** — Do NOT proceed if on main/master. Run `kickoff-branch` first. Red-green-refactor loop: write test first, make it fail, write code, make it pass, refactor.

**enforce-first:**
> **HARD GATE** — Before shipping, ALL enforcement checks must pass: lint, typecheck, tests, coverage gates. Do NOT disable or skip checks to get to green.

**delegate-task:**
> **HARD GATE** — Delegated work must have clear success criteria and verification commands. The delegate must be able to verify completion independently.

**dispatch-agents:**
> **HARD GATE** — Agent work must be parallelizable and have explicit synchronization points. Do NOT dispatch work that has hidden dependencies between agents.

**execute-plan:**
> **HARD GATE** — Active epic must exist with runnable verify on each task. Do NOT proceed without a plan in specs/epics/*.yaml. Every task failure must be fixed before advancing.

---

## Harden Phase

**Skills:** `wire-observability`

### Canonical HARD GATE
> **HARD GATE** — Observability is not optional. Before shipping, verify: structured logging is in place, key metrics are instrumented, error cases emit signals. "We'll add metrics later" becomes "never."

**Rationale:** Operational visibility is critical for production systems.

---

## Verify Phase

**Skills:** `verify-work`, `run-evals`

### Canonical HARD GATE (Verification Discipline)
> **HARD GATE** — No story is "done" until manual UAT for the active story is confirmed with evidence. Do NOT declare victory on green tests alone; user-observable behavior must be verified.

**Rationale:** Prevents shipping features that don't work in practice.

### Additional Gates (by skill)

**verify-work:**
> **HARD GATE** — Do NOT run on main/master. Use feature branch from kickoff-branch. Cold-start smoke test required (stop, clear caches, rebuild, test from scratch).

**run-evals:**
> **HARD GATE** — Before running evals, confirm the success metrics are measurable and the baseline is known. "Is this better?" requires a comparison point.

---

## Bug Phase

**Skills:** `investigate-bug`, `diagnose-root`, `validate-fix`

### Canonical HARD GATE (Bug Investigation)
> **HARD GATE** — Do NOT write a fix without investigating the root cause. Root cause investigation must be documented in specs/bugs/BUG-*.md with: (1) symptoms, (2) reproduction steps, (3) root cause hypothesis, (4) why the hypothesis is correct.

**Rationale:** Prevents fixing symptoms instead of causes; prevents recurrence.

### Additional Gates (by skill)

**investigate-bug:**
> **HARD GATE** — Repro the bug yourself before investigating. If you cannot reproduce it, ask for more context. A non-reproducible bug is not a bug; it is incomplete information.

**diagnose-root:**
> **HARD GATE** — Root cause is not "the code is wrong." It is the specific line, logic error, or invariant violation. Quote the offending code in the diagnosis.

**validate-fix:**
> **HARD GATE** — Fix must not regress. Run full test suite and manual UAT before declaring success. A fix that passes tests but breaks something else is a failure.

---

## Review Phase

**Skills:** `audit-code`, `request-review`, `respond-review`, `trace-requirement`

### Canonical HARD GATE (Code Quality)
> **HARD GATE** — Code review is mandatory before merge. Reviewer must understand the change and validate that it solves the stated problem without introducing regressions or anti-patterns.

**Rationale:** Human judgment + automated checks catch issues neither can alone.

### Additional Gates (by skill)

**audit-code:**
> **HARD GATE** — Audit must check for: bugs (correctness), security, performance, and clarity. Do NOT skip security review if the code touches user data, auth, or external APIs.

**request-review:**
> **HARD GATE** — PR must link to the epic/bug it closes and include a clear description of what changed and why. "WIP" PRs are not ready for review.

**respond-review:**
> **HARD GATE** — Every reviewer comment must be addressed (fix, disagree + document reason, or ask clarification). Do NOT ignore feedback and merge.

**trace-requirement:**
> **HARD GATE** — Every change must trace back to a requirement, epic, or bug. Code without a ticket is code debt, not feature work.

---

## Integrate Phase

**Skills:** `commit-message`, `release-branch`

### Canonical HARD GATE (Integration Discipline)
> **HARD GATE** — Commits must follow Conventional Commits spec (type(scope): description). Do NOT use vague messages like "fix" or "updates." The message must explain the "why," not the "what."

**Rationale:** Commit messages are documentation; they enable automated release notes and history navigation.

### Additional Gates (by skill)

**release-branch:**
> **HARD GATE** — Do NOT merge without: (1) passing CI, (2) passing code review, (3) passing manual UAT, (4) clean commit history (no merge commits in user-facing history).

---

## Sustain Phase

**Skills:** `inspect-quality`, `organize-workspace`, `stocktake-skills`, `evolve-skill`

### Canonical HARD GATE (Maintenance Discipline)
> **HARD GATE** — Do NOT let technical debt accumulate. After each story, spend time on: code cleanup, test gaps, documentation updates, and dependency health. Unmaintained code is debt.

**Rationale:** Prevention of decay; keeps codebase healthy long-term.

### Additional Gates (by skill)

**inspect-quality:**
> **HARD GATE** — Quality metrics (coverage, lint, cyclomatic complexity, security scans) must be monitored. If a metric degrades, surface it as a blocker. Do NOT accept regressions.

**organize-workspace:**
> **HARD GATE** — Workspace structure must reflect domain structure. If the codebase feels disorganized, flag it. Disorganization != "just a style thing;" it is a signal of domain misalignment.

**stocktake-skills:**
> **HARD GATE** — Skill inventory must be current. Missing HARD GATEs, stale descriptions, or broken verify commands are defects, not cosmetic. Fix them in `evolve-skill`.

**evolve-skill:**
> **HARD GATE** — Skill improvements must be validated with evidence (new examples, improved clarity, verified use cases). Do NOT ship skills that have not been tested by real users.

---

## Review Phase (continued)

**Skills:** N/A (covered above)

---

## Utility Phase

**Skills:** `terse-mode`, `craft-skill`, `edit-document`, `session-state`, `migrate-spec`, `visual-dashboard`, `write-document`, `setup-environment`, `reset-baseline`, `search-skills`, `compose-workflow`, `simulate-agents`

### Canonical HARD GATE (Utility Safety)
> **HARD GATE** — Utility skills must not have side effects that break the main workflow. If a utility skill modifies state, it must be fully documented and reversible. Do NOT use utility skills to bypass workflow gates.

**Rationale:** Utilities are tools, not shortcuts; they must not weaken enforcement.

### Additional Gates (by skill)

**terse-mode:**
> **HARD GATE** — Terse mode is for reducing token usage in long sessions. Do NOT use terse mode when clarity is critical (complex design decisions, bug investigations). Enable it only on explicit user request.

**craft-skill:**
> **HARD GATE** — New skills must follow verb-noun naming (kebab-case). SKILL.md is the single source of truth; do NOT edit generated artifacts (.cursor/rules, .gemini/). Must have HARD GATE callout.

**edit-document:**
> **HARD GATE** — Document edits must preserve intent and accuracy. Do NOT remove or contradict existing content without understanding why it was written. Check git history for context.

**session-state:**
> **HARD GATE** — Session state must be synchronized with git state. If state.yaml conflicts with the working tree, halt and ask for clarification. Do NOT assume state is correct.

**migrate-spec:**
> **HARD GATE** — Spec migrations must be backwards-compatible or clearly documented as breaking. Do NOT move or rename specs without updating all references. Automated migration scripts required for bulk changes.

**visual-dashboard:**
> **HARD GATE** — Dashboards are read-only. Do NOT use visualization to make decisions without consulting the source data. "The chart looks better" is not a decision.

**write-document:**
> **HARD GATE** — New documents must have a clear purpose and audience. Do NOT create docs that duplicate existing content. Link to related docs for context.

**setup-environment:**
> **HARD GATE** — Environment setup must be idempotent and reproducible. If setup fails, provide clear error messages and remediation steps. Do NOT assume prior state.

**reset-baseline:**
> **HARD GATE** — Baseline resets are destructive. Do NOT proceed without explicit user confirmation. Document what is being reset and why.

**search-skills:**
> **HARD GATE** — Search results must be ranked by relevance. Do NOT return all matches without prioritization. Use skill metadata (phase, purpose, frequency) to rank.

**compose-workflow:**
> **HARD GATE** — Workflows are orchestration, not automation. Do NOT create workflows for tasks that should be single skills. Workflow complexity must be justified.

**simulate-agents:**
> **HARD GATE** — Simulations are hypothetical. Do NOT use sim results to make production decisions without validation on real agents. Sims help discover gaps, not replace testing.

---

## Summary Table

| Phase | Canonical HARD GATE | Applies To |
|-------|-------------------|-----------|
| **Bootstrap** | Entry point enforcement | using-bigpowers |
| **Discover** | Context must be clear before planning | survey-context, research-first, elaborate-spec, map-codebase |
| **Elaborate** | Domain model must be explicit | model-domain, define-language, grill-me, grill-with-docs, deepen-architecture, design-interface |
| **Plan** | Success criteria clear + step verification required | assess-impact, scope-work, define-success, plan-work, plan-refactor, plan-release |
| **Initiate** | Not on main/master + branch protection | kickoff-branch, guard-git, hook-commits, seed-conventions |
| **Build** | Plan required + red-green-refactor | develop-tdd, enforce-first, execute-plan, fix-bug |
| **Verify** | Manual UAT required + cold-start | verify-work, run-evals |
| **Bug** | Root cause investigation required | investigate-bug, diagnose-root, validate-fix |
| **Review** | Code review + traceability required | audit-code, request-review, respond-review, trace-requirement |
| **Integrate** | Conventional commits + clean history | commit-message, release-branch |
| **Sustain** | Quality metrics monitored + tech debt prevented | inspect-quality, organize-workspace, stocktake-skills, evolve-skill |

---

**Date created:** 2026-06-10  
**Last updated:** 2026-06-10  
**Reference:** CONVENTIONS.md, SKILL-INDEX.md, e09s06 (Add HARD GATE enforcement)
