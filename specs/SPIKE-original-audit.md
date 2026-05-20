# bigpowers PLAN.md — Reference Audit

> Goal asserted in the prompt: deliver a "superpower-like" skill set for a **solo developer producing production-ready, TDD-driven software**, fusing Uncle Bob (Clean Code), Karpathy (LLM coding pitfalls), Matt Pocock (skills repo), obra/superpowers, and the user's own learnings.

## Verdict

The plan is **structurally sound and ~70% covered against the four named references**. Skill *naming*, *lifecycle arc*, *local-first discipline*, and *gh enforcement* are excellent. The plan delivers the *workflow* of superpowers and the *taxonomy* of Pocock cleanly. The principal weakness is on the **content of CONVENTIONS.md and the install artifacts**: they cite Uncle Bob loosely but omit the agent-era re-ranking from Akita and most of Karpathy's defensive rules. For a "production-ready TDD" tool, that is the gap that matters most — it is precisely the layer that turns a list of skills into a discipline the agent will follow on every tool call.

Bottom line: **approve the skill inventory and lifecycle as-is. Reject the current CONVENTIONS.md and install artifacts as insufficient — they need a rewrite that absorbs the akitaonrails 13-item re-rank and the Karpathy 4 principles verbatim.**

---

## Reference-by-reference coverage

### 1. obra/superpowers — covered ~95%

| superpowers skill | PLAN destination | Status |
|---|---|---|
| brainstorming | elaborate-spec | covered |
| using-git-worktrees | kickoff-branch | covered |
| writing-plans | plan-work | covered |
| subagent-driven-development | delegate-task | covered |
| executing-plans | execute-plan | covered |
| test-driven-development | develop-tdd (override) | covered |
| systematic-debugging | diagnose-root | covered |
| verification-before-completion | validate-fix | covered |
| requesting-code-review | audit-code | covered |
| receiving-code-review | respond-review | covered |
| dispatching-parallel-agents | dispatch-agents | covered |
| finishing-a-development-branch | release-branch | covered |
| writing-skills | craft-skill (merged) | covered |
| **using-superpowers** | — | **missing** (the bootstrap/intro skill — PLAN replaces with `survey-context` but does not document the substitution) |

Superpowers' four philosophy pillars (TDD, systematic-over-ad-hoc, complexity reduction, evidence-over-claims) — only the first two are echoed in CONVENTIONS.md. "Complexity reduction" and "evidence over claims" should be added by name.

### 2. mattpocock/skills — covered ~85%

| Pocock skill (README) | PLAN destination | Status |
|---|---|---|
| write-a-prd / to-prd | scope-work | covered (adapted: local .md) |
| prd-to-issues / to-issues | slice-tasks | covered (adapted) |
| grill-me | challenge-design | covered |
| tdd | develop-tdd (PLAN overrides with user's richer version) | covered |
| triage-issue | investigate-bug | covered |
| improve-codebase-architecture | deepen-architecture | covered |
| setup-pre-commit | hook-commits | covered |
| git-guardrails-claude-code | guard-git | covered |
| write-a-skill | craft-skill (merged with superpowers') | covered |
| **prototype** | — | **missing** — Pocock has a rapid-spike-before-TDD skill; PLAN's lifecycle forces TDD as the only mode of code creation and loses the "spike, throw away, then TDD properly" flow that solo devs need for unknown problem spaces |
| **diagnose** | partially via diagnose-root (superpowers) | unreconciled — PLAN chose superpowers' `systematic-debugging`, but Pocock has a distinct `diagnose` skill not referenced |
| **grill-with-docs** | — | **missing** — variant of grill-me that grounds challenges in actual library docs; useful for production work where wrong API assumptions are costly |

PLAN also cites these as Pocock sources (they exist in his `personal/`, `productivity/`, `misc/`, or `in-progress/` subtrees, not the main README): `zoom-out`, `domain-model`, `ubiquitous-language`, `request-refactor-plan`, `prepare-semantic-commit`, `qa`, `clean-my-room`, `caveman`, `edit-article`. These mappings are plausible but should be verified by URL when implementation begins.

### 3. akitaonrails Clean Code pra Agentes de IA — covered ~30% ❗

This is the **biggest gap**. The article is a 13-item re-rank of Clean Code's principles weighted for *agent* readers, plus 5 net-new agent-era practices. PLAN's CONVENTIONS.md addresses only the naming-and-comments slice. The other items are exactly the rules that make a TDD-with-agent loop production-grade.

| Akita item | In PLAN? | Where / Gap |
|---|---|---|
| 1. Small functions (4–20 lines) and small files (<500 lines) | **no** | not stated anywhere — critical for agent token economy |
| 2. SRP | partial | CONVENTIONS.md says "one function, one thing" — does not mention modules/classes |
| 3. Meaningful and unique (greppable) names | partial | naming rule applied to skill names, not to project code; the "grep returns <5 hits" heuristic is missing |
| 4. Comments with context and provenance | partial | CONVENTIONS.md says "comments explain WHY" — does **not** capture the agent-era inversion: *keep agent-written comments*, *write docstrings with intent + example*, *reference issue/commit SHAs* |
| 5. Explicit types (no `any`, no untyped) | partial | "Prefer typed over any-typed" — vague; needs hard "no `any`, no untyped function" wording |
| 6. DRY | covered | "No duplication. One place for every piece of knowledge." |
| 7. Tests the agent can run (F.I.R.S.T + headless + single command) | partial | `develop-tdd` skill exists; F.I.R.S.T is not codified; "tests run with a single command" rule missing |
| 8. Predictable directory structure | **no** | install artifacts have an "Architecture" section but no rule forbidding flat layouts / encouraging framework convention |
| 9. Dependency Injection / testability | **no** | absent — yet DI is the load-bearing refactor for any agent-driven codebase |
| 10. Avoid deep nesting (max 2 levels, early returns) | **no** | absent |
| 11. Errors with context (offending value + expected shape) | **no** | absent — yet this is what lets the agent debug from a stack trace |
| 12. Use default formatter, configure in pre-commit | partial | `hook-commits` exists as a skill; the *principle* "stop discussing style, accept the formatter" is not stated |
| 13. No obvious comments | covered | "Comments explain WHY. Never WHAT." |
| New: meta-doc files (CLAUDE.md/AGENTS.md/etc.) | covered | install artifacts |
| New: README with architecture | covered | README plan |
| New: structured (JSON) logging | **no** | absent |
| New: accessible observability commands | covered | Commands table in CLAUDE.md template |
| New: idempotent setup scripts | **no** | absent |
| New: defensive-code categories listed explicitly (rate limit, retry, breaker, fallback) | **no** | absent — Akita's closing paragraph: "the agent implements defensive code only when listed" |

### 4. multica-ai/andrej-karpathy-skills — covered ~80%

The four Karpathy principles map cleanly to AGENTS.md "Mandatory Behavior" and the Agent Rules in CLAUDE.md.

| Karpathy principle | PLAN location | Status |
|---|---|---|
| 1. Think Before Coding (state assumptions, present interpretations, push back, stop when confused) | AGENTS.md #1 + CLAUDE.md "One clarifying question beats a wrong assumption" + `challenge-design` skill | covered |
| 2. Simplicity First (minimum code, no speculative abstraction) | AGENTS.md #2 + CLAUDE.md "Write the minimum code that solves the stated problem" | covered |
| 3. Surgical Changes (touch only what you must) | CLAUDE.md "Never refactor, rename, or reorganize code outside the task scope" + AGENTS.md #3 | covered |
| 4. Goal-Driven Execution (define success criteria, loop until verified) | AGENTS.md #4 + `develop-tdd` + `validate-fix` | covered |
| Karpathy's "transform imperative → verifiable goal" recipe | **no** | `plan-work` should require every task to state `verify: <command>` — the Karpathy "Step → verify:" template should be in the skill's required output |

### 5. Uncle Bob / Clean Code (book) — covered ~50%

PLAN explicitly cites Chapter 2. The rest of the book is implicit at best.

| Chapter | Coverage |
|---|---|
| Ch 2 Meaningful Names | **strong** — explicitly applied to all 29 skill names |
| Ch 3 Functions (small, do one thing, single level of abstraction, descriptive names) | partial — "one thing" yes, size rules no |
| Ch 4 Comments | partial — WHY-not-WHAT yes, provenance no, docstring rules no |
| Ch 5 Formatting | absent |
| Ch 7 Error Handling (provide context with exceptions) | absent |
| Ch 9 Unit Tests (F.I.R.S.T) | not codified — only the TDD loop is referenced |
| Ch 10 Classes (cohesion, small) | partial — "alta coesão" stated as philosophy |
| Ch 12 Emergence (4 rules of simple design) | partial |
| Ch 14 Successive Refinement | implicit via `plan-refactor` |
| Ch 17 Smells and Heuristics | absent |
| **SOLID** | absent — only SRP implied |
| **Boy Scout Rule** | **covered** |

---

## Critical gaps to close before approving PLAN

The skills lifecycle is fine. The CONVENTIONS.md and install artifacts as currently drafted are **not** sufficient for a "production-ready TDD with agent" stack. Add the following blocks before execution.

### A. Replace CONVENTIONS.md "Code Quality" section

Current 6 bullets become a structured block matching Akita's template. Recommend adopting his 100-line template verbatim with light edits:

```
## Code Style
- Functions: 4–20 lines. Split if longer.
- Files: under 500 lines, ideally 200–300. Split by responsibility.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`, `Service`.
  Prefer names whose grep returns <5 hits in this codebase.
- Types: explicit. No `any`, no untyped public functions.
- No code duplication. Extract shared logic into a function/module.
- Early returns over nested ifs. Max 2 levels of indentation.
- Exception messages must include the offending value and expected shape.

## Comments
- Keep your own comments. Never strip them on refactor — they carry intent and provenance.
- Write WHY, not WHAT.
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because of a specific bug.

## Tests
- Tests run headless with a single command (recorded in CLAUDE.md).
- Every new function gets a test. Every bug fix gets a regression test.
- Mocks for external I/O are named fake classes, not inline stubs.
- Tests are F.I.R.S.T: Fast, Independent, Repeatable, Self-Validating, Timely.

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
```

### B. Add four missing skills

| New skill | Verb-noun (Uncle-Bob compliant) | Why |
|---|---|---|
| Pocock `prototype` | `spike-prototype` | Solo devs need throw-away exploration before TDD. PLAN forces TDD-only, which kills speed on unknown domains. |
| Akita "F.I.R.S.T tests" | `enforce-first` | Codify F.I.R.S.T as a separate skill the agent loads when writing tests; `develop-tdd` is the loop, this is the rubric. |
| Akita "structured logging + observability commands + idempotent setup" | `wire-observability` | Production-readiness lever: gives the agent a feedback loop in any new project. |
| Karpathy "verifiable goals" | `define-success` | Skill that converts an imperative task into "step → verify: <command>" pairs. `plan-work` should require its output. |

### C. Update `plan-work` to enforce Karpathy's verification template

Every task in a PLAN.md must be:
```
N. <Step> → verify: <runnable check>
```
That's the Karpathy mechanic that lets the agent loop autonomously. Currently `plan-work` is described as "structured PLAN.md with checkpoints" — too vague.

### D. Rename and reconsider one skill

`compress-tokens` (caveman mode) does not earn its place for production-grade TDD. Akita's whole point is that token discipline comes from **code shape** (small functions, unique names, headless tests), not from **terser prompts**. Recommend either dropping `compress-tokens` or repositioning it as `terse-mode` with a warning that it's a fallback, not a strategy.

### E. Bootstrap skill correctness

`survey-context` is positioned as the entry point. Per superpowers convention, the actual bootstrap is `using-superpowers` — it introduces the skills system. PLAN folds that responsibility into `survey-context`, but `survey-context` is also doing context-mapping work. Recommend splitting into:
- `using-bigpowers` — pure skills-system introduction (one-time)
- `survey-context` — per-task context survey (every session)

---

## Moderate gaps

- **SOLID beyond SRP.** Liskov, ISP, DIP not addressed. For a production tool, the agent should be told to favor interfaces over concrete types (DIP) when applying DI.
- **Boy Scout Rule lives only in CONVENTIONS.md.** It deserves a one-line check in `audit-code` (skill output).
- **"Complexity reduction" and "evidence over claims"** — superpowers' two unused pillars — should appear in the philosophy section of README.md.
- **No skill for "writing meta-docs for new projects."** Akita's "writing CLAUDE.md is a new skill" insight is acknowledged via install artifacts but there is no `bigpowers` skill that helps the user *generate* a CLAUDE.md for a brand-new project. Recommend adding `seed-conventions`.

## Minor gaps

- Pocock `grill-with-docs` (variant of `grill-me` grounded in real library docs) is missing — useful when the agent might hallucinate an API.
- `commit-message` should reference the *defensive-code categories* the commit touches, per Akita's closing point — small wording change.
- `release-branch` does not mention coverage thresholds; Akita's empirical bar (≥80% overall, ≥95% on business logic) should appear as a recommendation, not a hard gate.

## What PLAN got right

- Naming discipline applied uniformly to all 29 skills is the best part of the plan and is the single highest-leverage Uncle Bob practice for agent ergonomics.
- Local-first (no gh issues from skills) is a real differentiator vs both superpowers and Pocock — and survives Akita's critique because local files are cheaper context than API round-trips.
- Override of superpowers' `tdd` with the user's vertical-slice version aligns with Akita: "TDD became a technical obligation, not a philosophy."
- AGENTS.md "Mandatory Behavior" 5-line block is essentially Karpathy's 4 principles rewritten — clean, dense, agent-readable.
- The PMBOK lifecycle arc gives the README a teaching narrative that neither superpowers nor Pocock has.

---

## Recommended order of edits to PLAN.md

1. Rewrite the CONVENTIONS.md section to match block A above. (highest leverage)
2. Add the four skills from block B to the skill inventory and the workflow arc.
3. Edit the `plan-work` description to require Karpathy verify-pairs (block C).
4. Add a "Verification" subsection under each skill in the README plan, showing the agent's expected evidence of completion (matches superpowers' "evidence over claims" pillar).
5. Bookkeeping: drop or rename `compress-tokens`; split `survey-context` and `using-bigpowers`; reconsider `diagnose-root` vs Pocock `diagnose`; verify the Pocock source URLs for the skills outside his README.
