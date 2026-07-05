# Constitution — bigpowers (reborn)

> **Status:** v0.1 draft — the single source of *rules* for a reborn bigpowers repo.
> **Version:** `1.0.0` (SemVer). Bumped by the ADR that amends this file. Every skill declares `constitution_version` in its frontmatter to declare compatibility.
> **Authority:** This file is the only place principles are stated. Skills, kernel, and scaffold *reference* it; they never restate it. If a rule appears in two files, this one wins and the other is a bug.
> **Meta-rule (from OKF):** gates check **structure and provenance, never a specific value.** A rule you can only verify by hard-coding a magic number is a rule in the wrong place.
> **Amendment:** changing any block below requires (1) an ADR in `specs/adr/` documenting the rationale, (2) a passing `constitution-lint`, and (3) a SemVer bump of the `constitution_version` frontmatter field. The amendment ADR must state the old version and the new version.
> **Reborn doc set:** [`REBORN-DOC-INDEX.md`](REBORN-DOC-INDEX.md) · [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) · [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md)

---

## Part I — The Foundation (11 building blocks, in construction order)

These are laid in dependency order: each block assumes the ones above it exist. This is *not* chronological — it is the order in which the foundation is poured.

### B0 · Token/Context Substrate
Everything in this repo is authored under a token budget. Content is written to be *consumed linearly by a machine*, not skimmed.
- **Rules:** progressive disclosure (frontmatter → summary → detail); no filler or restated code; one-line runnable `verify:` commands; deep modules over chatty ones.
- **Provenance:** Context Engineering — Write / Select / Compress / Isolate.

### B1 · Agent-Grade Craftsmanship
The code floor, re-ranked for agents. SRP and small functions are the *unit of implementation*; deep modules are the *unit of abstraction*; grep-ability and remediation are *first-class*.
- **Rules:** functions do one thing, 4–20 lines; files < 300 lines; deep modules (simple interface, hidden complexity); public symbols unique enough that `grep` returns < 5 results; errors carry the offending value + a remediation hint.
- **Provenance:** Uncle Bob (Clean Code) → Ousterhout (deep modules) → Akita (Clean Code for AI Agents).

### B2 · Think-First Behavior
The agent's cognitive floor. Understand before acting; act minimally.
- **Rules:** surface assumptions before writing code; present multiple readings of an ambiguous request; ship the minimum viable implementation; edits are surgical (touch only what the task requires); loop until behavioral correctness is *verified*, not assumed.
- **Provenance:** Karpathy; extended-thinking / reasoning patterns.

### B3 · The Skill Primitive
A skill is a *procedure* — a repeatable, verb-noun workflow. Nothing else is a skill. Rules live in this constitution; deterministic operations live in the kernel.
- **Rules:** verb-noun kebab-case names (a public API — never renamed, only aliased); zoom-out before editing (know the callers); every skill declares `effort`, `spawn`, `risk`, `movement` (`frame | specify | plan | build | prove | sustain`), and a **behavioral** `verify:` that asserts an artifact, never `test -f SKILL.md`; the orchestrator dispatches by `(movement, current cockpit state)`, not by hard-coded chain; every skill writes `handoff.next_skill` to the cockpit as its last action before returning — a skill that finishes without a `next_skill` is incomplete by definition.
- **Provenance:** Pocock (Agent Skills); domain probes.

### B4 · Spec-as-Contract
The durable, testable spec is the source of truth — not the chat history, not the code. Code is the last-mile output; intent is the source.
- **Rules:** every epic has a spec with scope, ubiquitous-language glossary, and Gherkin acceptance criteria; the spec MUST use the structured countable-story format; acceptance criteria map explicitly to runnable verification commands in the execution ledger; the spec serves as the direct input to the story→BCP pipeline; the spec survives code regeneration; the story body follows a structured format designed for unambiguous input to the counter (complete coverage, explicit acceptance criteria tied to Gherkin `Scenario:` blocks, no pre-partitioning into dimensions — the counter's Element Router owns that); the story is the bridge between intent (B4) and accounting (B9); every acceptance criterion is a verifiable assertion with a runnable `verify:` command — no tautological checks, no self-reported "done".
- **Provenance:** Wasowski (SDD + BDD); Spec-Kit (constitution + executable intent). See [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md) §3 for the M0 story contract.

### B5 · Risk-Tiered Verification
Proof is *proportionate to risk*. Trivial work takes the fast lane; critical work takes the full gauntlet. (See Part II for the tiers.)
- **Rules:** every story is tagged P0–P3 at plan time; verification depth follows the tier; tests obey F.I.R.S.T and assert behavior through public APIs; non-functional requirements (security, performance) are gates for P0/P1, not afterthoughts.
- **Provenance:** BMAD TEA (P0–P3 risk-based test depth, NFR gates); TDD / F.I.R.S.T; STRIDE.

### B6 · Gates & Hard-Stops
Forward progress blocks until conditions are met. Gates are enforced, not advisory — but they are *risk-scaled*, so they never become fatigue.
- **Rules:** no code before the design is approved; detect and name "red-flag" rationalizations ("too simple to plan", "I'll test later"); independent reviews run in a **fresh subagent context**; a two-stage review gate (self-audit → external review) precedes merge.
- **Provenance:** Superpowers (hard gates, red flags); the four gate types (Confirm / Quality / Risk / Completeness).

### B7 · Context Isolation
Context rot is the primary failure mode of agentic work. The structural fix is fresh-context subagents with file-based handoff — not a bigger prompt.
- **Rules:** heavy work (`effort: heavy`, `spawn: subagent`) runs in a fresh context and returns only its result; the orchestrator stays lean; `handoff.next_skill` in the cockpit lets any interruption resume exactly where it stopped.
- **Provenance:** GSD (context-rot thesis, fresh-context subagents, effort budgeting).

### B8 · Self-Describing Artifacts (OKF is universal)
**Every generated file** — spec, story, epic, cockpit, report, metric — is an OKF bundle. Not a subset; all of them. One envelope, one validator.
- **Rules:** each artifact carries YAML frontmatter with `okf_kind`, `okf_version`, and provenance (generator, source, commit range); `validate-okf` is the single kind-aware gate for the whole `specs/` tree; validators **gate on structure and provenance, never on a value**; the cockpit schema is a versioned contract from day 0; body templates live in the kernel `templates/`, one per kind, so a new document type is a template + validator entry, never a skill edit.
- **`_LATEST` is abolished.** Git versions and freezes; the canonical path is latest; `supersedes`/`generated_at`/`commit_range` make "latest" a query, not a filename.
- **Provenance:** OKF — Open Knowledge Format. Envelope and M0 kinds: [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md).

### B9 · Effort Accounting (BCP — measured, not guessed)
One sizing unit runs the roadmap: it answers "how much effort is still left to finish?" and "how big is this new epic?" BCP is a **sum of per-dimension element sizes**, so it is *counted from the spec*, never hand-stamped as a gestalt.
- **Rules:** the `story` bundle is the *input* (structured for coverage and clarity — it does **not** pre-partition elements; the Element Router owns that); a native **`count-bcp`** skill (or kernel module) implements the Element Router and BCP-Plus decision tables locally — it consumes the validated `story` OKF bundle, uses the `glossary` knowledge bundle as domain ground truth, and emits a derived **`bcp-count`** OKF bundle (`elements/`, `dimensions/`, `total_bcp`, `calibration_id`, `confidence_verdict`); stories carry **no gestalt `SIZE` field**; every `bcp-count` is an OKF bundle (see B8) — gate on `okf_kind` and structure, never the BCP number; every story that feeds a count must pass `validate-okf` first; every BCP is gated on `calibration_id`, never on the number, and **velocity series segment by `calibration_id`** (a chart mixing calibrations is a silent lie); BCP lives at the **story level only** (task-level `[BCP N]` is prohibited); `epic` sums its stories' `total_bcp`.
- **Three native counting contracts:** (1) the **Element Router** owns dimension classification — the story is input, never pre-partitioned; (2) the **glossary** knowledge bundle is domain ground truth (entities → dims 6/7, roles → dim 5, NFR baselines → dims 11–13); (3) **`calibration_id`** provenance ties every count to a decision-table version — velocity series segment by it; mixed-calibration charts are prohibited.
- **Provenance:** BCP — Business Complexity Points (CI&T / Itaú); BCP-Plus 13-dimension methodology. Counting rules derive from the former `big-counter` ADR specs (spec-only reference — **not** an external executable dependency).

### B10 · The Synthesis
The blocks above are principles; this repo turns them into one executable discipline: a single fractal loop, one constitution, hard gates scaled by risk.
- **Movements:** **Frame** — understand the problem and existing context; **Specify** — turn intent into a durable, testable spec; **Plan** — decompose, risk-tier (P0–P3), estimate (BCP), order; **Build** — TDD vertical slices in isolated worktrees; **Prove** — verify by the risk tier assigned in Plan, then ship.
- **Rules:** the loop (Frame → Specify → Plan → Build → Prove → ship) runs identically at project, epic, and story scope; **every skill maps to exactly one movement** (see B3); the spec is the invariant across every movement; the constitution is one file; semantic-release derives version truth from Conventional Commits.
- **Provenance:** BMAD (document lifecycle) + GSD (execution framework), synthesized. Full architecture: [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) §4.

### ★ Capstone · Outcome Evals
The foundation proves it *produces better software* — not that it obeys its own philosophy.
- **Rules:** each skill ships an eval case; the headline proof is a positive **with-skill vs without-skill** delta (pass@k + token cost) on real tasks; a thin `constitution-lint` keeps structural invariants, but self-compliance is **not** the quality gate.
- **Provenance:** anthropic/skills eval methodology. *Replaces the legacy 94% Gherkin self-compliance gate.*

---

## Part II — Risk Tiers (the fast lane vs the full lane)

Set at plan time; picks the verification depth and the gate lane.

| Tier | Meaning | Verification depth | Lane |
|---|---|---|---|
| **P0** | Critical (auth, money, data loss, security) | full multi-phase UAT + NFR gates + security scan + fresh-subagent review | full |
| **P1** | High | build + test + lint + step-by-step UAT + review | full |
| **P2** | Medium | smoke + typecheck + lint | full (light) |
| **P3** | Low / trivial data-only | typecheck + lint; `quick-fix` allowed | fast |

The fast lane exists so gate discipline never becomes gate fatigue.

---

## Part III — Conventions (non-negotiable)

The concrete rules every change must satisfy. These make the repo pass its own craftsmanship features by construction.

- **Commits & versions:** Conventional Commits 1.0.0; SemVer 2.0.0; version truth comes from tags/semantic-release, never hand-edited.
- **Branches:** never work directly on `main`/`master`; feature branches in worktrees.
- **Size:** functions 4–20 lines; files < 300 lines (documented exceptions only, in a table with a split-candidate note).
- **Structure:** SRP per module; dependencies injected, not global; nesting ≤ 2 levels.
- **Types:** explicit typing at boundaries.
- **Comments:** explain WHY, not WHAT; no commented-out or dead code; complex logic carries a provenance link (ADR / commit).
- **Errors:** include the offending value, the expected shape, and a remediation hint.
- **Tests:** F.I.R.S.T; assert behavior through public APIs; boundary conditions exhaustively covered; the whole suite runs with a single command.
- **Verifiability:** every change is provable with one runnable command before it is marked done.

---

## Part IV — Gates (the four enforcement types)

| Gate | Blocks until | Used at |
|---|---|---|
| **Confirm** | user explicitly approves | end of Frame / Specify / Plan |
| **Risk** | story tagged P0–P3 | end of Plan (picks the lane) |
| **Quality** | risk-tier verification passes; review clean | end of Build / Prove |
| **Completeness** | adversarial gap-critic finds no BLOCKER | before merge |

A BLOCKER from the completeness critic aborts the merge; WARNING-level findings are advisory until calibration data (post-M4) justifies promoting them.

---

## Part V — What this constitution deliberately is *not*

- Not 34 reference documents. Provenance lives in one-line footnotes above; the ideas live here once.
- Not a self-compliance suite. Proof is outcome evals (Capstone), not "does the framework obey itself".
- Not an MCP dependency. State is plain files; an MCP surface is the *last* thing added, never a prerequisite.
- Not a skill count. Coverage of the loop is the metric, not headcount.
- Not an external counting tool dependency. BCP sizing is native (`count-bcp` skill or kernel module), implementing BCP-Plus specs locally — the former `big-counter` repo is a spec reference only.

---

*Provenance footnotes intentionally terse — each names the source; the full lineage narrative lives in a thin `docs/PRINCIPLES.md` in the new repo (see [`BIGPOWERS-REBORN.md`](BIGPOWERS-REBORN.md) §13.3). Amendments require an ADR. Gap report [`REBORN-CONSTITUTION-GAPS.md`](REBORN-CONSTITUTION-GAPS.md) applied 2026-07-04.*
