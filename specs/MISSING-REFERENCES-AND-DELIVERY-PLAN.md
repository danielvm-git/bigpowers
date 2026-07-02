# Missing References, New Enhancements & Delivery Plan

> Generated: 2026-07-02
> Companion to: specs/DEEPEN-ARCHITECTURE-REVIEW.md
> Question: What major references from computer engineering history are missing? What recent articles could add value? How should this be sliced for solo developers?

---

## Table of Contents

1. [Missing Historical References](#1-missing-historical-references)
2. [Recent Articles Worth Adding](#2-recent-articles-worth-adding)
3. [Target End State — What the Delivery Plan Gets You To](#3-target-end-state--what-the-delivery-plan-gets-you-to)
4. [Delivery Plan — Sliced for Solo Developers](#4-delivery-plan--sliced-for-solo-developers)

---

## 1. Missing Historical References

These are foundational software engineering works that have shaped the field but are not referenced anywhere in bigpowers — not in PRINCIPLES.md, not in CONVENTIONS.md, not in docs/references/, not in any SKILL.md body.

### 1.1 Kent Beck — Extreme Programming & "Tidy First?" (1999-2024)

**Status**: ABSENT from bigpowers. Not mentioned anywhere.

**What it contributes**: Beck invented TDD (the RED-GREEN-REFACTOR cycle that develop-tdd implements), Extreme Programming (the planning practices that the planning spine implements), and the "Make it work, make it right, make it fast" ordering principle. His 2024 book "Tidy First?" is directly relevant: it argues for tiny structural refactorings before behavior changes — exactly what plan-refactor and the Boy Scout Rule encode, but with a more precise vocabulary (tidying vs refactoring vs behavior change as distinct commits).

**Why it matters for bigpowers**: bigpowers uses Beck's inventions (TDD, vertical slices, small commits) without crediting them. "Tidy First?" adds the distinction between:
- Tidying (structural change, no behavior change, safe to abort)
- Refactoring (structural change, no behavior change, larger scope)
- Behavior change (functional change)

This maps directly to commit-message types (refactor vs feat) and to the plan-refactor skill. The ordering matters: tidy before behavior change makes the diff reviewable.

**Where to add**: docs/references/kent-beck.md. Update PRINCIPLES.md layer 1 to credit Beck alongside Uncle Bob. Add "tidy before behavior change" to CONVENTIONS.md §Code Style.

### 1.2 Martin Fowler — Refactoring Catalog (1999, 2nd ed 2018)

**Status**: Mentioned once in plan-refactor/SKILL.md ("Remember Martin Fowler's advice"). No reference doc.

**What it contributes**: The canonical catalog of code smells and named refactorings (Extract Method, Inline Class, Replace Conditional with Polymorphism, etc.). The code-smell taxonomy is the diagnostic vocabulary that audit-code and plan-refactor need but currently improvise. Fowler's "smells → refactorings" mapping is the missing link between "audit found problems" and "plan the fix."

**Why it matters for bigpowers**: audit-code checks for CONVENTIONS.md compliance but has no vocabulary for naming what it finds. plan-refactor breaks work into tiny commits but has no catalog to draw from. The code-review.md reference has a small smell table but it's ad hoc, not Fowler's canonical set. A reference to Fowler's catalog gives both skills a shared diagnostic language.

**Where to add**: docs/references/fowler.md. Cross-reference from audit-code and plan-refactor SKILL.md bodies.

### 1.3 Michael Feathers — Working Effectively with Legacy Code (2004)

**Status**: ABSENT. The "seam" concept in deepen-architecture/LANGUAGE.md cites Feathers ("from Michael Feathers") but there's no reference doc for the book itself.

**What it contributes**: The concept of "seams" (already borrowed by deepen-architecture), characterization tests (tests that document existing behavior before refactoring), and the dependency-breaking techniques catalog. The book defines legacy code as "code without tests" and provides techniques for getting untested code under test.

**Why it matters for bigpowers**: bigpowers targets solo developers who often inherit or create legacy code. The investigate-bug and diagnose-root skills deal with code that lacks tests, but there's no skill or reference for "how to get this untested code under test so I can refactor safely." Feathers' characterization tests are the answer.

**Where to add**: docs/references/feathers.md. The deepen-architecture LANGUAGE.md already cites Feathers — add the full reference. Consider a "characterize-legacy" skill or a mode in investigate-bug.

### 1.4 Sandi Metz — Practical Object-Oriented Design (POODR, 2nd ed 2018)

**Status**: ABSENT.

**What it contributes**: The SOLID principles explained through practical, small-scale examples. Her treatment of single responsibility at the class level (vs Uncle Bob's function level) complements Ousterhout's deep modules. She also coined the practical rule: "if a class has a reason to change that's different from its other reasons, extract." Her testing philosophy (unit tests for messages sent between objects, not internal state) directly informs the F.I.R.S.T rubric.

**Why it matters for bigpowers**: bigpowers has SOLID in CONVENTIONS.md (line 151: "SOLID beyond SRP") but no reference explaining what that means in practice. Metz's treatment is the most accessible for solo developers.

**Where to add**: docs/references/sandi-metz.md. Cross-reference from CONVENTIONS.md §Code Style.

### 1.5 Rich Hickey — "Simple Made Easy" (2011)

**Status**: ABSENT.

**What it contributes**: The critical distinction between "simple" (one fold, unmixed concerns) and "easy" (near to hand, familiar). Hickey argues that developers conflate the two, reaching for "easy" tools that introduce complexity (mixed concerns, interleaved state). The talk provides a vocabulary for diagnosing complexity that Ousterhout's "deep modules" doesn't address — Ousterhout talks about interface complexity; Hickey talks about implementation complexity (complecting).

**Why it matters for bigpowers**: The CONVENTIONS.md rule "Write the minimum code that solves the stated problem. Nothing extra." and Karpathy's "Simplicity First" both gesture at Hickey's distinction but don't have the vocabulary. "Is this simple or just easy?" is a grilling question that grill-me should ask.

**Where to add**: docs/references/rich-hickey.md. Add "simple vs easy" to the grill-me question set.

### 1.6 The Pragmatic Programmer — Andy Hunt & Dave Thomas (1999, 20th ed 2019)

**Status**: ABSENT. Andy Hunt's "Practices of an Agile Developer" is in the local library but not referenced in bigpowers.

**What it contributes**: DRY, "tracer bullets" (prototyping to validate architecture before full implementation — maps to spike-prototype), "broken windows" (the source of "fix the first broken window you see" in CONVENTIONS.md's Boy Scout Rule), orthogonality (independence of concerns), and the DRY vs AHA (Avoid Hasty Abstraction) tension. The 20th edition added "programming by coincidence" (code that works for unknown reasons) which is a root cause category that diagnose-root doesn't name.

**Why it matters for bigpowers**: CONVENTIONS.md already uses "broken window" (from this book) and "DRY" (from this book) without crediting the source. "Tracer bullets" is a better metaphor than "prototype" for what spike-prototype does. "Programming by coincidence" is a diagnostic category that investigate-bug should name explicitly.

**Where to add**: docs/references/pragmatic-programmer.md. Update PRINCIPLES.md to credit Hunt & Thomas alongside Uncle Bob.

### 1.7 Domain-Driven Design — Eric Evans (2003) / Vaughn Vernon (2013)

**Status**: PARTIALLY PRESENT. The model-domain skill exists and references "ubiquitous language" and "bounded context" but there's no reference doc for DDD itself. The deepen-architecture skill uses "seam" instead of "boundary" specifically to avoid overloading DDD's "bounded context."

**What it contributes**: Strategic design (bounded contexts, context mapping, ubiquitous language), tactical patterns (aggregates, repositories, domain events). The ubiquitous language concept is already in model-domain. What's missing is the strategic design layer: how to identify bounded contexts and map the relationships between them.

**Why it matters for bigpowers**: model-domain extracts the glossary but doesn't help with context boundaries — where does one model end and another begin? For solo developers building a monolith, this is the question that prevents the "god object" anti-pattern. deepen-architecture addresses module boundaries; DDD addresses domain boundaries.

**Where to add**: docs/references/ddd.md. Extend model-domain or create a "map-context" skill for context mapping.

### 1.8 Accelerate / DORA Metrics — Forsgren, Humble, Kim (2018)

**Status**: ABSENT. bigpowers has BCP/hr velocity tracking but no reference to the DORA four keys.

**What it contributes**: The four key metrics for software delivery performance: Deployment Frequency, Lead Time for Changes, Time to Restore Service, Change Failure Rate. These are the evidence-based metrics that correlate with high-performing teams.

**Why it matters for bigpowers**: bigpowers tracks BCP/hr (a velocity metric) but doesn't track the other three DORA dimensions. For a solo developer, tracking Change Failure Rate (how often a release requires a hotfix) and Time to Restore (how fast you fix a production issue) would add to the cycle-times.yaml ledger. The BCP/hr metric is bigpowers' innovation; the DORA four keys are the industry standard it should sit alongside.

**Where to add**: docs/references/accelerate.md. Extend specs/metrics/cycle-times.yaml to include change_failure_rate and restore_time. Add a "track-velocity" skill or extend release-branch.

### 1.9 Staff Engineer — Will Larson (2019)

**Status**: ABSENT.

**What it contributes**: The leverage modes for senior+ engineers: Solver, Tech Lead, Architect, Right Hand. For solo developers, the relevant insight is "scope of impact" — the progression from task-level to project-level to organization-level impact. bigpowers' 6-phase lifecycle implicitly moves through these scopes (story → epic → release), but the framing isn't explicit.

**Why it matters for bigpowers**: Solo developers using bigpowers are effectively a staff engineer wearing all hats. Larson's framing helps them decide where to invest their limited time — which problems are worth the "architect" mode (deep design) vs which need "solver" mode (just fix it).

**Where to add**: docs/references/staff-engineer.md. Cross-reference from orchestrate-project (which decides the phase and thus the scope of impact).

### 1.10 Working Effectively with Legacy Code — already covered above (#1.3)

### Summary: Missing Historical References

| # | Author | Work | Year | Contribution to bigpowers |
|---|--------|------|------|--------------------------|
| 1 | Kent Beck | XP + "Tidy First?" | 1999-2024 | TDD, vertical slices, tidy vs refactor vs behavior change |
| 2 | Martin Fowler | Refactoring | 1999-2018 | Code smell catalog, named refactorings |
| 3 | Michael Feathers | Working Effectively with Legacy Code | 2004 | Seams (already borrowed), characterization tests |
| 4 | Sandi Metz | POODR | 2018 | SOLID in practice, message-level testing |
| 5 | Rich Hickey | "Simple Made Easy" | 2011 | Simple vs easy distinction, complecting |
| 6 | Hunt & Thomas | The Pragmatic Programmer | 1999-2019 | DRY, broken windows, tracer bullets, programming by coincidence |
| 7 | Eric Evans | Domain-Driven Design | 2003 | Bounded contexts, context mapping (partially present) |
| 8 | Forsgren/Humble/Kim | Accelerate / DORA | 2018 | Four key delivery metrics |
| 9 | Will Larson | Staff Engineer | 2019 | Leverage modes, scope of impact |

---

## 2. Recent Articles Worth Adding

These are articles and tools from 2025-2026 that are gaining traction and address gaps in bigpowers.

### 2.1 LangChain "Context Engineering" (2025-2026)

**URL**: https://www.langchain.com/blog/context-engineering-for-agents
**GitHub**: https://github.com/langchain-ai/context_engineering

**What it contributes**: A four-strategy framework for managing agent context:
- **Write**: persist information to files between turns (bigpowers does this via specs/state.yaml)
- **Select**: choose what to load into context (bigpowers does this via survey-context)
- **Compress**: summarize to free context (bigpowers does this via terse-mode)
- **Isolate**: run work in fresh-context subagents (bigpowers does this via delegate-task)

**Why it matters**: bigpowers already implements all four strategies but doesn't name them. Naming them gives the agent a vocabulary for deciding which strategy to apply when. GSD Core borrowed this framework explicitly; bigpowers should too.

**Where to add**: docs/references/context-engineering.md. Add the four-strategy vocabulary to session-state and terse-mode. This is the missing theoretical backing for candidate 5.6 (effort: frontmatter) from the architecture review.

### 2.2 Karpathy's "Context Engineering" Definition (2025-2026)

**URL**: Referenced across multiple sources; Karpathy defined context engineering as "the art and science of delivering the right information, in the right format, at the right time."

**What it contributes**: The term "context engineering" itself — elevating prompt-level thinking to a systems discipline. bigpowers already does context engineering (specs/ is a context-engineering system) but doesn't use the term.

**Where to add**: Update PRINCIPLES.md to name "context engineering" as a first-class discipline alongside SDD.

### 2.3 Martin Fowler on SDD Tools (2026)

**URL**: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html

**What it contributes**: Fowler's analysis of the SDD tool landscape: Kiro (AWS), spec-kit, and Tessl. He defines SDD as "documentation first — the spec becomes the source of truth for code generation." This is the external validation of bigpowers' specs/ approach.

**Why it matters**: bigpowers has spec-kit.md reference but doesn't mention Kiro or the broader SDD tool landscape. Fowler's framing helps position bigpowers relative to these tools.

**Where to add**: Update docs/references/spec-kit.md to cover the full SDD tool landscape (Kiro, spec-kit, Tessl, BMAD, GSD, bigpowers).

### 2.4 Gergely Orosz / The Pragmatic Engineer — "AI Tooling for Software Engineers 2026"

**URL**: https://newsletter.pragmaticengineer.com/p/ai-tooling-2026

**What it contributes**: Survey data from ~1000 engineers on AI tooling adoption. Key findings: context management is the #1 pain point, spec-driven workflows are the #1 differentiator between high and low satisfaction.

**Why it matters**: Empirical evidence that bigpowers' bets (specs/ as context management, SDD as workflow) are the right bets.

**Where to add**: Cite in PRINCIPLES.md or README as external validation.

### 2.5 "Deep Agents" — AgentNativeDev (2026)

**URL**: https://agentnativedev.medium.com/deep-agents-the-harness-behind-claude-code-codex-manus-and-openclaw-bdd94688dfdb

**What it contributes**: Analysis of the agent harness pattern (Claude Code, Codex, Manus, OpenClaw). Identifies the shared architecture: thin orchestrator + fresh-context subagents + file-based state. This is the architectural pattern that bigpowers, GSD, and Superpowers all implement.

**Where to add**: docs/references/deep-agents.md. Use to position bigpowers' architecture in the broader ecosystem.

---

## 3. Target End State — What the Delivery Plan Gets You To

The question "what would I do differently from scratch?" turned out to be misleading. The current architecture is sound — the YAML cockpit, next_skill chain, BCP velocity tracking, and Gherkin compliance gates are genuine innovations that I would NOT change. What initially looked like "from scratch" improvements are actually just the delivery plan below, expressed as a vision instead of as stories.

This section reframes those ideas as the target end state that the 6-epic delivery plan (section 4) reaches incrementally. No rewrite required — each target is reached by shipping the corresponding epic.

### 3.1 Parse→IR→render pipeline → reached by Epic 2

The current sync-skills.sh grew organically (Cursor → Gemini → pi → OpenCode, each copy-pasted). The target end state is a shared library (scripts/lib/skill-common.sh) providing parse_frontmatter + iterate_skills, and sync-skills.sh using render-target functions where adding a target = adding a function. Epic 2 (4 stories, 13 BCP) gets there without a rewrite — you extract the shared library, then refactor the loop.

### 3.2 Context engineering as named discipline → reached by Epic 4

bigpowers already implements all four context-engineering strategies from LangChain's framework:
- **Write**: specs/state.yaml persists information between turns
- **Select**: survey-context chooses what to load
- **Compress**: terse-mode summarizes to free context
- **Isolate**: delegate-task runs work in fresh-context subagents

But it doesn't name them. The target end state is: the vocabulary is explicit in PRINCIPLES.md and session-state, and `effort: heavy|light` frontmatter gives agents a signal about context budget. Epic 4 (4 stories, 10 BCP) gets there — you're labeling what's already there, not rebuilding.

### 3.3 Skill count — 72 is the right number (no change)

I initially suggested reducing to ~25-30 skills from scratch. On reflection, that was wrong. The deletion test shows that most near-cousin clusters (plan-work/plan-release/plan-refactor, audit-code/request-review/respond-review) are genuinely distinct — different outputs, different responsibilities. Only 3-4 pairs (delegate-task/dispatch-agents, grill-me/grill-with-docs, fix-bug/investigate-bug/diagnose-root) are true cousins where a mode flag could replace a separate skill.

Progressive disclosure means descriptions are cheap (always in context) and full bodies load on demand. Superpowers' 14 skills is too coarse; GSD's 69 works fine. bigpowers' 72 is in the right range. The cousin merges are optional polish (deferred from the delivery plan), not a structural imperative.

### 3.4 YAML cockpit — already the right design (no change)

The specs/ YAML cockpit is bigpowers' best architectural decision. It's structured, machine-greppable, schema-validatable, and survives context resets. GSD uses prose Markdown (.planning/STATE.md); BMAD uses artifact folders. YAML is deeper — more capability per unit of interface. Nothing to change.

### 3.5 DORA four keys alongside BCP/hr → reached by Epic 5

bigpowers tracks BCP/hr (a velocity metric) but not the other three DORA keys. The target end state is cycle-times.yaml extended with:
- Deployment Frequency (release-branch already writes this)
- Lead Time for Changes (survey-context stamps story_start, release-branch stamps story_end — already tracked)
- Change Failure Rate (fix-bug triggered after a release → count as failure)
- Time to Restore (fix-bug start to validate-fix end — already trackable from bug_cycle)

Epic 5 (3 stories, 7 BCP) gets there — two of the four are already tracked, just not named.

### 3.6 Plan-checker as mandatory gate → 1 additional story (folded into Epic 1)

GSD and Superpowers both have a plan-checker that runs after planning and before execution. bigpowers has assess-impact and audit-plan but they're not mandatory gates in the build-epic cycle. The target is making plan validation a hard gate between plan-work and kickoff-branch. This is a 1-story change to build-epic's SKILL.md — add the gate step. Folded into Epic 1 as e01s05.

### 3.7 Reference docs as provenance pointers → reached by Epic 6

The target end state is docs/references/ as thin provenance pointers ("Source: Clean Code, Uncle Bob, 2008. See CONVENTIONS.md §Code Style for the rules.") rather than restating the principles. The canonical rules live in CONVENTIONS.md only. Epic 6 (4 stories, 10 BCP) gets there — you slim down the reference docs.

### Summary: the delivery plan IS the path from current to target

| Target | Current state | Epic that reaches it | Stories | BCP |
|--------|--------------|---------------------|---------|-----|
| Parse→IR→render pipeline | Copy-paste targets | Epic 2 | 4 | 13 |
| Context engineering named | Scattered mechanisms | Epic 4 | 4 | 10 |
| Skill count 72 | 72 (correct) | No change | 0 | 0 |
| YAML cockpit | Already correct | No change | 0 | 0 |
| DORA four keys | BCP/hr only | Epic 5 | 3 | 7 |
| Plan-checker gate | Optional | Epic 1 (e01s05) | 1 | 2 |
| Provenance pointers | Restated principles | Epic 6 | 4 | 10 |

---

## 4. Delivery Plan — Sliced for Solo Developers

This plan integrates:
- Bug fixes from the architecture review
- Deepening opportunities from the architecture review
- New references from this analysis
- Target end states from section 3

Sliced into 6 epics, ordered by WSJF (value / effort). Each epic is independently shippable. Each story has BCP, verify commands, and next_skill.

---

### Epic 1: Quick Fixes (WSJF: 13/2 = 6.5)

Fix the concrete bugs found in the architecture review. These are mechanical fixes with no design decisions.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e01s01 | 2 | Add extract-design, security-review, visual-dashboard to get_phase() in generate-skill-index.sh | `bash scripts/sync-skills.sh && grep -c 'TOTAL.*72\|Total: 72' SKILL-INDEX.md` |
| e01s02 | 2 | Fix 4 broken specs/tech-architecture/ references in orchestrate-project and seed-conventions SKILL.md | `grep -rn 'tech-architecture/test.md\|tech-architecture/design.md\|tech-architecture/security.md' skills/ && echo "FAIL: still broken" \|\| echo "OK"` |
| e01s03 | 1 | Delete specs/verifications/features/karpathy.feature.bak | `test ! -f specs/verifications/features/karpathy.feature.bak && echo OK` |
| e01s04 | 3 | Replace 50+ tautological verify commands with either removal or behavior-relevant checks | `grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md \| grep -v ':0$' \| wc -l \| awk '{if($1==0) print "OK"; else print "REMAINING: "$1}'` |
| e01s05 | 2 | Add plan-checker as mandatory gate in build-epic SKILL.md — insert assess-impact or audit-plan step between plan-work (step 2) and kickoff-branch (step 3) in the 8-step cycle | `grep -q 'assess-impact\|audit-plan' skills/build-epic/SKILL.md && grep -q 'gate\|mandatory' skills/build-epic/SKILL.md && echo OK` |

**next_skill**: e01s01 → e01s02 → e01s03 → e01s04 → e01s05 → release-branch

---

### Epic 2: Sync Pipeline Refactor (WSJF: 10/5 = 2.0)

Refactor the build pipeline from copy-paste-variant to parse→IR→render. This is the highest structural-impact change.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e02s01 | 3 | Create scripts/lib/skill-common.sh with resolve_repo_root, resolve_skills_root, parse_frontmatter, iterate_skills | `source scripts/lib/skill-common.sh && parse_frontmatter skills/audit-code/SKILL.md && echo OK` |
| e02s02 | 2 | Refactor 13 scripts to source skill-common.sh instead of duplicating REPO_ROOT/SKILLS_ROOT boilerplate | `grep -c 'REPO_ROOT=.*dirname.*BASH_SOURCE' scripts/*.sh \| grep -v ':0$' \| wc -l \| awk '{if($1<=1) print "OK"; else print "REMAINING: "$1}'` |
| e02s03 | 5 | Refactor sync-skills.sh to use render-target functions (one function per target: cursor, gemini-skill, gemini-command, pi-skill, pi-prompt) | `bash scripts/sync-skills.sh && test -f .cursor/rules/audit-code.mdc && test -f .gemini/extensions/bigpowers/skills/audit-code/SKILL.md && test -f .pi/skills/audit-code/SKILL.md && echo OK` |
| e02s04 | 3 | Refactor regenerate-lockfile.sh, generate-skill-index.sh, build-skill-index.sh to source skill-common.sh and use shared parse_frontmatter | `bash scripts/sync-skills.sh && jq '.skills \| length' skills-lock.json \| awk '{if($1==72) print "OK"; else print "FAIL: "$1}'` |

**next_skill**: e02s01 → e02s02 → e02s03 → e02s04 → release-branch

---

### Epic 3: Missing Historical References (WSJF: 12/4 = 3.0)

Add the 9 missing historical reference docs and cross-reference them from the skills that use their concepts.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e03s01 | 2 | Create docs/references/kent-beck.md (XP, TDD origins, Tidy First? tidy vs refactor vs behavior) | `test -f docs/references/kent-beck.md && grep -q 'Tidy First' docs/references/kent-beck.md && echo OK` |
| e03s02 | 2 | Create docs/references/fowler.md (refactoring catalog, code smells, named refactorings) | `test -f docs/references/fowler.md && grep -q 'Extract Method\|code smell' docs/references/fowler.md && echo OK` |
| e03s03 | 2 | Create docs/references/feathers.md (seams, characterization tests, legacy code = code without tests) | `test -f docs/references/feathers.md && grep -q 'characterization\|seam' docs/references/feathers.md && echo OK` |
| e03s04 | 2 | Create docs/references/pragmatic-programmer.md (DRY, broken windows, tracer bullets, programming by coincidence) | `test -f docs/references/pragmatic-programmer.md && grep -q 'broken window\|tracer bullet\|coincidence' docs/references/pragmatic-programmer.md && echo OK` |
| e03s05 | 2 | Create docs/references/rich-hickey.md (simple vs easy, complecting) | `test -f docs/references/rich-hickey.md && grep -q 'simple.*easy\|complect' docs/references/rich-hickey.md && echo OK` |
| e03s06 | 2 | Create docs/references/sandi-metz.md (SOLID in practice, message-level testing) | `test -f docs/references/sandi-metz.md && grep -q 'SOLID\|message' docs/references/sandi-metz.md && echo OK` |
| e03s07 | 2 | Create docs/references/ddd.md (bounded contexts, context mapping, ubiquitous language) | `test -f docs/references/ddd.md && grep -q 'bounded context\|context map' docs/references/ddd.md && echo OK` |
| e03s08 | 2 | Create docs/references/accelerate.md (DORA four keys: deployment frequency, lead time, restore time, change failure rate) | `test -f docs/references/accelerate.md && grep -q 'DORA\|four key' docs/references/accelerate.md && echo OK` |
| e03s09 | 2 | Update PRINCIPLES.md to credit Beck, Fowler, Feathers, Hunt & Thomas alongside Uncle Bob in layer 1 | `grep -q 'Beck\|Fowler\|Feathers\|Hunt' docs/PRINCIPLES.md && echo OK` |
| e03s10 | 2 | Cross-reference new docs from SKILL.md bodies (plan-refactor → fowler, audit-code → fowler smells, investigate-bug → feathers, grill-me → hickey) | `grep -q 'fowler' skills/plan-refactor/SKILL.md && grep -q 'feathers\|characterization' skills/investigate-bug/SKILL.md && echo OK` |

**next_skill**: e03s01 → e03s02 → ... → e03s10 → release-branch

---

### Epic 4: Context Engineering Layer (WSJF: 11/4 = 2.75)

Add the context-engineering vocabulary and effort signaling that GSD Core has and bigpowers lacks.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e04s01 | 2 | Create docs/references/context-engineering.md (LangChain's write/select/compress/isolate framework, Karpathy's definition) | `test -f docs/references/context-engineering.md && grep -q 'write.*select.*compress.*isolate' docs/references/context-engineering.md && echo OK` |
| e04s02 | 3 | Add optional `effort: heavy\|light` frontmatter to all 72 skills. Heavy = orchestrators (build-epic, execute-plan, orchestrate-project, delegate-task, dispatch-agents, verify-work). Light = utilities (terse-mode, session-state, search-skills, reset-baseline). Default = medium (omit). | `grep -rl 'effort:' skills/*/SKILL.md \| wc -l \| awk '{if($1>=10) print "OK"; else print "FAIL: "$1}'` |
| e04s03 | 2 | Update CLAUDE.md Token Management section to use context-engineering vocabulary (write/select/compress/isolate) and reference effort: frontmatter | `grep -q 'write.*select.*compress.*isolate\|effort:' CLAUDE.md && echo OK` |
| e04s04 | 3 | Update session-state SKILL.md to name the four context-engineering strategies explicitly and map them to bigpowers mechanisms | `grep -q 'write\|select\|compress\|isolate' skills/session-state/SKILL.md && echo OK` |

**next_skill**: e04s01 → e04s02 → e04s03 → e04s04 → release-branch

---

### Epic 5: DORA Metrics Extension (WSJF: 8/3 = 2.67)

Extend the metrics layer from BCP/hr only to all four DORA keys.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e05s01 | 2 | Extend specs/metrics/cycle-times.yaml schema to include change_failure_rate and restore_time_minutes fields | `grep -q 'change_failure_rate\|restore_time' specs/metrics/cycle-times.yaml 2>/dev/null \|\| grep -q 'change_failure_rate\|restore_time' docs/references/accelerate.md && echo OK` |
| e05s02 | 3 | Update release-branch to compute change_failure_rate (count of fix-bug cycles triggered within 7 days of release) and restore_time_minutes (bug_cycle start to validate-fix end) | `grep -q 'change_failure_rate\|restore_time' skills/release-branch/SKILL.md && echo OK` |
| e05s03 | 2 | Update CONVENTIONS.md BCP accounting section to reference DORA four keys alongside BCP/hr | `grep -q 'DORA\|deployment.frequency\|change.failure' CONVENTIONS.md && echo OK` |

**next_skill**: e05s01 → e05s02 → e05s03 → release-branch

---

### Epic 6: Documentation Deduplication (WSJF: 7/5 = 1.4)

Replace hub-and-spoke duplication with single-source-of-truth + provenance pointers.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e06s01 | 3 | Convert docs/references/uncle-bob.md from restating principles to provenance pointer ("See CONVENTIONS.md §Code Style and §Tests. Source: Clean Code, 2008.") | `wc -l docs/references/uncle-bob.md \| awk '{if($1<20) print "OK: slimmed"; else print "FAIL: "$1" lines"}'` |
| e06s02 | 3 | Convert docs/references/akita.md, ousterhout.md, karpathy.md, wasowski.md to provenance pointers | `for f in akita ousterhout karpathy wasowski; do wc -l docs/references/$f.md \| awk '{if($1>30) print "FAIL: '$f' still long"}'; done && echo OK` |
| e06s03 | 2 | Remove F.I.R.S.T rubric restatement from enforce-first/SKILL.md and audit-code/SKILL.md; replace with "See CONVENTIONS.md §Tests (F.I.R.S.T)" | `grep -c 'Fast.*Independent.*Repeatable' skills/enforce-first/SKILL.md skills/audit-code/SKILL.md \| awk -F: '{sum+=$2} END{if(sum<=1) print "OK"; else print "FAIL: "sum}'` |
| e06s04 | 2 | Update docs/references/spec-kit.md to cover full SDD tool landscape (Kiro, spec-kit, Tessl, BMAD, GSD, bigpowers) with Fowler's framing | `grep -q 'Kiro\|Tessl' docs/references/spec-kit.md && echo OK` |

**next_skill**: e06s01 → e06s02 → e06s03 → e06s04 → release-branch

---

### Delivery Summary

| Epic | Stories | Total BCP | WSJF | Priority |
|------|---------|-----------|------|----------|
| Epic 1: Quick Fixes | 5 | 10 | 6.5 | 1st — ship immediately |
| Epic 2: Sync Pipeline | 4 | 13 | 2.0 | 3rd — structural, needs design |
| Epic 3: Historical References | 10 | 20 | 3.0 | 2nd — high value, low effort |
| Epic 4: Context Engineering | 4 | 10 | 2.75 | 4th — borrows GSD's best idea |
| Epic 5: DORA Metrics | 3 | 7 | 2.67 | 5th — extends BCP innovation |
| Epic 6: Doc Dedup | 4 | 10 | 1.4 | 6th — lowest urgency, highest churn |

**Total**: 30 stories, 70 BCP across 6 epics.

### What's NOT in this plan (and why)

- **Near-cousin skill merging** (candidate 5.4): Controversial — reduces the 72-skill count that's a marketing feature. Defer until there's user feedback that the cousins cause navigation friction.
- **Flat script directory reorganization** (candidate 5.7): Changes path references everywhere, high churn for low value. Defer.
- **context7.mdc promotion** (candidate 5.8): Minor. Defer.
- **Lifecycle hooks** (PreCompact etc): Requires runtime-specific implementation per IDE. Defer until bigpowers has more runtime support.

---

*End of report*
