# bigpowers — Implementation Plan

> **Status: PLAN ONLY — no files have been changed yet.**
> Review and approve this document before executing anything.
>
> **Audit applied:** gaps from AUDIT.md closed on 2026-05-17.
> Key changes: +7 skills (spike-prototype, enforce-first, wire-observability, define-success, using-bigpowers, seed-conventions, grill-with-docs); CONVENTIONS.md rewritten with Akita's full block; plan-work updated for Karpathy verify-pairs; compress-tokens repositioned as terse-mode fallback; audit-code/request-review split clarified; dispatch-agents/delegate-task distinction documented.

---

## Identity

**Name:** bigpowers
**Model:** Fork of obra/superpowers + overrides from mattpocock/skills + original additions
**Naming convention:** Uncle Bob / Clean Code — every skill is a **verb-noun pair** that reveals its single intent, pronounceable in any language, searchable, no noise words, no encodings
**Cohesion rule:** Each skill does one thing. No merges. Low coupling — skills reference each other by name only, never by importing content.
**Local-first:** No skill creates GitHub issues. Workflow produces local Markdown files. `gh` is used exclusively for pull requests and branch operations, never for issue management.

---

## Repository Structure (mirrors superpowers)

```
bigpowers/
├── .claude-plugin/         ← Claude Code plugin manifest
├── .gemini/                ← Gemini CLI extension config
├── skills/
│   ├── using-bigpowers/    ← NEW: one-time bootstrap intro to the skills system
│   ├── survey-context/     ← per-task context survey (split from bootstrap role)
│   ├── elaborate-spec/
│   ├── model-domain/
│   ├── define-language/
│   ├── challenge-design/
│   ├── grill-with-docs/    ← NEW: challenge-design grounded in real library docs
│   ├── deepen-architecture/
│   ├── scope-work/
│   ├── slice-tasks/
│   ├── plan-work/
│   ├── plan-refactor/
│   ├── spike-prototype/    ← NEW: throw-away spike before committing to TDD
│   ├── define-success/     ← NEW: convert task to "step → verify: <cmd>" pairs
│   ├── kickoff-branch/
│   ├── guard-git/
│   ├── hook-commits/
│   ├── seed-conventions/   ← NEW: generate CLAUDE.md / CONVENTIONS.md for a new project
│   ├── develop-tdd/
│   ├── enforce-first/      ← NEW: F.I.R.S.T test-quality rubric (used inside develop-tdd)
│   ├── delegate-task/
│   ├── dispatch-agents/
│   ├── execute-plan/
│   ├── wire-observability/ ← NEW: structured logging + observability + idempotent setup
│   ├── investigate-bug/
│   ├── diagnose-root/
│   ├── validate-fix/
│   ├── audit-code/
│   ├── request-review/     ← NEW: formally request human review; links audit-code → respond-review
│   ├── respond-review/
│   ├── commit-message/
│   ├── release-branch/
│   ├── inspect-quality/
│   ├── organize-workspace/
│   ├── terse-mode/         ← RENAMED from compress-tokens; fallback utility only
│   ├── craft-skill/
│   └── edit-document/
├── AGENTS.md               ← install artifact: copy to project root
├── CLAUDE.md               ← install artifact: copy to project root
├── GEMINI.md               ← install artifact: copy to project root
├── CONVENTIONS.md          ← install artifact: copy to project root
└── README.md
```

---

## Naming — Clean Code Applied

Uncle Bob's rules for naming (Chapter 2) applied to skills:

- **Use intention-revealing names** — the name answers: what will the agent DO, and to what?
- **Use pronounceable names** — every name is speakable without decoding
- **Make meaningful distinctions** — no two skills sound like the same thing
- **Avoid noise words** — no `using-`, `writing-`, `finishing-a-`, `requesting-`
- **Functions are verbs** — first word is always a verb (survey, model, define, develop…)
- **Second word disambiguates** — noun makes the intent concrete (survey-context, develop-tdd…)
- **Do one thing** — if a name needs "and" to explain it, split the skill
- **PMBOK / Agile vocabulary** — nouns drawn from PMBOK 6 + Agile Practice Guide for global recognition

---

## Complete Skill Inventory

### Relationship to source skills

| bigpowers name | Clean Code intent | Source | Action |
|---|---|---|---|
| `using-bigpowers` | One-time bootstrap: introduce the skills system and lifecycle | using-superpowers (superpowers) | **NEW** — split from survey-context |
| `survey-context` | Per-task context survey: read CONVENTIONS.md, map state, suggest next skill | zoom-out | rename (scope narrowed — bootstrap moved to using-bigpowers) |
| `elaborate-spec` | Refine a rough idea into a spec through dialogue | brainstorming (superpowers) | keep + extend |
| `model-domain` | Build the domain model interactively, update CONTEXT.md | domain-model | rename |
| `define-language` | Extract and persist the ubiquitous language glossary | ubiquitous-language | rename |
| `challenge-design` | Stress-test a plan by grilling its assumptions | grill-me | rename |
| `grill-with-docs` | Stress-test assumptions grounded in actual library docs (prevents hallucinated APIs) | grill-with-docs (Pocock) | **NEW** — variant of challenge-design |
| `deepen-architecture` | Surface architecture deepening opportunities | improve-codebase-architecture | rename |
| `scope-work` | Define what's in/out, produce local SCOPE.md | to-prd (adapted, no gh issue) | rename + adapt |
| `slice-tasks` | Slice work into local TASKS.md with vertical slices | to-issues (adapted, no gh issue) | rename + adapt |
| `plan-work` | Write a detailed plan to PLAN.md; every step must include `verify: <runnable check>` (Karpathy) | writing-plans (superpowers) | keep + extend |
| `plan-refactor` | Plan a refactor via interview, produce local REFACTOR.md | request-refactor-plan (adapted) | rename + adapt |
| `spike-prototype` | Throw-away spike for unknown problem spaces; output is learning, not code | prototype (Pocock) | **NEW** — precedes develop-tdd when domain is unexplored |
| `define-success` | Convert an imperative task into "step → verify: \<command\>" pairs | Karpathy "transform imperative → verifiable goal" | **NEW** — plan-work should require its output |
| `kickoff-branch` | Create worktree + branch + verify clean test baseline | using-git-worktrees (superpowers) | keep + extend |
| `guard-git` | Install hooks that block destructive git operations | git-guardrails | rename |
| `hook-commits` | Install pre-commit hooks: lint, format, typecheck, test | setup-pre-commit | rename |
| `seed-conventions` | Generate CLAUDE.md + CONVENTIONS.md for a brand-new project | Akita "writing CLAUDE.md is a skill" | **NEW** — entry-point for greenfield projects |
| `develop-tdd` | Run red-green-refactor TDD loop (richer than superpowers) | tdd + test-driven-development | override superpowers |
| `enforce-first` | Apply F.I.R.S.T test-quality rubric (Fast, Independent, Repeatable, Self-Validating, Timely) | Akita / Clean Code Ch 9 | **NEW** — loaded by develop-tdd when writing tests |
| `delegate-task` | **One subagent, one task, sequential.** Two-stage review before merging back. Use when oversight of a single complex task is needed. _Distinct from dispatch-agents: no parallelism, reviewer sees full diff before proceed._ | subagent-driven-development (superpowers) | keep |
| `dispatch-agents` | **Multiple subagents in parallel on independent tasks.** No waiting between them. Use when tasks are truly decoupled and speed matters over careful per-task review. _Distinct from delegate-task: concurrent, no inter-task review gate._ | dispatching-parallel-agents (superpowers) | keep |
| `execute-plan` | Batch execute plan tasks sequentially with human checkpoints | executing-plans (superpowers) | keep |
| `wire-observability` | Add structured JSON logging, observability commands, and idempotent setup scripts to a project | Akita "structured logging + accessible observability + idempotent setup" | **NEW** — production-readiness lever |
| `investigate-bug` | Investigate a bug, produce local DIAGNOSIS.md | triage-issue (adapted, no gh issue) | rename + adapt |
| `diagnose-root` | Run 4-phase root cause process on an active problem | systematic-debugging (superpowers) | keep + extend |
| `validate-fix` | Prove the fix works before declaring done | verification-before-completion (superpowers) | keep |
| `audit-code` | **Self-review checklist you run before dispatching a reviewer agent.** Checks CONVENTIONS.md compliance, Boy Scout Rule, test coverage, types, SOLID, no `any`. Output: pass/fail checklist. _Distinct from request-review: this is the coding agent checking its own work; no second agent is involved yet._ | requesting-code-review (superpowers) | keep |
| `request-review` | **Dispatch a fresh reviewer agent to critique the code after audit-code passes.** The reviewer agent gets a clean context — no shared state with the coding agent — so it can give a genuine second opinion. Produces a structured review report. _Distinct from audit-code: this is the external agent review; the coding agent is not doing the reviewing here._ Solo-developer note: this replaces the human reviewer — the agent IS the reviewer. | — (gap in superpowers) | **NEW** — closes the audit-code → respond-review gap |
| `respond-review` | Act on the reviewer agent's feedback systematically: categorize findings (must-fix / should-fix / consider), apply changes, verify tests still pass | receiving-code-review (superpowers) | keep |
| `commit-message` | Draft Conventional Commits message + predict semver bump; note defensive-code categories touched | prepare-semantic-commit | rename |
| `release-branch` | Merge/PR/keep/discard decision + worktree cleanup (gh pr); coverage ≥ 80% overall / ≥ 95% business logic recommended | finishing-a-development-branch (superpowers) | keep + extend |
| `inspect-quality` | Run local QA session, produce BUG-LOG.md | qa (adapted, no gh issue) | rename + adapt |
| `organize-workspace` | Scan, classify, confirm, then clean the workspace | clean-my-room | rename |
| `terse-mode` | **Fallback only.** Switch to ultra-terse output when context is critically long. _Not a strategy — token discipline comes from code shape (small functions, unique names, headless tests), not terser prompts._ | caveman | rename from compress-tokens + repositioned |
| `craft-skill` | Create a new bigpowers skill with proper structure | write-a-skill + writing-skills (superpowers) | merge + override |
| `edit-document` | Edit and restructure a document for clarity and flow | edit-article | rename |

**Dropped (project-specific, not bigpowers core):**
- `scaffold-exercises` — tied to ai-hero-cli, not general-purpose
- `obsidian-vault` — personal vault path hardcoded
- `migrate-to-shoehorn` — TypeScript-specific library migration
- `github-triage` — pure GitHub issue state machine, contradicts local-first rule
- `test-skill` — placeholder, discard

---

## Workflow Arc

The skills map to a developer lifecycle. The arc is documented in `README.md`:

```
[first time only] using-bigpowers
                              ↓
survey-context → elaborate-spec → model-domain / define-language
                              ↓
          challenge-design / grill-with-docs → deepen-architecture
                              ↓
              scope-work → slice-tasks → define-success
                              ↓
                    plan-work / plan-refactor
                              ↓
              kickoff-branch → guard-git / hook-commits / seed-conventions
                              ↓
          [unknown domain?] spike-prototype → (learnings feed back to plan-work)
                              ↓
develop-tdd (+ enforce-first) ←→ delegate-task / dispatch-agents / execute-plan
                              ↓
         investigate-bug → diagnose-root → validate-fix
                              ↓
         wire-observability (production-readiness gate, any phase)
                              ↓
                   audit-code → request-review → respond-review
                              ↓
                   commit-message → release-branch
                              ↓
                inspect-quality → organize-workspace (ongoing)
```

**Dispatch vs delegate decision rule:**
- Use `delegate-task` when a task is complex, sequential, and requires a two-stage review before the agent proceeds.
- Use `dispatch-agents` when multiple tasks are truly independent and can safely run concurrently — no review gate between them.

**Audit vs request-review distinction (solo developer with agents):**
- `audit-code` = the coding agent self-checks its own work before anyone else sees it (CONVENTIONS.md compliance, Boy Scout Rule, coverage, types). Internal.
- `request-review` = dispatch a *fresh* reviewer agent with a clean context — it has no shared state with the coding agent and can give a genuine second opinion. This is the agent that replaces the human reviewer for a solo developer.
- `respond-review` = act on the reviewer agent's findings: categorize, apply fixes, re-verify.

`terse-mode`, `craft-skill`, and `edit-document` are transversal utilities invokable at any phase.
`enforce-first` is a sub-skill loaded by `develop-tdd` when writing tests — not invoked standalone in normal flow.

---

## gh Enforcement Strategy

**Problem:** Repeating "always use gh" in every skill bloats context and creates inconsistency.

**Solution:** Single source of truth in `CONVENTIONS.md`. Every meta-doc (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) contains one line:

```
Before any GitHub or git operation, read CONVENTIONS.md.
```

Agents load `CONVENTIONS.md` once at session start. It is never repeated inside individual skills.

**What CONVENTIONS.md enforces:**
- Use `gh pr create`, `gh pr merge`, `gh pr view` — never `git push` to open PRs
- Use `gh repo clone` — never `git clone` for GitHub repos
- Use `gh auth status` to verify auth before git operations
- Use `gh run view` / `gh run watch` for CI status
- Never call the GitHub REST API directly with curl or fetch
- Never create GitHub issues from skills — produce local Markdown files instead
- Code quality rules: typed over untyped, no duplication, comments explain why not what

---

## Install Artifacts

These four files are designed to be **copied into a project's root directory**. They are not skills — they are project-level configuration for AI agents.

### `CLAUDE.md` — for Claude Code

```markdown
# [Project Name] — Claude Code

Read CONVENTIONS.md before any GitHub or git operation.

## Project
[One sentence. What this codebase does.]
Stack: [language, framework, runtime]

## Commands
| Action | Command |
|--------|---------|
| Run | `[cmd]` |
| Test | `[cmd]` |
| Build | `[cmd]` |
| Lint | `[cmd]` |

## Architecture
[1–2 sentences. Key modules and their relationships. No implementation details.]

## Conventions
- [e.g. Named exports only]
- [e.g. All queries go through the repository layer]

## Never
- [Hard stop — e.g. Never touch legacy/]
- [Hard stop — e.g. Never run seed in production]

## Agent Rules
- Read CONTEXT.md and docs/adr/ before writing code.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
```

### `GEMINI.md` — for Gemini CLI

Same structure as CLAUDE.md. Key differences:
- Keep under 2000 tokens (Gemini context management)
- Gemini reads `GEMINI.md` at extension load time
- No `disable-model-invocation` concept

### `AGENTS.md` — for all agents (OpenAI Codex and others)

Same structure. Additional mandatory section:

```markdown
## Mandatory Behavior
1. Think first. Read context before touching files.
2. Simplest solution. Write least code that satisfies the requirement.
3. Surgical. Change only what was asked. Never improve unrelated code.
4. Verify. Run tests. Show evidence the goal was met.
5. Ask when unsure. One question beats a wrong assumption.
```

### `CONVENTIONS.md` — shared rules, loaded by all agents

```markdown
# Conventions

## GitHub & Git Operations
- Use `gh pr create` not `git push` + manual PR
- Use `gh repo clone` not `git clone` for GitHub repos
- Use `gh run view` / `gh run watch` for CI status
- Verify auth with `gh auth status` before operations
- Never call GitHub REST API directly (curl, fetch, etc.)
- Never create GitHub issues from automated workflows — produce local .md files

## Code Style (Akita / Clean Code re-rank for agent readers)
- Functions: 4–20 lines. Split if longer.
- Files: under 500 lines, ideally 200–300. Split by responsibility.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`, `Service`.
  Prefer names whose grep returns <5 hits in this codebase.
- Types: explicit. No `any`, no untyped public functions.
- No code duplication. Extract shared logic into a function/module.
- Early returns over nested ifs. Max 2 levels of indentation.
- Exception messages must include the offending value and expected shape.
- SOLID beyond SRP: favor interfaces over concrete types (DIP) when injecting dependencies.

## Comments
- Keep your own comments. Never strip them on refactor — they carry intent and provenance.
- Write WHY, not WHAT.
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because of a specific bug.
- No obvious comments that restate the code.

## Tests (F.I.R.S.T — Uncle Bob Ch 9)
- Tests run headless with a single command (recorded in CLAUDE.md).
- Every new function gets a test. Every bug fix gets a regression test.
- Mocks for external I/O are named fake classes, not inline stubs.
- Tests are **F**ast, **I**ndependent, **R**epeatable, **S**elf-Validating, **T**imely.

## Dependencies
- Inject dependencies through constructor/parameter, not global/import.
- Wrap third-party libs behind a thin project-owned interface.

## Structure
- Follow the framework convention (Rails, Django, Next.js, etc.).
- Predictable paths: controller/model/view, src/lib/test.
- Prefer small focused modules over god files.

## Formatting
- Use the language default formatter (cargo fmt, gofmt, prettier, black, rubocop -A).
- Configured in pre-commit and on-save. No style debates beyond that.

## Logging
- Structured JSON for debugging / observability.
- Plain text only for user-facing CLI output.

## Defensive Code (project must list which categories apply)
- Rate limit | Retry with backoff | Circuit breaker | Timeout | Graceful degradation
- The agent implements defensive code only for categories explicitly listed here.

## Output Files
When a skill produces written output, use these filenames:
- Scope definition → SCOPE.md
- Task breakdown → TASKS.md
- Implementation plan → PLAN.md (or PLAN-[feature].md)
- Refactor plan → REFACTOR.md
- Bug investigation → DIAGNOSIS.md
- QA session log → BUG-LOG.md
- Domain glossary → CONTEXT.md / UBIQUITOUS_LANGUAGE.md
```

---

## Execution Order

Once approved, work proceeds in this sequence. No step begins before the previous is complete.

**Step 1 — Scaffold the repo structure**
- Create `bigpowers/` with superpowers-mirrored layout
- Create empty `skills/` subdirectories for all 29 skills (two-word names)
- Create `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `CONVENTIONS.md` at root

**Step 2 — Port and rename existing skills (your repo → bigpowers)**
Rename only (content unchanged for now):
`survey-context`, `model-domain`, `define-language`, `challenge-design`, `deepen-architecture`, `guard-git`, `hook-commits`, `commit-message`, `organize-workspace`, `compress-tokens`, `edit-document`

**Step 3 — Adapt local-first skills (remove gh issue creation)**
Rewrite output target from GitHub issues to local Markdown files:
`scope-work`, `slice-tasks`, `plan-refactor`, `investigate-bug`, `inspect-quality`

**Step 4 — Port superpowers skills (keep content, update naming/style)**
`elaborate-spec`, `kickoff-branch`, `delegate-task`, `dispatch-agents`, `execute-plan`, `diagnose-root`, `validate-fix`, `audit-code`, `respond-review`, `release-branch`

**Step 5 — Override: your version beats superpowers**
`develop-tdd` — merge your TDD skill (richer vertical-slice philosophy) over superpowers' version

**Step 6 — Merge: two sources into one skill**
`craft-skill` — merge write-a-skill + superpowers writing-skills into one

**Step 7 — Write `plan-work` skill**
Standalone skill: produce a structured PLAN.md from a scope and task list. Every step in the output MUST follow the Karpathy verification template:
```
N. <Step> → verify: <runnable command>
```
The skill should call `define-success` before writing PLAN.md when the task's success criteria are unclear.

**Step 7b — Write `define-success` skill**
Converts an imperative task statement into "step → verify: \<command\>" pairs. Used as a pre-flight check by `plan-work` and `develop-tdd`.

**Step 7c — Write `spike-prototype` skill**
Throw-away spike for unknown problem spaces. Output is learning notes (not code to keep). Explicitly transitions to `plan-work` → `develop-tdd` after the spike is done.

**Step 7d — Write `enforce-first` skill**
F.I.R.S.T test rubric as a sub-skill invoked by `develop-tdd` when writing tests. Not typically invoked standalone.

**Step 7e — Write `wire-observability` skill**
Adds structured JSON logging, documents observability commands in CLAUDE.md, and writes idempotent setup scripts. Can be invoked at any phase; recommended at the end of first working slice.

**Step 7f — Write `seed-conventions` skill**
Generates CLAUDE.md + CONVENTIONS.md for a brand-new project through a brief interview. The entry-point for greenfield work.

**Step 7g — Write `request-review` skill**
Dispatches a fresh reviewer agent (clean context, no shared state with coding agent). Reviewer produces a structured report. Solo-developer equivalent of assigning a human reviewer.

**Step 7h — Write `using-bigpowers` skill**
One-time bootstrap: introduces the skills system, the PMBOK lifecycle arc, and tells the agent which skill to call first. Analogous to superpowers' `using-superpowers`.

**Step 7i — Write `grill-with-docs` skill**
Variant of `challenge-design` that grounds every assumption challenge in a real library/API doc URL. Prevents hallucinated API usage in production work.

**Step 8 — Write `survey-context` skill (narrowed scope)**
Per-task context survey: reads CONVENTIONS.md, reads CONTEXT.md if present, maps current lifecycle phase, suggests next skill. Does NOT introduce the skills system (that's `using-bigpowers`).

**Step 9 — Verify**
Run through a test scenario end to end:
`survey-context` → `elaborate-spec` → `plan-work` → `develop-tdd` → `validate-fix` → `commit-message`

**Step 10 — Write README.md**
Produce a README modeled after the role-directory README structure:

- **Header** — project name `bigpowers`, tagline ("A curated lifecycle of agent skills for production-ready, TDD-driven software by solo developers"), badges: based on superpowers, skill count (36), MIT license, Claude/Gemini/Codex compatible
- **Motivation** — blockquote "The Magic": one paragraph on why a coherent skill lifecycle beats ad-hoc prompting
- **How It Works** — lifecycle arc as ASCII diagram (Discover → Design → Plan → Initiate → Execute → Inspect → Review → Integrate → Sustain, with skill names at each node)
- **Skills Reference** — table organized by PMBOK lifecycle phase, columns: skill name (linked), one-line description, source
  - Bootstrap (one-time): `using-bigpowers`, `seed-conventions`
  - Discover: `survey-context`, `elaborate-spec`
  - Design: `model-domain`, `define-language`, `challenge-design`, `grill-with-docs`, `deepen-architecture`
  - Plan: `scope-work`, `slice-tasks`, `define-success`, `plan-work`, `plan-refactor`
  - Spike: `spike-prototype` (optional — unknown domains only)
  - Initiate: `kickoff-branch`, `guard-git`, `hook-commits`
  - Execute: `develop-tdd`, `enforce-first`, `delegate-task`, `dispatch-agents`, `execute-plan`
  - Harden: `wire-observability` (any phase)
  - Inspect: `investigate-bug`, `diagnose-root`, `validate-fix`
  - Review: `audit-code`, `request-review`, `respond-review`
  - Integrate: `commit-message`, `release-branch`
  - Sustain: `inspect-quality`, `organize-workspace`
  - Utility (any phase): `terse-mode` (fallback only), `craft-skill`, `edit-document`
- **Installation** — step-by-step numbered, one section per harness (Claude Code, Gemini CLI, Cursor, Codex)
- **Install Artifacts** — explain CLAUDE.md / GEMINI.md / AGENTS.md / CONVENTIONS.md, link to each file, copy-to-project instructions
- **Philosophy** — five principles: alta coesão e baixo acoplamento, Uncle Bob naming, PMBOK lifecycle + local-first, **complexity reduction** (always the simplest solution that satisfies the requirement), **evidence over claims** (every task ends with a runnable verify step — not "I think it works")
- **Contributing** — how to add a skill using `craft-skill`, PR checklist, naming rules
- **Credits** — obra/superpowers (base), mattpocock/skills (overrides), akitaonrails (Clean Code for AI Agents), andrej-karpathy-skills (Think Before Coding)
- **License** — MIT with full text
- **Project Status & Roadmap** — checkbox list (✅ done / 🔲 planned)
- **Footer tagline** — "Made with ❤️ by danielvm | Skills: 36 | Philosophy: Clean Code × PMBOK × alta coesão × evidence over claims"

---

## What Changes vs. What Stays

| Category | Decision |
|---|---|
| Skill names | All 36 use two-word verb-noun pattern (Uncle Bob + PMBOK vocabulary) |
| GitHub issue creation | Removed from all skills. Output is local .md files. |
| `gh` for PRs and repo ops | Kept. CONVENTIONS.md enforces its use. |
| superpowers behavior shaping | Kept verbatim where superpowers content is used. |
| Uncle Bob naming | Applied to all 29 skill names. |
| Domain-specific skills | Dropped (scaffold-exercises, obsidian-vault, migrate-to-shoehorn). |
| Test skill | Dropped. |
| `compress-tokens` → `terse-mode` | Renamed and repositioned as a fallback utility, not a strategy. Token discipline comes from code shape, not terser prompts. |
| Review flow (solo dev) | `audit-code` (self-check) → `request-review` (dispatch fresh reviewer *agent*) → `respond-review` (act on findings). No human reviewer assumed. |
| Alta coesão | No skills merged except craft-skill (write-a-skill + writing-skills are the same thing). |
