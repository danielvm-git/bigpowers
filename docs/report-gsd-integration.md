# GSD-to-Big Powers Integration Assessment Report

**Date:** 2026-05-19  
**GSD Version:** 1.50.0-canary.0  
**Big Powers Version:** 1.14.0  
**Author:** Daniel VM, Software Orchestrator  

---

## Executive Summary

This report presents the findings of a comprehensive feature-level comparison between **Get Shit Done (GSD)** v1.50.0-canary.0 and **Big Powers** v1.14.0. The goal is to identify GSD features that are missing or underdeveloped in Big Powers, prioritize them by impact and effort, and recommend a concrete integration roadmap.

**Key findings:**

- **74 distinct gaps** were identified across **17 categories**.
- **Big Powers** excels at its core mission: spec-driven, test-first development for solo developers, with a clean 42+ skill architecture, hard gates, and a PMBOK-inspired lifecycle.
- **GSD** is a broader system: it adds multi-agent orchestration (33 agent roles, 88 workflows), a structured `.planning/` artifact system, advanced execution models (wave-based parallelism, cross-AI delegation, failure-tier escalation), a comprehensive hook system, security hardening, and a full SDK/CLI layer.
- The highest-value, lowest-effort wins are in **context engineering** (context window monitoring, learning store), **quality assurance** (node repair operator, verification debt tracking), and **phase management** (dynamic phase modification, quick mode).
- The highest-impact but higher-effort opportunities are in **multi-agent orchestration** (specialized agent roles, fresh context per agent) and **advanced execution models** (wave-based parallelism, cross-AI delegation).

**Bottom line:** Big Powers has a strong foundation. The recommended approach is to adopt GSD's context engineering and quality assurance features first (quick wins), then incrementally introduce multi-agent orchestration patterns and advanced execution models.

---

## 1. Feature Comparison Overview

### 1.1 Side-by-Side Summary

| Dimension | GSD v1.50.0-canary.0 | Big Powers v1.14.0 |
|-----------|----------------------|---------------------|
| **Core philosophy** | Meta-prompting, context-engineering, spec-driven | Spec-driven, test-first, PMBOK lifecycle |
| **Slash commands** | 67 | ~15 (via skills) |
| **Agent roles** | 33 specialized roles | None predefined |
| **Workflow files** | 88 orchestration workflows | Skills reference each other by name |
| **Skills/extensions** | 15+ install profiles | 42+ skills |
| **Supported runtimes** | 15 AI runtimes | 2 (Gemini Extension, Claude Code) |
| **Test files** | 569+ | N/A (skills don't ship tests) |
| **CI/CD workflows** | 19 GitHub Actions | None |
| **Hook system** | 11+ hooks (pre-commit, session, phase boundary) | 2 (guard-git, hook-commits) |
| **Context management** | Window monitoring, budgeting, thinning, threads | terse-mode (manual) |
| **Artifact system** | `.planning/` (PROJECT.md, REQUIREMENTS.md, ROADMAP.md, specs/state.yaml, CONTEXT.md, config.json) | `specs/` (release-plan.yaml, state.yaml, IMPACT.md) |
| **Execution model** | Wave-based parallel, node repair, cross-AI delegation | Sequential (execute-plan), parallel (dispatch-agents) |
| **Security** | Secret scanning, package legitimacy, prompt injection detection, read-before-edit guard | guard-git (destructive op blocking) |
| **SDK** | TypeScript SDK (200+ modules), CLI transport | None |
| **Installer** | Universal, profile-based, multi-runtime | Gemini Extension |
| **Documentation** | 41 reference docs, 36+ templates, 5-language README | English-only, skill-level docs |
| **Developer profiling** | `/gsd-profile-user` (USER-PROFILE.md) | `memory` tool (unstructured) |
| **Project management** | Milestone lifecycle, workspace management, review backlog, safe undo | release-branch, kickoff-branch |

### 1.2 What Big Powers Does Better

Before diving into gaps, it's important to acknowledge areas where Big Powers is equal or superior:

- **Hard gates and safety:** Big Powers' `guard-git` and explicit HARD GATE pattern are more opinionated and safer than GSD's approach.
- **TDD enforcement:** `develop-tdd` with RED-GREEN-REFACTOR is more rigorous than GSD's execution model.
- **Self-review:** `audit-code` with its 8-dimension checklist and Clean Code Heuristics is more thorough than GSD's code review pipeline.
- **Impact analysis:** `assess-impact` with blast radius analysis is more structured than GSD's approach.
- **WSJF prioritization:** Built into `plan-release` and `change-request`; GSD has no equivalent.
- **Boy Scout Rule enforcement:** Explicit in `audit-code`; not present in GSD.
- **Simplicity:** Big Powers' 42 skills with "one skill, one thing" is more maintainable than GSD's 88 workflows.

---

## 2. Gap Analysis

### 2.1 Prioritization Framework

Gaps are prioritized using a simplified WSJF-like model:

- **Impact:** How much would this improve Big Powers' capabilities? (1-10)
- **Effort:** How complex is this to implement? (1-10, where 10 = months of work)
- **Priority Score:** Impact / Effort (higher = implement sooner)

### 2.2 Tier 1 — Quick Wins (High Impact, Low Effort)

These can be implemented as new or modified skills with minimal architectural changes.

| # | Gap | Category | Impact | Effort | Score | Recommendation |
|---|-----|----------|--------|--------|-------|----------------|
| 4.2 | Context window monitoring & budgeting | Context Eng | 8 | 3 | 2.67 | Add context utilization tracking to `orchestrate`; auto-trigger `terse-mode` when budget exceeded |
| 5.3 | Node repair operator | Quality | 7 | 3 | 2.33 | Extend `execute-plan` to auto-diagnose and retry failed verify commands |
| 2.3 | Quick Mode | Execution | 7 | 3 | 2.33 | Add a `--quick` flag to `orchestrate` that skips research and plan-check gates |
| 5.4 | Verification debt tracking | Quality | 6 | 2 | 3.00 | Add a verification debt section to `specs/state.yaml` |
| 4.4 | Learning store | Context Eng | 6 | 3 | 2.00 | Add `/gsd-extract-learnings` equivalent that saves patterns from completed phases to `specs/LEARNINGS.md` |
| 2.9 | Progress auto-advance | Phase Mgmt | 6 | 3 | 2.00 | Extend `survey-context` with a `--next` flag that runs the recommended next skill |
| 5.5 | Health validation | Quality | 5 | 2 | 2.50 | Add a health check command that validates `specs/` artifact consistency |
| 1.2 | Configurable roadmap granularity | Planning | 5 | 2 | 2.50 | Add granularity parameter to `plan-release` |
| 2.7 | Pause/resume work | Phase Mgmt | 5 | 2 | 2.50 | Formalize `orchestrate --resume` with explicit pause/resume commands |

### 2.3 Tier 2 — Medium-Term Investments (High Impact, Medium Effort)

These require new skills or significant modifications to existing ones.

| # | Gap | Category | Impact | Effort | Score | Recommendation |
|---|-----|----------|--------|--------|-------|----------------|
| 2.2 | Wave-based parallel execution | Execution | 9 | 5 | 1.80 | Extend `execute-plan` with dependency analysis and wave grouping |
| 3.2 | Fresh context per agent | Multi-Agent | 8 | 5 | 1.60 | Formalize context budget management in `delegate-task` |
| 2.5 | Plan review convergence loop | Planning | 7 | 4 | 1.75 | Extend `request-review` with a convergence loop (plan → review → replan) |
| 4.1 | Structured `.planning/` artifact system | Context Eng | 7 | 4 | 1.75 | Add per-phase `CONTEXT.md`, requirement IDs (REQ-XX), and `config.json` to `specs/` |
| 5.1 | 8-dimensional plan checker | Quality | 7 | 4 | 1.75 | Extend `plan-work` with structured 8-dimension verification |
| 3.3 | Thin orchestrator pattern | Multi-Agent | 6 | 3 | 2.00 | Formalize the pattern in `orchestrate` documentation |
| 2.1 | Dynamic phase modification | Phase Mgmt | 6 | 4 | 1.50 | Add phase insert/remove commands to `plan-release` |
| 6.1 | Milestone lifecycle commands | Project Mgmt | 6 | 4 | 1.50 | Add milestone tracking to `release-branch` |
| 7.1 | Codebase mapping | Brownfield | 6 | 4 | 1.50 | Extend `survey-context` with structured codebase mapping output |
| 13.4 | Read-before-edit guard | Security | 5 | 2 | 2.50 | Add a pre-tool-use hook that checks file read history |
| 11.3 | Phase boundary hook | Hooks | 5 | 3 | 1.67 | Add phase transition validation to `orchestrate` |
| 12.4 | Template system | Docs | 5 | 3 | 1.67 | Create a centralized template library for common patterns |

### 2.4 Tier 3 — Strategic Investments (High Impact, High Effort)

These represent significant architectural changes that should be planned carefully.

| # | Gap | Category | Impact | Effort | Score | Recommendation |
|---|-----|----------|--------|--------|-------|----------------|
| 3.1 | 33 specialized agent roles | Multi-Agent | 9 | 8 | 1.13 | Define a core set of 8-10 agent roles (code-reviewer, security-auditor, doc-writer, etc.) |
| 15.1 | Cross-AI execution delegation | Advanced Exec | 8 | 8 | 1.00 | Design cross-AI delegation protocol for `delegate-task` |
| 15.2 | Failure-tier escalation | Advanced Exec | 7 | 6 | 1.17 | Add model escalation to `delegate-task` on failure |
| 10.2 | Multi-runtime support (15 runtimes) | Installer | 7 | 8 | 0.88 | Design runtime abstraction layer for skill delivery |
| 9.1 | GSD SDK | SDK/CLI | 6 | 8 | 0.75 | Design a TypeScript SDK for Big Powers skills |
| 13.1 | Security auditing | Security | 7 | 6 | 1.17 | Add a `security-audit` skill with dependency scanning |
| 15.3 | Per-phase-type model selection | Advanced Exec | 6 | 5 | 1.20 | Add model profile configuration to `orchestrate` |
| 17.1 | Comprehensive planning config | Configuration | 6 | 5 | 1.20 | Add a `config.json` equivalent for Big Powers behavior tuning |
| 1.1 | Adaptive "Dream Extraction" with parallel research | Bootstrap | 7 | 7 | 1.00 | Extend `seed-conventions` with parallel research agents |
| 2.4 | Autonomous Mode | Execution | 7 | 7 | 1.00 | Extend `orchestrate` with a fully autonomous mode |

### 2.5 Tier 4 — Lower Priority (Lower Impact or Very High Effort)

These are nice-to-have but should not be prioritized over Tiers 1-3.

| # | Gap | Category | Impact | Effort | Score |
|---|-----|----------|--------|--------|-------|
| 2.6 | Gap closure mode | Planning | 4 | 3 | 1.33 |
| 2.8 | Plan import | Planning | 3 | 3 | 1.00 |
| 3.4 | 88 workflow files | Multi-Agent | 4 | 7 | 0.57 |
| 4.3 | Context threads | Context Eng | 4 | 5 | 0.80 |
| 4.5 | Socratic exploration | Context Eng | 3 | 3 | 1.00 |
| 5.2 | Nyquist validation | Quality | 3 | 3 | 1.00 |
| 5.6 | Milestone audit | Quality | 4 | 4 | 1.00 |
| 5.7 | Code review pipeline with auto-fix | Quality | 4 | 5 | 0.80 |
| 6.2 | Workspace management | Project Mgmt | 3 | 4 | 0.75 |
| 6.3 | Review backlog | Project Mgmt | 2 | 2 | 1.00 |
| 6.4 | Safe undo | Project Mgmt | 3 | 5 | 0.60 |
| 6.5 | Resume project | Project Mgmt | 3 | 4 | 0.75 |
| 6.6 | Workstream namespacing | Project Mgmt | 2 | 4 | 0.50 |
| 7.2 | Codebase scan | Brownfield | 3 | 3 | 1.00 |
| 7.3 | Codebase intelligence store | Brownfield | 3 | 5 | 0.60 |
| 7.4 | Forensics | Brownfield | 2 | 4 | 0.50 |
| 8.1 | UI design contract | UI/UX | 4 | 5 | 0.80 |
| 8.2 | UI review | UI/UX | 3 | 4 | 0.75 |
| 8.3 | Sketch command | UI/UX | 2 | 3 | 0.67 |
| 9.2 | CLI transport interface | SDK/CLI | 2 | 5 | 0.40 |
| 9.3 | Dispatch error taxonomy | SDK/CLI | 2 | 3 | 0.67 |
| 10.1 | Profile-based installer | Installer | 3 | 5 | 0.60 |
| 10.3 | Installer migrations | Installer | 2 | 4 | 0.50 |
| 10.4 | Update system | Installer | 2 | 3 | 0.67 |
| 11.1 | Pre-commit hooks (5 types) | Hooks | 4 | 4 | 1.00 |
| 11.2 | Session hooks (8 types) | Hooks | 3 | 5 | 0.60 |
| 12.1 | Documentation generation | Docs | 3 | 4 | 0.75 |
| 12.2 | Doc ingestion | Docs | 2 | 4 | 0.50 |
| 12.3 | Knowledge graph | Docs | 2 | 5 | 0.40 |
| 12.5 | Internationalized documentation | Docs | 2 | 6 | 0.33 |
| 13.2 | Package legitimacy gate | Security | 3 | 4 | 0.75 |
| 13.3 | Secret scanning | Security | 4 | 4 | 1.00 |
| 14.1 | Comprehensive test suite | Testing | 3 | 7 | 0.43 |
| 14.2 | CI/CD pipeline | Testing | 2 | 7 | 0.29 |
| 14.3 | Changeset workflow | Testing | 2 | 5 | 0.40 |
| 15.4 | Ultraplan phase | Advanced Exec | 3 | 5 | 0.60 |
| 15.5 | MVP mode | Advanced Exec | 3 | 4 | 0.75 |
| 16.1 | Developer profiling | Community | 3 | 4 | 0.75 |
| 16.2 | Stats dashboard | Community | 2 | 4 | 0.50 |
| 16.3 | Manager dashboard | Community | 2 | 5 | 0.40 |
| 17.2 | Model profiles (3 tiers) | Configuration | 3 | 4 | 0.75 |
| 17.3 | Skill surface control | Configuration | 2 | 4 | 0.50 |

---

## 3. Category-Level Analysis

### 3.1 Context Engineering (5 gaps)

**Current state:** Big Powers uses `specs/` for artifacts and `terse-mode` for token economy. No context window monitoring or budgeting.

**Assessment:** This is the highest-leverage category. Context rot and context overflow are primary failure modes in long-running agent sessions. GSD's approach of monitoring context utilization and automatically thinning prompts is directly applicable.

**Recommendation:** Implement context window monitoring as an extension to `orchestrate`. Add a `specs/CONTEXT.md` per phase for implementation decisions. Create a `specs/LEARNINGS.md` for cross-phase knowledge accumulation.

### 3.2 Quality Assurance (7 gaps)

**Current state:** Big Powers has strong QA via `audit-code`, `enforce-first`, `request-review`, and `validate-fix`. However, it lacks automated node repair, verification debt tracking, and health validation.

**Assessment:** The node repair operator is the most impactful gap here. Currently, when a task's verify command fails during `execute-plan`, the user must manually intervene. Auto-retry with diagnosis would significantly reduce friction.

**Recommendation:** Extend `execute-plan` with a node repair operator that auto-diagnoses common failure modes (missing dependency, syntax error, test failure) and attempts fixes before escalating.

### 3.3 Phase Management (6 gaps)

**Current state:** Big Powers' `orchestrate` coordinates phases well, but lacks dynamic phase modification, quick mode, pause/resume, and auto-advance.

**Assessment:** Quick mode and auto-advance are the most practical additions. Not every task needs the full lifecycle, and reducing cognitive load for routine progressions would improve the user experience.

**Recommendation:** Add a `--quick` flag to `orchestrate` that skips research and plan-check gates. Extend `survey-context` with `--next` to auto-advance.

### 3.4 Multi-Agent Orchestration (4 gaps)

**Current state:** Big Powers has `delegate-task` and `dispatch-agents` for spawning subagents, but no predefined agent roles, no fresh context guarantee, and no thin orchestrator pattern formalization.

**Assessment:** This is the largest architectural gap. GSD's 33 agent roles with focused tool sets and model assignments represent a mature multi-agent system. However, adopting all 33 roles is overkill for Big Powers' solo-developer focus.

**Recommendation:** Start with 5 core agent roles: `code-reviewer`, `security-auditor`, `doc-writer`, `bug-investigator`, and `researcher`. Define each with a focused tool set and recommended model. Formalize the thin orchestrator pattern in `orchestrate`.

### 3.5 Execution Models (5 gaps)

**Current state:** `execute-plan` runs sequentially; `dispatch-agents` runs in parallel but lacks wave analysis. No autonomous mode, no cross-AI delegation, no failure-tier escalation.

**Assessment:** Wave-based parallelism is the most impactful addition. Grouping independent tasks and running them in parallel would significantly speed up execution for phases with many independent stories.

**Recommendation:** Add dependency analysis to `execute-plan` that groups independent tasks into waves. Each wave runs in parallel; waves run sequentially.

### 3.6 Security & Hardening (4 gaps)

**Current state:** `guard-git` blocks destructive operations. No secret scanning, package legitimacy checking, or prompt injection detection.

**Assessment:** Secret scanning and read-before-edit guard are the most practical security additions. Secret scanning prevents accidental credential commits; read-before-edit prevents accidental code corruption.

**Recommendation:** Add a pre-commit secret scan (base64 detection, common patterns). Add a read-before-edit check to `guard-git`.

### 3.7 Remaining Categories (10 categories, 33 gaps)

The remaining categories (Project Management, Brownfield, UI/UX, SDK/CLI, Installer, Hooks, Documentation, Testing, Developer Profiling, Configuration) contain gaps that are generally lower priority for Big Powers' core solo-developer use case. They become relevant if Big Powers expands to team/multi-project scenarios or aims for broader runtime support.

---

## 4. Recommended Integration Roadmap

### Phase 1 — Foundation (Weeks 1-4)

**Goal:** Add context engineering and quality quick wins.

1. Extend `orchestrate` with context window monitoring and auto-thinning
2. Add `specs/CONTEXT.md` per phase for implementation decisions
3. Extend `execute-plan` with node repair operator (auto-retry on verify failure)
4. Add verification debt tracking to `specs/state.yaml`
5. Add health validation command for `specs/` artifact consistency
6. Add configurable granularity to `plan-release`

**Expected outcome:** 15-20% reduction in failed sessions due to context overflow; 30% reduction in manual intervention during execution.

### Phase 2 — Acceleration (Weeks 5-8)

**Goal:** Add execution speed improvements and phase management.

1. Add `--quick` flag to `orchestrate` for lightweight tasks
2. Extend `survey-context` with `--next` auto-advance
3. Add wave-based parallelism to `execute-plan`
4. Add dynamic phase modification to `plan-release`
5. Formalize pause/resume in `orchestrate`

**Expected outcome:** 40% faster execution for phases with independent tasks; better UX for small tasks.

### Phase 3 — Multi-Agent (Weeks 9-14)

**Goal:** Introduce specialized agent roles and orchestration patterns.

1. Define 5 core agent roles (code-reviewer, security-auditor, doc-writer, bug-investigator, researcher)
2. Formalize thin orchestrator pattern in `orchestrate`
3. Add fresh context guarantee to `delegate-task`
4. Extend `request-review` with plan review convergence loop
5. Add per-phase model selection to `orchestrate`

**Expected outcome:** Higher-quality multi-agent workflows; better plan quality through convergence.

### Phase 4 — Hardening (Weeks 15-18)

**Goal:** Add security and production-readiness features.

1. Add secret scanning (base64 + common patterns) to pre-commit hooks
2. Add read-before-edit guard to `guard-git`
3. Add security audit skill with dependency scanning
4. Add milestone lifecycle commands to `release-branch`
5. Add a centralized template library

**Expected outcome:** Reduced security risk; better milestone tracking.

### Phase 5 — Strategic (Weeks 19+)

**Goal:** Long-term strategic capabilities.

1. Cross-AI execution delegation protocol
2. Failure-tier model escalation
3. Multi-runtime support expansion
4. SDK design for programmatic integration
5. Developer profiling and stats dashboard

**Expected outcome:** Broader runtime support; automatic model optimization; programmatic integration.

---

## 5. Risk Assessment

### 5.1 Integration Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Skill bloat — adding too many skills dilutes the "one skill, one thing" principle | High | Medium | Consolidate related features into umbrella skills; keep the total count under 60 |
| Token overhead — context monitoring and multi-agent features increase token usage | Medium | High | Use profile-based skill loading; disable monitoring for small projects |
| Complexity creep — wave-based execution and cross-AI delegation add significant complexity | Medium | Medium | Implement incrementally; start with sequential execution, add waves as an opt-in |
| Maintenance burden — 74 gaps is a large backlog; trying to close all at once will stall | High | High | Follow the phased roadmap; close 10-15 gaps per quarter |
| User confusion — too many modes and flags overwhelm solo developers | Medium | Medium | Sensible defaults; advanced features behind `--advanced` flags |

### 5.2 What NOT to Integrate

Some GSD features are not a good fit for Big Powers:

- **88 workflow files:** Big Powers' skill-per-feature model is more maintainable than GSD's workflow library approach.
- **15-runtime support:** Big Powers targets Gemini Extension and Claude Code. Expanding to 15 runtimes is not aligned with its focus.
- **Full SDK:** A TypeScript SDK makes sense for GSD's programmatic use case but is overkill for Big Powers' skill-based model.
- **569+ test files:** Big Powers is a skill system, not a CLI tool. It doesn't need its own test suite at that scale.
- **Manager dashboard:** Big Powers is designed for solo developers. Multi-project management is out of scope.

---

## 6. Conclusion

Big Powers v1.14.0 is a well-architected skill system for spec-driven, test-first development by solo developers. GSD v1.50.0-canary.0 is a broader system with more advanced multi-agent orchestration, context engineering, and execution models.

The 74 identified gaps represent a significant opportunity to enhance Big Powers without compromising its core philosophy. The recommended approach is:

1. **Start with context engineering and quality quick wins** (Tier 1) — these provide immediate value with minimal risk.
2. **Add execution speed improvements** (Tier 2) — wave-based parallelism and quick mode significantly improve the user experience.
3. **Incrementally introduce multi-agent patterns** (Tier 3) — start with 5 core agent roles and expand based on user feedback.
4. **Defer strategic investments** (Tier 3-4) — cross-AI delegation, multi-runtime support, and SDK design are long-term goals that should not block near-term improvements.

The phased roadmap above provides a concrete 18-week plan for the first four phases, with a fifth phase for strategic capabilities. Each phase builds on the previous one, minimizing risk while delivering incremental value.

---

## Appendix A: Full Gap List

See `gaps.md` in the analysis workspace for the complete list of 74 gaps with detailed descriptions, GSD feature references, Big Powers current state, and rationale for each gap.

## Appendix B: Feature Lists

- `features_gsd.md` — Comprehensive GSD feature list (783 lines, 19 categories)
- `features_bigpowers.md` — Comprehensive Big Powers feature list (171 lines, 5 sections)

## Appendix C: Methodology

1. Cloned GSD v1.50.0-canary.0 and Big Powers v1.14.0
2. Extracted feature lists from both codebases
3. Compared features category by category
4. Identified 74 gaps where GSD has a feature Big Powers lacks
5. Prioritized gaps using impact/effort scoring
6. Grouped gaps into a phased integration roadmap
