# Target Architecture — the migration's north-star reference

<!-- story: e53s04 -->

**Story:** e53s04. This document routes to two sources so every later migration epic
(e54–e59) can cite one place instead of re-deriving the target shape from scratch. It
is a **router, not a restatement** — the same discipline established throughout the
wayfinder session that produced §2 below. Follow the links for full detail; nothing
here should be treated as the primary source.

## 1. Overall methodology target — bigspec's constitution + architecture

**Source:** [`bigspec`](https://github.com/danielvm-git/bigspec) (sibling repo,
`/Users/danielvm/Developer/bigspec` locally), commit `4fc24c8` (2026-07-06),
`constitution.md` (139 lines) + `docs/architecture.md` (326 lines).

bigspec is the reborn, greenfield redesign of bigpowers' own methodology — "which of
the current core ideas survive contact with a blank page." It is not itself the
migration target (bigpowers is not becoming bigspec), but its constitution is the
methodology's clearest current statement of *why* each doctrine exists, and several
of e54–e59's decisions (skill reclassification, evals-over-compliance) directly mirror
verdicts bigspec already reached.

### 1.1 The 11 building blocks (B0–B10) + Capstone

Constitution Part I lays these in **dependency order** — each assumes the ones above
it exist:

| Block | Establishes | One-line rule |
|---|---|---|
| **B0** Token/Context Substrate | Everything is token-budget-aware | Progressive disclosure; no filler; deep modules over chatty ones |
| **B1** Agent-Grade Craftsmanship | The code floor, re-ranked for agents | 4–20 line functions; files < 300 lines; grep-able symbols (< 5 hits); errors carry a remediation hint |
| **B2** Think-First Behavior | The cognitive floor | Surface assumptions before coding; ship the minimum; edits are surgical |
| **B3** The Skill Primitive | A skill is *only* a procedure | Rules live in the constitution; deterministic ops live in the kernel; every skill writes `handoff.next_skill` |
| **B4** Spec-as-Contract | The spec, not chat history, is the source of truth | Countable-story format; acceptance criteria map to runnable `verify:` commands |
| **B5** Risk-Tiered Verification | Proof proportionate to risk | P0–P3 tiers set at plan time; verification depth follows the tier |
| **B6** Gates & Hard-Stops | Forward progress blocks until conditions are met | Risk-scaled, never gate fatigue; fresh-subagent review; two-stage gate before merge |
| **B7** Context Isolation | Fresh-context subagents, not a bigger prompt | Heavy work runs isolated; `handoff.next_skill` lets any interruption resume |
| **B8** Self-Describing Artifacts | Every generated file is an OKF bundle | One envelope, one validator; `_LATEST` is abolished — git versions, freezes |
| **B9** Effort Accounting | BCP is counted from the spec, never hand-stamped | Story-level only; every count carries `calibration_id` provenance |
| **B10** The Synthesis | One fractal loop across project/epic/story scope | Frame → Specify → Plan → Build → Prove → ship |
| **★ Capstone** Outcome Evals | Proof is *task success*, not self-compliance | With-skill vs without-skill pass@k delta; **replaces the legacy 94% Gherkin gate** |

Full text: [`constitution.md`](https://github.com/danielvm-git/bigspec/blob/main/constitution.md).

### 1.2 Why this matters for e54–e59

- **e58 (evals-over-compliance)** is bigspec's Capstone block already reached and
  reasoned through — "*Replaces the legacy 94% Gherkin self-compliance gate*"
  (constitution §Capstone). e53s03's `GOLDEN-COMPLIANCE-DEPENDENCY.md` maps exactly
  what bigpowers' own equivalent gate touches before e58 attempts the same move.
- **e56 (skill reclassification)** mirrors bigspec's primitive-on-trial verdict:
  *"'Skill' as the unit… KEEP but purify… a skill is only a procedure. Rules move to
  the constitution; deterministic tools move to the kernel."* (architecture.md §1).
  bigpowers' tombstone-alias mechanism (e53s02) is the transition tool for exactly
  this kind of reclassification.
- **Risk tiers (B5)** are already load-bearing in bigpowers today (`verify-work`'s
  P0–P3 depth scaling) — bigspec confirms this survives the redesign unchanged.
- **BCP (B9)** stays the primary sizing unit in both — this migration does not touch
  BCP methodology.

See [`docs/architecture.md`](https://github.com/danielvm-git/bigspec/blob/main/docs/architecture.md)
§1 ("The primitives, on trial") for the full survivor/drop/replace verdict table
against every current bigpowers mechanism, and §13 for the block-to-feature mapping.

## 2. Documentation architecture — the wayfinder session's resolution

**Source:** `specs/wayfinder/doc-templates/tickets/T6-doc-information-architecture.md`
(this repo), a closed HITL grilling ticket, plus its later AMENDMENT.

### 2.1 The 3-wave model (adopted from `big-docs`, amended)

| Wave | Scope | Renders via |
|---|---|---|
| **Wave 1 — GitHub-native** | Repo root + `.github/`: README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, issue/PR templates, CI | GitHub's own UI (repo homepage, Community tab, issue/PR forms) — a genuinely separate rendering surface, not a gap |
| **Wave 2 — GoodDocs** (`docs/`) | Flat TGDP pack folders: concept, how-to, reference, tutorial, glossary, changelog, release-notes, style-guide, troubleshooting, user-personas, readme, images. Also owns `AGENTS.md`/`CLAUDE.md`/`CONVENTIONS.md` | 1:1 onto the docs site, zero transform |
| **Wave 3 — Specs** | Machine-parsed project state and history | **Amended** — see §2.2, no longer a sibling of `docs/` |

**Render split within Wave 3:** narrative-OKF (ADR, story, bug, audit report — markdown
prose body) renders 1:1 as a page, zero transform. Data-OKF (metrics,
execution-status, cycle-times — structured YAML, no prose) is not a page; it feeds a
small fixed set of generic dashboard views queried by `okf_kind` — replacing the
`visual-dashboard` skill and local `dashboard/` app entirely.

### 2.2 The specs/ → docs/ dissolution decision (AMENDMENT, supersedes the sibling model)

**REVERSAL, user-confirmed:** `big-docs`' 3-wave model has `docs/` and `specs/` as
*siblings*. That is overturned for bigpowers' own future target.

1. **`docs/` becomes the single documentation root. `specs/` dissolves into it.**
   Reasoning: management information (scope, roadmap, risk, status, metrics) *is*
   project documentation (PMBOK project documents) → all documentation lives in
   `docs/` → no separate `specs/` folder is needed. The ex-`specs/` content becomes
   `docs/project/`.
2. **Runtime state moves to `docs/project/status/`** (`state.yaml`,
   `execution-status.yaml`). A hidden `.bigpowers/` root was considered and rejected —
   state stays inside the docs root.
3. **Payoff:** one set of markdown files serves both consumers — agents read the raw
   repo files, humans read the same files rendered on the docs site. No sync step, no
   mirror.
4. **Known migration cost (accepted, not a blocker):** every bigpowers script parses
   `specs/…` paths today. This dissolution is a real path migration, to be sequenced
   in a future epic — **not** something e53–e59 perform. This document records the
   target; it does not schedule the cutover.

**Consequence for `big-docs` itself:** its DESIGN.md and layout invariants need a
matching amendment (Wave 3 becomes a subtree of Wave 2's folder, not a sibling) —
tracked as a follow-up against `big-docs`, not against this repo.

**Consequence for wiki:** GitHub's Wiki feature is not used at all (separate
`repo.wiki.git`, no PR review, guaranteed drift, and it would be a parallel mirror).
The `maintain-wiki` INGEST/LINT mechanism is kept — it implements the llm-wiki
bookkeeping pattern (`index.md` catalog + `log.md` append-only journal) entirely
inside `docs/`, rendered via Pages, no separate platform.

Full ticket (including round-by-round resolution history and the diagram artifact):
[`specs/wayfinder/doc-templates/tickets/T6-doc-information-architecture.md`](../specs/wayfinder/doc-templates/tickets/T6-doc-information-architecture.md).

## 3. Adopted document templates — the target shape for every document type

**Source:** `specs/wayfinder/doc-templates/templates/` (this repo) — one
philosophy-tied, OKF-valid template per document kind the bigpowers-solo-core
generates (ADR, epic, story, tasks, glossary, cockpit-state, execution-status,
release-notes, security-advisory, and others). Consult that directory directly for
the current set — **this document deliberately does not enumerate or count them**,
since the set grows as `specs/wayfinder/doc-templates/tickets/` resolves more
template-collision tickets (T-series), and a hardcoded count here would drift out of
date on the next ticket close.

**Governing rule (from the templates' own `MAP.md`):** one template format per
document — narrative content renders directly as the site page (zero transform);
data content feeds a small, fixed set of generic dashboard views. `acps-workflow` is
reference material for these templates, never a template target itself (T4 ruling #3).

**How later epics should use this:** when a migration story needs to know "what shape
should this document take," check `specs/wayfinder/doc-templates/templates/` for an
existing template for that `okf_kind` before inventing a new shape. If none exists,
that's a signal to open a new wayfinder ticket, not to freelance a format.

## 4. What this document is not

Per task 4's own discipline: this is a router. It does not restate bigspec's
constitution or architecture.md content beyond the block-name summary table in §1.1
(needed for at-a-glance scanning); it does not restate T6's full grilling history
beyond the decision itself; it does not enumerate or duplicate the template
directory's contents. Every claim above carries a source link — follow it for the
authoritative text.
