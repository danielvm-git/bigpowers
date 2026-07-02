# Deepen Architecture: bigpowers Full Review Report

> Generated: 2026-07-02
> Method: deepen-architecture skill (meta-project adaptation)
> Scope: 72 skills, 31 scripts, 27 reference docs, sync pipeline, YAML cockpit, Gherkin compliance features, generated artifacts (.cursor, .gemini, .pi)
> Cross-referenced against: BMAD Method (bmad-code-org/BMAD-METHOD), Superpowers (obra/superpowers), GSD Core (open-gsd/gsd-core)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Methodology and Vocabulary](#2-methodology-and-vocabulary)
3. [The Philosophical Stack](#3-the-philosophical-stack)
4. [Cross-Project Comparison](#4-cross-project-comparison)
5. [Deepening Opportunities](#5-deepening-opportunities)
   - 5.1 [Sync Pipeline: Copy-Paste-Variant, Not Parse→IR→Render](#51-sync-pipeline-copy-paste-variant-not-parseirrender)
   - 5.2 [Path Resolution Boilerplate Duplicated Across 13 Scripts](#52-path-resolution-boilerplate-duplicated-across-13-scripts)
   - 5.3 [50+ Skills Have Tautological Verify Commands](#53-50-skills-have-tautological-verify-commands)
   - 5.4 [Near-Cousin Skill Clusters](#54-near-cousin-skill-clusters)
   - 5.5 [Hub-and-Spoke Documentation Duplication](#55-hub-and-spoke-documentation-duplication)
   - 5.6 [No Context-Rot Mitigation in the Skill System](#56-no-context-rot-mitigation-in-the-skill-system)
   - 5.7 [Flat Script Directory with Inconsistent Naming](#57-flat-script-directory-with-inconsistent-naming)
   - 5.8 [Orphan Cursor Rule (context7.mdc)](#58-orphan-cursor-rule-context7mdc)
6. [Concrete Bugs Found](#6-concrete-bugs-found)
7. [Shallow Scripts Identified](#7-shallow-scripts-identified)
8. [Duplication Patterns Quantified](#8-duplication-patterns-quantified)
9. [Broken References Found](#9-broken-references-found)
10. [Stale Files](#10-stale-files)
11. [Gap Analysis vs GSD/BMAD/Superpowers](#11-gap-analysis-vs-gsdbmadsuperpowers)
12. [Priority Ranking](#12-priority-ranking)

---

## 1. Executive Summary

bigpowers is a 72-skill, documentation-as-code methodology that synthesizes classical software engineering literature (Uncle Bob, Ousterhout, Toyota Way, Lean Software, PMBOK) with AI-native articles (Akita, Wasowski, Karpathy) and prior skill frameworks (Superpowers, Matt Pocock's skills, BCP Agent) into a prescriptive 6-phase lifecycle with hard gates, a 94% quality threshold, and a YAML cockpit.

The architecture is fundamentally sound — the YAML cockpit (specs/state.yaml), the next_skill handoff chain, the BCP velocity tracking, and the Gherkin compliance features are genuine innovations that none of the three comparison projects have. The philosophical layer cake is well-documented and the skill taxonomy is comprehensive.

However, the review surfaced **8 deepening opportunities**, **4 concrete bugs**, **3 shallow scripts**, **6 duplicated boilerplate patterns**, **4 broken references**, and **1 stale file**. The highest-impact findings are:

1. The sync pipeline is copy-paste-variant code, not a parse→IR→render pipeline — adding a new IDE target requires modifying the loop body, not adding a renderer
2. The SKILL-INDEX.md phase table silently drops 3 skills because `get_phase()` is a hardcoded case statement that wasn't updated
3. 50+ skills have tautological verify commands that test file existence instead of behavior
4. The same principles (F.I.R.S.T, Boy Scout Rule) are restated in 4-6 places with slight drift
5. bigpowers lacks GSD Core's central insight: context-budget signaling via `effort:` frontmatter and lifecycle hooks

---

## 2. Methodology and Vocabulary

This review uses the deepen-architecture skill's vocabulary, adapted for a documentation-as-code project via the meta-project-adaptation reference:

| Term | Traditional code | bigpowers mapping |
|------|-----------------|-------------------|
| **Module** | Class, function, package | A SKILL.md file, a script (.sh/.py/.js), a document, or a generated artifact target |
| **Interface** | Type signature, public methods | The YAML frontmatter (name, description, model) — what an agent sees to decide whether to load. For scripts: the CLI flags and positional args |
| **Implementation** | Function body | The SKILL.md body (process, instructions, verify commands). For scripts: the bash/shell logic |
| **Depth** | Behavior per interface surface | How much guided workflow an agent gets from a concise description and frontmatter. A deep skill has a ~1-line trigger description that unlocks a complete multi-step process |
| **Seam** | Place to alter behavior without editing in place | Where a skill's instructions are consumed (Hermes skill system, Gemini commands, Cursor rules, pi prompts). The same SKILL.md lives at multiple output seams |
| **Adapter** | Concrete implementation at a seam | A generated artifact: .cursor/rules/foo.mdc, .gemini/commands/foo.toml, .pi/prompts/foo.md. All are adapters of the same SKILL.md source |
| **Deletion test** | Delete module → complexity reappears at callers | Delete a SKILL.md → agents lose that capability. But delete a generated artifact → unchanged source still produces it on next sync |

Key principles applied:
- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

---

## 3. The Philosophical Stack

bigpowers is a chronological layer cake — each wave of thinking builds on and resolves tensions from the previous one:

| Era | Source | Contribution | Tension Resolved |
|-----|--------|-------------|-----------------|
| 2008 | Uncle Bob (Clean Code) | SRP, Boy Scout Rule, F.I.R.S.T tests, intention-revealing names | — (foundation) |
| 2018 | Ousterhout (A Philosophy of Software Design) | Deep modules, information hiding, define errors out of existence | Small functions alone create shallow modules with bloated interfaces |
| 2023-24 | Karpathy, Superpowers, Pocock | Think-first planning, verb-noun skill architecture, zoom-out strategy | Raw LLMs have no discipline — they need orchestration, not raw prompting |
| 2024 | Wasowski (SDD), BCP | Specs as the human-agent interface; business complexity as a pre-build sizing unit | Agents drift without a verifiable spec — BDD Gherkin closes the loop |
| 2026 | Akita (Clean Code for AI Agents) | Grep-ability, structured JSON logging, token economy, remediation hints in errors | Uncle Bob's rules were written for humans — agents need different code hygiene |
| Synthesis | BMAD + GSD (self-authored) | 6-phase lifecycle, hard gates, 94% quality threshold, specs/state.yaml cockpit | All the above are principles; bigpowers turns them into an executable discipline |

The books in the local library (/Users/danielvm/Developer/hermes-agent/books) cover layers 1-3 (the classical foundation). The web articles and repos cover layers 4-7 (the AI-native adaptation). bigpowers is the synthesis layer.

### Books read

1. **Clean Code** — Robert C. Martin (2008): SRP, Boy Scout Rule, F.I.R.S.T tests, intention-revealing names, small functions (4-20 lines), Stepdown Rule
2. **A Philosophy of Software Design** — John Ousterhout (2018): Deep modules, information hiding, tactical vs strategic programming, "design it twice"
3. **PMBOK 7th Edition**: Project management lifecycle and phase-gate discipline
4. **The Toyota Way** — Jeffrey Liker (2003): 14 management principles, kaizen, genchi genbutsu
5. **Lean Software Development** — Mary & Tom Poppendieck (3 books): 7 wastes translated to software
6. **Agile Retrospectives** — Derby & Larsen (2006): Retrospective methodology
7. **Practices of an Agile Developer** — Subramaniam & Hunt (2006): Pragmatic agile practices
8. **Agile Estimating and Planning** — Mike Cohn (2005): Story-point estimation, velocity tracking

### Articles read

9. **Clean Code for AI Agents** — Fabio Akita (April 2026): Re-ranks Clean Code for AI agents — grep-ability, comments as provenance, token economy, remediation hints
10. **SDD: BDD as the Missing Link** — Jarek Wasowski (April 2026): Specifications as execution contracts, BDD Gherkin as the missing specification language
11. **SDD: Designing a Spec That Survives Code Generation** — Wasowski (May 2026): Five specification types with different lifecycles

### Repos studied

12. **Karpathy-Inspired Claude Code Guidelines** (multica-ai/andrej-karpathy-skills): Four principles — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution
13. **Superpowers** (obra/superpowers): 14 core skills, subagent-driven development, skill enforcement doctrine, multi-harness plugin support
14. **Matt Pocock's Skills** (mattpocock/skills): grill-me, two-axis code review, handoff, writing-great-skills
15. **BCP Agent** (flow-ciandt/bcp-agent): Business Complexity Points — 10 functional elements sized XS-XL on Fibonacci scale

---

## 4. Cross-Project Comparison

All four projects solve the same problem: raw LLMs can write code but lack engineering discipline. They take different structural approaches.

### BMAD Method (bmad-code-org/BMAD-METHOD) — 50k stars, v6

A role-based, persona-driven agile methodology. Instead of skills that fire on triggers, BMAD assigns named AI agents with distinct personalities: Mary (Business Analyst), John (PM), Sally (UX Designer), Winston (Architect), Amelia (Senior Dev). 4 phases: analysis → plan-workflows → solutioning → implementation.

Key innovation: the architecture spine — a consistency contract that fixes only the invariants keeping independently-built units from diverging. Uses a memlog (.memlog.md) as append-only working memory. Two modes: Coaching path (Socratic elicitation) vs Fast path (draft with [ASSUMPTION] tags).

### Superpowers (obra/superpowers) — 244k stars, v6.1

A skill-based methodology with 14 core skills and aggressive auto-invocation. The using-superpowers bootstrap skill enforces: "If you think there is even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke it."

Key innovation: subagent-driven development — each task gets a fresh implementer subagent, then a separate task-reviewer subagent (spec compliance + code quality), then a final whole-branch reviewer. The orchestrator never touches source files.

### GSD Core (open-gsd/gsd-core) — 64k stars

A context-engineering framework that solves "context rot" — quality degradation as an AI fills its context window. Central insight: most work doesn't need to happen in the main context. Heavy research, planning, and execution run in fresh-context subagents while the orchestrator stays lean.

Key innovations: the .planning/ directory as shared substrate (STATE.md, CONTEXT.md, RESEARCH.md, PLAN.md, VERIFICATION.md), lifecycle hooks for context headroom (PreCompact, Stop, SubagentStop), effort: frontmatter (max/low) for token budget signaling, 5-step phase loop (Discuss → Plan → Execute → Verify → Ship).

### bigpowers (this project) — 72 skills, v2.44.1

A prescriptive, vertical-slice methodology synthesizing all three above plus classical engineering books and AI-native articles. 6-phase lifecycle with hard gates, 94% quality threshold, YAML cockpit.

Key differentiators: BCP velocity tracking (BCP/hr), Gherkin compliance features with 94% threshold, semantic-release automation, explicit philosophical stack documentation, WSJF prioritization, YAML cockpit (structured state vs prose Markdown), next_skill handoff chain, Akita's AI-specific code rules.

### Comparison Matrix

| Dimension | BMAD | Superpowers | GSD Core | bigpowers |
|-----------|------|-------------|----------|-----------|
| Primary unit | Agent personas | Skills (14) | Skills (69) | Skills (72) |
| State format | Markdown folders | Plan files | .planning/ MD+JSON | specs/ YAML |
| Context strategy | Party mode | Subagent per task | Fresh-context subagents | next_skill chain |
| Estimation | Scale-adaptive | None | None | BCP (normalized) |
| Verification | Reviewer gate | Code review | VERIFICATION.md | Gherkin 94% gate |
| Release mgmt | Manual | Manual | Ship step | semantic-release |
| Phase model | 4 phases | 6-step workflow | 5-step loop | 6-phase lifecycle |
| Multi-runtime | Claude/Cursor | 10+ harnesses | 12+ runtimes | Claude/Gemini/Cursor/pi |
| Persona-driven | Yes (named agents) | No | No | No |
| Philosophy docs | Implicit | Implicit | Context-rot thesis | Explicit layer cake |
| Compliance tests | No | No | No | Yes (Gherkin) |
| effort: frontmatter | No | No | Yes | No |
| Lifecycle hooks | No | No | Yes | No |
| Plan-checker | No | Yes (task-reviewer) | Yes (plan-checker) | No |

---

## 5. Deepening Opportunities

### 5.1 Sync Pipeline: Copy-Paste-Variant, Not Parse→IR→Render

**Files**: scripts/sync-skills.sh (272 lines), scripts/regenerate-lockfile.sh (49 lines), scripts/generate-skill-index.sh (171 lines), scripts/build-skill-index.sh (28 lines), scripts/generate-reference-tables.sh (68 lines)

**Problem**: The build pipeline that generates artifacts for 5 targets (Cursor .mdc, Gemini SKILL.md, Gemini .toml, pi SKILL.md, pi prompts) is a single monolithic loop in sync-skills.sh. Each target gets its own inline write block (lines 68-116). The frontmatter parsing logic (awk for name, model, description) is duplicated verbatim in sync-skills.sh, regenerate-lockfile.sh, and build-skill-index.sh — three separate copies of the same awk recipe, all with subtle differences:

- build-skill-index.sh doesn't escape quotes in descriptions
- regenerate-lockfile.sh doesn't extract the model field
- sync-skills.sh has the most complete version with escaping

Adding a new target (e.g. OpenCode, Copilot, a new IDE) means modifying the loop body in sync-skills.sh — adding another inline write block, another echo heredoc, another set of path variables. This is the classic shallow-pipeline shape: adding a target requires modifying the orchestrator, not adding a renderer. The pipeline's interface (the loop body) is nearly as complex as its implementation.

The five index/lockfile scripts (regenerate-lockfile → generate-skill-index → build-skill-index → generate-reference-tables → sync-skills) form a sequential chain called from sync-skills.sh, but they're called as separate bash processes with no shared parsing. Each re-reads every SKILL.md from scratch, re-parses frontmatter, re-computes skill lists. The same 72 SKILL.md files are read and awk-parsed 5 times per sync run.

**Deletion test**: If you delete sync-skills.sh, complexity doesn't vanish — it reappears as 5 separate scripts that each need to know how to parse frontmatter, find skills, and resolve paths. The parsing knowledge is earning its keep, but it's spread across 5 shallow scripts instead of concentrated in one deep module.

**Solution**: Extract a shared bash library (e.g. scripts/lib/skill-common.sh) that provides:
- resolve_repo_root
- resolve_skills_root
- parse_frontmatter (returns name/model/description)
- iterate_skills

Then refactor sync-skills.sh to use a render-target pattern: each target (cursor, gemini-skill, gemini-command, pi-skill, pi-prompt, opencode) is a function that takes (name, model, description, body, output_dir) and writes its artifact. Adding a target = adding a function, not modifying the loop. The lockfile/index scripts source the same library instead of re-implementing frontmatter parsing.

**Benefits**:
- **Locality**: frontmatter parsing logic lives in one place; the BSD sed '+' bug (BUG-2026-06-02T164500) can only happen once
- **Leverage**: adding a 5th or 6th IDE target is a 10-line function, not a 30-line inline block. The interface of the pipeline becomes "register a render function" rather than "edit the loop body"
- **Tests**: you can test parse_frontmatter in isolation, and test each render function with a fixture SKILL.md

---

### 5.2 Path Resolution Boilerplate Duplicated Across 13 Scripts

**Files**: 13 scripts (add-model-frontmatter.sh, bp-yaml-set.sh, bp-yaml-snapshot.sh, build-skill-index.sh, convert-legado.sh, enrich-epics-from-archive.sh, generate-skill-index.sh, install.sh, regenerate-lockfile.sh, sync-bugs-registry.sh, sync-skills.sh, sync-status-from-epics.sh, validate-specs-yaml.sh)

**Problem**: The exact same 3-line pattern appears in 13 scripts:

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_ROOT="$REPO_ROOT"
[[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"
```

This is a shallow module — the interface (3 lines of path resolution) is nearly as complex as the implementation (3 lines of path resolution). It exists because bash has no module system, but the knowledge it encodes (the skills/ subdirectory fallback for the e29s02 migration) is spread across 9 call sites. If the migration completes and the fallback is removed, you have to edit 9 files.

**Solution**: Part of the same scripts/lib/skill-common.sh library from candidate 5.1. A single `source "$(dirname "$0")/lib/skill-common.sh"` replaces 3 lines in 13 scripts.

**Benefits**: Locality — the fallback decision lives in one place. When the migration completes, delete one line, not thirteen.

---

### 5.3 50+ Skills Have Tautological Verify Commands

**Files**: 50 out of 72 skills

**Problem**: 50 skills have verify commands that just check the SKILL.md file exists:

```
→ verify: `test -f <name>/SKILL.md && grep -q '^name:' <name>/SKILL.md && echo "OK" || echo "FAIL"`
```

This is a shallow interface signal. The verify command doesn't test anything about the skill's actual behavior — it tests that the file the agent just loaded exists. It's a tautology: the file exists because it was just read. This is the documentation-as-code equivalent of a pass-through function: the verify command passes through to the filesystem check without adding any behavioral assertion.

The CONVENTIONS.md mandate says "Every story implementation MUST end with a step-by-step manual verification script" and "Every change must be verifiable with a single runnable command before it is marked done." But 50 skills violate the spirit of this rule — their verify commands provide zero behavioral signal. They're cargo-culted from the first skill and never differentiated.

Only ~15 skills have meaningful verify commands:
- diagnose-root: checks for 4 phases (Reproduce|Isolate|Hypothesize|Verify) in BUG-*.md
- scope-work: checks for out_of_scope in SCOPE_LATEST.yaml
- slice-tasks: checks for task files in specs/epics/
- run-planning: checks for 3+ status:done entries in planning-status.yaml
- grill-with-docs: checks for 2+ URLs in the skill body

**Solution**: Two options:
- (A) Remove tautological verify commands entirely — they add noise without signal. The sync-skills.sh pipeline already validates that SKILL.md files exist and have valid frontmatter via validate-skill-yaml.py.
- (B) Replace each with a behavior-relevant verify command that checks the skill's expected output artifact (e.g. for plan-work: check that specs/epics/eNN-*/stories/ has task files; for audit-code: check that a checklist was produced).

**Benefits**:
- **Leverage**: a verify command that actually tests behavior is worth running; one that tests file existence is wasted context
- **Locality**: if the verify command tests the artifact, a failure points you directly to the skill that produced the bad artifact, not to a missing file
- The interface (verify command) becomes a real test surface instead of a tautology

---

### 5.4 Near-Cousin Skill Clusters

**Files**: Multiple skill clusters across 72 skills

**Problem**: Several skill clusters share ~70-80% of their workflow with distinguishing features that are essentially mode flags:

#### Cluster A — Bug fix pipeline (3 skills)

| Skill | Lines | Role |
|-------|-------|------|
| investigate-bug | 124 | Explore codebase → find root cause → write TDD fix plan to BUG-*.md |
| diagnose-root | 24 | 4-phase RCA (reproduce, isolate, hypothesize, verify) — runs AFTER investigate-bug |
| fix-bug | 57 | Orchestrator — reads BUG-*.md, chains investigate-bug → develop-tdd → validate-fix |

Deletion test: fix-bug is already an orchestrator that calls investigate-bug. investigate-bug already delegates to diagnose-root for RCA. diagnose-root is a 24-line skill that is essentially a sub-procedure of investigate-bug. The three form a pipeline but the handoff points create 3 separate skills where 1 orchestrator + 1 sub-procedure would suffice.

#### Cluster B — Delegation (2 skills)

| Skill | Lines | Role |
|-------|-------|------|
| delegate-task | 81 | One subagent, sequential, two-stage review |
| dispatch-agents | 88 | Multiple subagents, parallel, no inter-task review |

Deletion test: The only differences are (1) count: 1 vs N, (2) parallelism: sequential vs concurrent, (3) review gate: two-stage vs none. These are mode flags, not separate skills. A single `delegate` skill with `--mode=sequential|parallel` and `--review=staged|none` would cover both. The descriptions even cross-reference each other ("Distinct from dispatch-agents" / "Distinct from delegate-task").

#### Cluster C — Grilling (2 skills)

| Skill | Lines | Role |
|-------|-------|------|
| grill-me | 34 | Stress-test plan from conversation/context |
| grill-with-docs | 30 | Same but every challenge must cite a real URL |

Deletion test: grill-with-docs is grill-me + a citation constraint. grill-me already has a "Docs mode" section in its body. A `--docs-grounded` flag on grill-me would cover both. The bodies share the same questioning loop.

#### Cluster D — Planning (3 skills)

| Skill | Lines | Role |
|-------|-------|------|
| plan-work | ~100 | Write implementation tasks into epic capsules (planning spine step 3) |
| plan-release | 150 | Sequence epics into release-plan.yaml with WSJF (release-index builder) |
| plan-refactor | ~80 | Refactor plan with tiny commits |

Deletion test: These are genuinely distinct in output (task files vs release index vs refactor RFC). Deleting one would lose capability. NOT a candidate for merging — but a candidate for a shared planning library that each skill sources.

#### Cluster E — Verification (3 skills)

| Skill | Lines | Role |
|-------|-------|------|
| verify-work | 134 | Multi-phase UAT gate (cold-start, build, typecheck, lint, tests, manual verification) |
| validate-fix | 108 | Re-run failing test, full suite, typecheck, lint, harden against recurrence |
| validate-contracts | 115 | Data shape consistency across system boundaries |

Deletion test: validate-fix is a subset of verify-work (verify-work does everything validate-fix does plus cold-start smoke and manual verification). validate-contracts is genuinely distinct (boundary testing vs functional verification). If verify-work had a `--scope=full|fix-only` flag, validate-fix could be a mode. But the descriptions are distinct enough that users may want to call validate-fix directly after a bug fix without running the full UAT gate.

#### Cluster F — Review (3 skills)

| Skill | Lines | Role |
|-------|-------|------|
| audit-code | 131 | Self-review checklist (pre-review) |
| request-review | ~80 | Dispatch fresh reviewer agent (post-audit) |
| respond-review | ~70 | Act on reviewer feedback (post-request) |

These form a clear pipeline (self-review → external review → respond to findings) and are genuinely distinct. NOT a candidate for merging — but the handoff chain could be made more explicit via next_skill signaling.

**Solution**: For clusters A, B, C — consider merging into a single skill with mode flags, keeping the others as thin aliases that set the flags. For clusters D and F — keep separate but extract shared logic.

**Benefits**:
- **Locality**: a bug in the questioning loop only needs to be fixed in one place (grill-me) instead of two
- **Leverage**: users have fewer skills to learn; the mode flag is part of the interface, not a separate skill
- Tests improve: you test the mode flag, not two separate skills that might drift

**Note**: CONVENTIONS.md says "skill directories under skills/ use verb-noun naming" and the README markets "72 skills" as a feature count. Merging reduces the count. The skill count is auto-generated from the catalog, so this is not a hard barrier, but it's a branding consideration.

---

### 5.5 Hub-and-Spoke Documentation Duplication

**Files**: CONVENTIONS.md, docs/PRINCIPLES.md, docs/references/uncle-bob.md, docs/references/akita.md, docs/references/ousterhout.md, docs/references/karpathy.md, docs/references/wasowski.md, docs/references/bcp.md, docs/references/superpowers.md, docs/references/gsd.md, docs/references/bmad.md, skills/enforce-first/SKILL.md, skills/audit-code/SKILL.md, skills/develop-tdd/SKILL.md

**Problem**: The same principles are stated in 3-4 places with slight drift:

**F.I.R.S.T rubric** (6 locations):
- CONVENTIONS.md line 163
- PRINCIPLES.md line 14
- enforce-first/SKILL.md line 11
- audit-code/SKILL.md line 72
- docs/references/uncle-bob.md line 8
- develop-tdd/SKILL.md line 43

**Boy Scout Rule** (5 locations):
- CONVENTIONS.md line 147
- PRINCIPLES.md line 12
- audit-code/SKILL.md lines 53, 55
- docs/references/uncle-bob.md line 6

**Deep modules** (2 locations):
- PRINCIPLES.md line 22
- docs/references/ousterhout.md

Each restating is slightly different — CONVENTIONS.md says "4-20 lines" for functions, PRINCIPLES.md says "small functions," audit-code says "small enough to fit in a standard context window." The 27 reference docs in docs/references/ (2,959 lines total) largely restate what's already in CONVENTIONS.md and PRINCIPLES.md, formatted differently.

**Deletion test**: If you delete docs/references/uncle-bob.md, does complexity vanish? Mostly yes — the principles are already in CONVENTIONS.md and PRINCIPLES.md. The reference doc adds provenance (the book citation) but not new behavioral rules.

**Solution**: Replace the reference docs with section references. Instead of docs/references/uncle-bob.md restating SRP and Boy Scout, it becomes a provenance pointer: "See CONVENTIONS.md §Code Style (SRP, G34, Boy Scout Rule) and §Tests (F.I.R.S.T). Source: Clean Code, Robert C. Martin, 2008." The canonical rules live in CONVENTIONS.md only. The reference docs become thin provenance adapters, not parallel restatements.

**Benefits**:
- **Locality**: when you update the F.I.R.S.T rubric, you edit one file (CONVENTIONS.md), not six
- **Leverage**: agents reading CONVENTIONS.md get the authoritative version, not one of several slightly-different restatements
- Drift risk eliminated

---

### 5.6 No Context-Rot Mitigation in the Skill System

**Files**: All 72 skills, CONVENTIONS.md, CLAUDE.md

**Problem**: GSD Core's central insight — the thing that justifies its existence — is that context rot is the primary failure mode of AI-assisted development, and the structural solution is fresh-context subagents with file-based state. bigpowers acknowledges context rot in session-state/SKILL.md and PRINCIPLES.md, but doesn't encode the mitigation as a first-class skill-level concern:

- No `effort:` frontmatter (GSD declares `effort: max` for heavy orchestrators, `effort: low` for quick-status skills)
- No context-budget signaling (GSD's lifecycle hooks warn before context exhaustion)
- The CLAUDE.md "Token Management" section mentions terse-mode at 20 turns but doesn't make it automatic
- No concept of "spawning orchestrator" vs "leaf skill" — delegate-task and dispatch-agents exist but the distinction between skills that should spawn subagents (and stay lean) vs skills that should do work directly is not encoded in frontmatter

This is not a bug — it's a missing deepening. The skill system has 72 skills all loaded the same way, with no metadata distinguishing the heavy orchestrators (build-epic, execute-plan, orchestrate-project) from the lightweight utilities (terse-mode, session-state, search-skills). An agent loading build-epic gets the same context budget as one loading terse-mode.

**Solution**: Add optional `effort: heavy|light` frontmatter to skills. Heavy skills (orchestrators that spawn subagents) get `effort: heavy`. Light skills (quick lookups, state reads) get `effort: light`. This is metadata, not a behavior change — but it gives the agent (and future tooling) a signal about context budget. Pair this with a CLAUDE.md rule: "When context feels heavy (latency increasing), switch to terse-mode and delegate heavy skills to fresh subagents."

**Benefits**:
- **Leverage**: agents can make informed decisions about when to delegate vs when to work inline
- **Locality**: the effort classification lives in the skill's frontmatter, not in the agent's memory
- This directly addresses GSD's core insight without adopting GSD's heavyweight .planning/ directory

---

### 5.7 Flat Script Directory with Inconsistent Naming

**Files**: scripts/ (31 scripts)

**Problem**: All 31 scripts live in one flat directory. Naming is inconsistent:

- `bp-*` prefix: bp-yaml-set.sh, bp-yaml-snapshot.sh, bp-timing.sh, bp-read-agents.sh, bp-opensrc-check.sh
- Descriptive names: sync-skills.sh, generate-skill-index.sh, validate-specs-yaml.sh
- Install/land: install.sh, land-branch.sh
- Utility: mcp-server.js, yaml-tools.py, validate-skill-yaml.py

The `bp-` prefix was presumably an early convention that was abandoned. New scripts don't use it. An agent grepping for "yaml" tools has to check both bp-yaml-set.sh, bp-yaml-snapshot.sh, yaml-tools.py, and validate-skill-yaml.py to find the right one.

**Deletion test**: The flat directory itself is the shallow module — its interface (`ls scripts/`) is nearly as complex as its implementation (31 files with no structure).

**Solution**: Group by concern:
- `scripts/build/` — sync-skills.sh, generate-skill-index.sh, build-skill-index.sh, regenerate-lockfile.sh, generate-reference-tables.sh
- `scripts/validate/` — validate-specs-yaml.sh, validate-doctrine.sh, validate-skill-yaml.py, check-skill-size.sh, audit-compliance.sh, audit-catalog.sh, run-skill-verify.sh
- `scripts/yaml/` — bp-yaml-set.sh, bp-yaml-snapshot.sh, yaml-tools.py
- `scripts/install/` — install.sh, install-cursor-skills.sh, install-cursor-skills-local.sh
- `scripts/git/` — land-branch.sh, cleanup-worktrees.sh
- `scripts/` (root) — mcp-server.js (the only non-bash tool)

**Benefits**: Locality — an agent looking for build tools goes to scripts/build/. Leverage — the directory structure itself is a navigation interface, reducing grep noise. The `bp-` prefix can be dropped during the move.

**Note**: This changes path references in CLAUDE.md, CONVENTIONS.md, and sync-skills.sh's sub-script calls. Medium effort, low risk.

---

### 5.8 Orphan Cursor Rule (context7.mdc)

**Files**: .cursor/rules/context7.mdc, scripts/sync-skills.sh (lines 198-207, the CURSOR_KEEP allowlist)

**Problem**: context7.mdc is a hand-maintained Cursor rule with no SKILL.md source. It's handled by a special allowlist in sync-skills.sh (`CURSOR_KEEP="context7.mdc"`). This is a shallow adapter — it exists at one seam (Cursor) but not at the others (Gemini, pi). If Context7 MCP is useful, it should be a proper skill with a SKILL.md that generates artifacts for all targets. If it's Cursor-specific, the allowlist is the right approach but it's an undocumented exception.

The orphan-pruning logic itself (lines 196-207) is a post-hoc fix for a structural problem: the pipeline generates artifacts by iterating SKILL.md sources, but doesn't track what it generated, so it can't distinguish "orphan" from "hand-maintained." The allowlist is the workaround.

**Solution**: Either (A) create a skills/context7/SKILL.md and remove the allowlist, or (B) document the allowlist pattern in CONVENTIONS.md so future hand-maintained rules have a known mechanism. Option A is deeper — it makes context7 a first-class skill that generates artifacts for all targets.

**Benefits**: Locality — the allowlist mechanism and its maintenance burden vanish (option A). The pipeline becomes uniform: every artifact has a source SKILL.md.

---

## 6. Concrete Bugs Found

### Bug 1: SKILL-INDEX.md Phase Table Missing 3 Skills

**Severity**: Medium (index inaccuracy, no runtime impact)

- 72 skill directories exist
- skills-lock.json has 72 entries
- SKILL-INDEX.md header correctly says "Skills: 72" (reads from lockfile)
- BUT the phase table TOTAL says 69

The cause: `get_phase()` in `scripts/generate-skill-index.sh` (a case statement mapping skill names to phases) is missing 3 skills:

1. `extract-design` — not in any phase case, not mentioned anywhere in SKILL-INDEX.md
2. `security-review` — not in any phase case, not mentioned anywhere in SKILL-INDEX.md
3. `visual-dashboard` — not in any phase case, appears only in "Transversal utilities" prose and the naming-exceptions note

The `get_phase()` function is a shallow module — it's a hardcoded case statement that must be manually updated when a skill is added. If a new skill is created and the developer forgets to add it to `get_phase()`, it silently drops out of the index.

**Fix**: Add `extract-design`, `security-review`, and `visual-dashboard` to the appropriate phase cases in `get_phase()`. extract-design and security-review belong in "Verify" or "Build". visual-dashboard belongs in "Sustain" (it's listed as a transversal utility).

### Bug 2: Broken References to specs/tech-architecture/ Files

**Severity**: Low (skills reference files that don't exist, but this is a documentation gap not a runtime error)

4 broken references:
- `orchestrate-project` references `specs/tech-architecture/test.md` (does not exist)
- `seed-conventions` references `specs/tech-architecture/design.md` (does not exist)
- `seed-conventions` references `specs/tech-architecture/security.md` (does not exist)
- `seed-conventions` references `specs/tech-architecture/test.md` (does not exist)

These skills claim knowledge their implementation doesn't have — the skill interface promises a file that doesn't exist on disk.

**Fix**: Either create the referenced files or update the skill bodies to reference the correct paths (likely `specs/tech-architecture/TECH_STACK_LATEST.md` or `docs/references/` equivalents).

### Bug 3: Count Mismatch Between Badge and Phase Table

**Severity**: Low (cosmetic)

The README badge says "72 skills" (stamped by sync-skills.sh from the live count). The SKILL-INDEX.md header says "Skills: 72" (from lockfile). But the phase table TOTAL says "69" (from get_phase() counting). This is the same root cause as Bug 1.

### Bug 4: Stale .bak File in Features Directory

**Severity**: Low (potential parse issue)

`specs/verifications/features/karpathy.feature.bak` — a backup file left in the features directory. The compliance harness (audit-compliance.sh) iterates .feature files in a directory. If it picks up .bak files, it may produce false results.

**Fix**: Delete the .bak file or move it to specs/archive/.

---

## 7. Shallow Scripts Identified

From reading all 31 scripts, these are shallow (interface nearly as complex as implementation):

### bp-yaml-set.sh (9 lines)

A 3-line wrapper that calls `python3 scripts/yaml-tools.py set "$FILE" "$KEY" "$VAL"`. The interface (3 args: file, key, value) is the entire implementation.

Deletion test: if deleted, callers just call `python3 scripts/yaml-tools.py set` directly. It's a pass-through.

### install-cursor-skills-local.sh (13 lines)

Sets two env vars (TARGET_DIR, SOURCE_DIR) and execs `install-cursor-skills.sh`. Pure pass-through.

Deletion test: if deleted, callers set the env vars and call install-cursor-skills.sh directly.

### validate-specs-yaml.sh (41 lines)

Calls `need()` 5 times, each checking a grep pattern against a YAML file. The interface (5 expected patterns) is the implementation. Not shallow per se, but the patterns are hardcoded and fragile — if the YAML schema changes, this script breaks silently.

---

## 8. Duplication Patterns Quantified

| Pattern | Scripts affected | Lines duplicated | Total duplicated lines |
|---------|-----------------|-----------------|----------------------|
| REPO_ROOT boilerplate | 13 scripts | 1 line each | 13 lines |
| SKILLS_ROOT fallback | 9 scripts | 3 lines each | 27 lines |
| AWK name extraction | 2 scripts | 1 line each (different variants) | 2 lines |
| AWK description extraction | 3 scripts | 1 line each (3 different variants) | 3 lines |
| Skill iteration loop | 4 scripts | 1 line each (same shape) | 4 lines |
| **Total** | **13 scripts** | | **~49 lines** |

Not enormous, but each duplication is a potential drift point. The 3 different AWK description extraction variants are particularly fragile — they produce slightly different results (escaping, whitespace handling) and have already caused one bug (BUG-2026-06-02T164500, the BSD sed '+' issue).

---

## 9. Broken References Found

4 broken references to `specs/tech-architecture/` files that don't exist:

| Skill | Referenced file | Status |
|-------|----------------|--------|
| orchestrate-project | specs/tech-architecture/test.md | MISSING |
| seed-conventions | specs/tech-architecture/design.md | MISSING |
| seed-conventions | specs/tech-architecture/security.md | MISSING |
| seed-conventions | specs/tech-architecture/test.md | MISSING |

These skills claim knowledge their implementation doesn't have — the skill interface promises a file that doesn't exist on disk. An agent following the skill's instructions will try to read a file that isn't there.

---

## 10. Stale Files

| File | Issue |
|------|-------|
| specs/verifications/features/karpathy.feature.bak | Backup file left in features directory; may be parsed by audit-compliance.sh |

---

## 11. Gap Analysis vs GSD/BMAD/Superpowers

Features that the comparison projects have and bigpowers lacks:

| Feature | GSD | BMAD | Superpowers | bigpowers | Impact |
|---------|-----|------|-------------|-----------|--------|
| `effort:` frontmatter | Yes | No | No | No | High — enables context-budget-aware skill loading |
| Lifecycle hooks (PreCompact etc) | Yes | No | No | No | Medium — warns before context exhaustion |
| Dedicated plan-checker agent | Yes | No | Yes (task-reviewer) | No | Medium — catches plan ambiguity before execution |
| Fresh-context subagent enforcement | Yes (structural) | No | Yes (using-superpowers bootstrap) | Partial (mentioned in 3 skills, not enforced) | High — prevents context rot |
| Multi-runtime support | 12+ | 2 | 10+ | 4 + partial OpenCode | Medium — limits reach |
| Persona-driven agents | No | Yes (12+) | No | No | Low — design choice, not a gap |
| Context-budget signaling | Yes | No | No | No (terse-mode at 20 turns, manual) | High — directly addresses context rot |
| Party mode (multi-agent session) | No | Yes | No | No | Low — niche feature |
| Web bundles (Gemini/ChatGPT) | No | Yes | No | No | Low — cost optimization for planning |

Features that bigpowers has and none of the others have:

| Feature | bigpowers only | Impact |
|---------|---------------|--------|
| BCP velocity tracking (BCP/hr) | Yes | High — normalized estimation enables cross-project comparison |
| Gherkin compliance features (94% gate) | Yes | High — executable verification of own principles |
| semantic-release automation | Yes | Medium — eliminates manual version tracking |
| Explicit philosophical stack documentation | Yes | Medium — onboarding and traceability |
| WSJF prioritization | Yes | Medium — data-driven epic ordering |
| YAML cockpit (structured state) | Yes | High — machine-greppable, schema-validatable |
| next_skill handoff chain | Yes | High — explicit session resumption |
| Akita's AI-specific code rules | Yes | Medium — grep-ability, comments as provenance |

---

## 12. Priority Ranking

Ordered by impact-to-effort ratio:

### Tier 1 — High Impact, Low-Medium Effort (Quick Wins)

1. **Fix Bug 1: Add 3 missing skills to get_phase()** — 3-line fix, eliminates index inaccuracy
2. **Fix Bug 2: Resolve 4 broken tech-architecture references** — 4-line fix per skill
3. **Fix Bug 4: Delete stale .bak file** — 1 command
4. **Candidate 5.3: Remove or replace 50+ tautological verify commands** — improves signal-to-noise, medium effort but mechanical

### Tier 2 — High Impact, Medium Effort (Structural Improvements)

5. **Candidate 5.1: Refactor sync pipeline to parse→IR→render** — highest structural impact, eliminates 3 copies of frontmatter parsing, makes adding IDE targets trivial
6. **Candidate 5.2: Extract scripts/lib/skill-common.sh** — eliminates 49 lines of duplication across 13 scripts, pairs naturally with 5.1
7. **Candidate 5.6: Add effort: frontmatter** — borrows GSD's best idea, low effort, high leverage for context management
8. **Candidate 5.5: Deduplicate hub-and-spoke documentation** — eliminates drift, touches many files but each change is simple

### Tier 3 — Medium Impact, Higher Effort (Larger Refactors)

9. **Candidate 5.4: Merge near-cousin skill clusters** — controversial (reduces skill count), but eliminates drift between paired skills
10. **Candidate 5.7: Reorganize flat script directory** — medium effort, changes path references everywhere
11. **Candidate 5.8: Promote context7 to a real skill or document the allowlist** — small but completes the pipeline uniformity

### Not Recommended (Keep As-Is)

- Cluster D (plan-work / plan-release / plan-refactor) — genuinely distinct outputs, keep separate
- Cluster F (audit-code / request-review / respond-review) — clear pipeline, keep separate

---

## Appendix: What bigpowers Does Better Than the Competition

This review focused on improvement opportunities, but it's worth documenting what bigpowers does that none of the three comparison projects do:

1. **BCP velocity tracking** — the only framework with a normalized estimation unit (BCP from CI&T) and velocity metric (BCP/hr). Story points are subjective and non-comparable; BCP is objective and cross-project.

2. **Gherkin compliance features** — the only framework with executable verification of its own principles. specs/verifications/features/ contains .feature files (cleancode.feature, akita.feature, conventions.feature, superpowers.feature, pocock.feature, karpathy.feature) that empirically prove compliance. npm run compliance audits all features. Score < 94% = hard stop.

3. **semantic-release integration** — the only framework with automated semver via Conventional Commits. The real version is never hand-tracked — gh release view / git tags are authoritative.

4. **next_skill signaling** — each critical-path skill writes handoff.next_skill to state.yaml as its last action. After any interruption, survey-context reads state.yaml and resumes exactly where you left off. Neither Superpowers, GSD, nor BMAD have this explicit handoff chain.

5. **Explicit philosophical layer cake** — the only framework that documents its intellectual lineage as a chronological stack where each layer resolves a tension from the previous one.

6. **YAML cockpit** — structured YAML as the single source of truth (state.yaml, release-plan.yaml, execution-status.yaml, cycle-times.yaml), machine-greppable and schema-validatable, vs GSD's prose Markdown or BMAD's artifact folders.

7. **Akita's AI-specific code rules** — the only framework that encodes Akita's re-ranking of Clean Code for AI agents: grep-ability (< 5 results), comments as provenance (not code smell), remediation hints in exception messages, structured JSON logging.

---

*End of report*
