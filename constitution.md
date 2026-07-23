# bigpowers Constitution

<!-- story: e55s02 -->

> **Status:** consolidated entry point for bigpowers' doctrine, built from a
> full audit of every current rule source
> (`specs/epics/e55-extract-constitution/e55s01-doctrine-mapping.md`).
>
> **Authority:** this file is where a reader starts. It does **not** yet
> replace `CLAUDE.md` or `CONVENTIONS.md` — both remain fully authoritative in
> their own right today. Each block below synthesizes what those files (and
> the supporting `docs/references/*.md` sources) currently say, with citations
> to the fuller text rather than a full copy of it, so this file doesn't
> become a second place the same rule can drift out of sync.
>
> This file has no `constitution_version` or amendment scheme — that
> compatibility-tracking mechanism is a later concern (e59, absorb-fresh-
> references), not something this story invents ahead of schedule.
>
> Structure follows bigspec's 11 blocks (B0–B10) plus a Capstone category, used
> here purely as an organizing skeleton (`specs/reborn-constitution.md` Part I),
> not as a source of content — every claim below is about what *this* repo's
> doctrine actually says today.

---

## B0 · Token/Context Substrate

Content is written to be consumed by an agent under a real token budget, not
skimmed by a human. Files stay under size caps so they fit a single context
window; skills load progressively (frontmatter → summary → detail) instead of
being read in full up front; `verify:` commands are one-line and runnable.

- 300-line file cap, `SKILL.md` size caps — `CONVENTIONS.md` §Code Style, `docs/PRINCIPLES.md` §5/§8
- Context Routing (load by glob, not the full doc tree) — `CLAUDE.md`
- Token Economy, high-density skill descriptions — `docs/PRINCIPLES.md` §5, `docs/references/akita.md`
- Full progressive-disclosure framework, `bts_map`/`bts_compress`/`sqz`/`rtk` tooling — `docs/references/context-engineering.md`
- `terse-mode` past ~20 turns — `CONVENTIONS.md` §Risk Tiers (`terse-when-heavy`)

## B1 · Agent-Grade Craftsmanship

The code floor: functions 4–20 lines, files under 300 lines, one responsibility
per module, names specific enough that `grep` returns under 5 hits, no
duplication, exceptions over error codes, dead code deleted not commented out,
Boy Scout Rule, Law of Demeter, error messages that carry a remediation hint.

- Full Code Style, Comments, Dependencies, Structure, Formatting, Logging sections — `CONVENTIONS.md`
- SRP, Boy Scout Rule, intention-revealing names — `docs/PRINCIPLES.md` §1
- Deep modules, information hiding — `docs/PRINCIPLES.md` §2, `docs/references/ousterhout.md`, `docs/references/pocock.md`
- Grep-ability, structured observability, remediation hints — `docs/PRINCIPLES.md` §5, `docs/references/akita.md`
- SOLID, DRY, refactoring catalog, seams for testability — `docs/references/sandi-metz.md`, `docs/references/fowler.md`, `docs/references/uncle-bob.md`, `docs/references/feathers.md`, `docs/references/pragmatic-programmer.md`, `docs/references/rich-hickey.md`
- Conventional Commits message mechanics — `docs/references/git-integration.md`

## B2 · Think-First Behavior

Understand before acting; act minimally. Assumptions get surfaced before code
is written, ambiguous requests get multiple readings named explicitly, and
edits stay surgical — touching only what the task requires.

- Session Start read order, "minimum code", "one clarifying question beats a wrong assumption" — `CLAUDE.md`
- Think First, Zoom-Out Strategy, Surgical Edits — `docs/PRINCIPLES.md` §3
- Zoom-out mandate, `define-success` hard gate, "we'll decide during code" red flag — `docs/references/orchestration.md`, `docs/references/workflow-steps.md`
- Tidy First?, tracer bullets, good-enough software — `docs/references/kent-beck.md`, `docs/references/pragmatic-programmer.md`
- System 1 vs System 2 thinking, model-escalation cost-benefit — `docs/references/thinking-models.md`
- Domain probes (`grill-me`), model-domain invariant grilling — `docs/references/domain-probes.md`, `docs/references/ddd.md`

## B3 · The Skill Primitive

A skill is a verb-noun procedure, not a class of code. Every critical-path
skill writes `handoff.next_skill` as its last action so work can resume
anywhere it stopped.

- Workflow Mandate: route work through bigpowers skills, never write code directly — `CLAUDE.md`, `CONVENTIONS.md` §Agent Workflow Mandates
- Skill Naming, Tombstone Aliases, next_skill signaling mandate — `CONVENTIONS.md`
- Skill-Based Architecture, zoom-out mandate — `docs/PRINCIPLES.md` §3
- `seed-conventions` bootstrap, `survey-context` phase mapping — `docs/references/agent-config-files-and-okf.md`, `docs/references/workflow-steps.md`

## B4 · Spec-as-Contract

The spec is the source of truth, not the chat history. `plan-work` produces
`verify:`-bearing tasks before any feature code is written; a story only
counts as done once `verify-work` confirms it against those criteria.

- `plan-work` before feature code, UAT sign-off mandate, delta-tag requirement — `CONVENTIONS.md` §Agent Workflow Mandates
- Intent/delivery/execution file ownership table — `CONVENTIONS.md` §specs/
- SDD, BDD/Gherkin as the link — `docs/PRINCIPLES.md` §4, `docs/references/wasowski.md`
- Ubiquitous Language, information-first design — `docs/references/pocock.md`, `docs/references/rich-hickey.md`
- Story maturity/INVEST gates, NFR Gate pattern, structured-spec pattern — `docs/references/bcp.md`, `docs/references/bcp-plus.md`, `docs/references/spec-kit.md`
- Bounded context, context mapping, `define-language` — `docs/references/ddd.md`

## B5 · Risk-Tiered Verification

Proof is proportionate to risk. Every story is tagged P0–P3 at plan time; that
tier picks how much verification it gets — full multi-phase UAT for P0, down
to typecheck-and-lint for P3.

- Full Risk Tiers (P0–P3) table, Tests (F.I.R.S.T) — `CONVENTIONS.md` §Risk Tiers, §Tests
- F.I.R.S.T Testing — `docs/PRINCIPLES.md` §1, `docs/references/kent-beck.md`, `docs/references/uncle-bob.md`, `docs/references/tdd.md`, `docs/references/wasowski.md` *(stated in at least 5 sources — a live duplication instance, not evidence of 5 distinct rules)*
- P0–P3 risk-based test-depth tables — `docs/references/bmad.md`, `docs/references/tea.md`
- Boundary conditions, public-interface-only testing (T4/T5/T8), ≥95% coverage, NFR Evidence Audit — `docs/references/tdd.md`, `docs/references/bmad.md`, `docs/references/tea.md`
- OKF validation gates on structure/provenance, never a value — `docs/references/okf.md`
- Slopcheck [OK]/[SUS]/[SLOP], supply-chain and security-audit checklists — `docs/references/security-threats.md`

## B6 · Gates & Hard-Stops

Forward progress blocks until conditions are met — Preflight and CI must be
green before any forward work, and any reproducible gate failure is a
discovered defect, not something to note and move past.

- Always Green / Shift Left, Discovered Defects fix-or-log ladder, banned dismissive phrases — `CONVENTIONS.md` §Always Green, §Discovered Defects
- Hard Gates — `docs/PRINCIPLES.md` §6
- Broken Windows, quality-score gate, review workflow gate — `docs/references/pragmatic-programmer.md`, `docs/references/code-review.md`
- Checkpoint state machine, safety checkpoints, never-auto-merge — `docs/references/checkpoints.md`, `docs/references/git-integration.md`
- 6-phase Confirm-gates, deviation-from-plan red flag, mode-scaled strictness — `docs/references/orchestration.md`, `docs/references/orchestration-modes.md`
- Full Traceability Gate pipeline (coverage matrix, blind-spot categories, PASS/CONCERNS/FAIL/WAIVED verdicts) — `docs/references/traceability-gate.md`
- Four gate types (Confirm/Quality/Safety/Transition) — `docs/references/gates.md`

**Today's proof mechanism, described honestly:** the actual gate that runs on
every `npm run compliance` invocation is a Gherkin-based self-compliance suite
with a 94% pass threshold (`docs/PRINCIPLES.md` §6/§7, `CLAUDE.md` §Commands,
`docs/references/gates.md`). This is what genuinely exists and gates merges
today. `specs/reborn-constitution.md`'s Capstone block describes a *target*
state where outcome evals (with-skill vs without-skill delta) replace this
threshold — that replacement is **e58's job (evals-over-compliance), not yet
built**. The 94% Gherkin gate is not deprecated; it is the live mechanism
until e58 ships something to replace it with.

## B7 · Context Isolation

Context rot is the primary failure mode of long agentic sessions. The fix is
fresh-context subagents with file-based handoff, not a bigger prompt —
`state.yaml` tracks precise session state so any interruption can resume
exactly where it stopped.

- Token Management (Write/Select/Compress/Isolate, effort classification) — `CLAUDE.md`
- Session Governance via `state.yaml`/`release-plan.yaml` — `docs/PRINCIPLES.md` §6
- Model-escalation to fresh-context subagents — `docs/references/thinking-models.md`
- Handoff-contract principle, `dispatch-agents`/`delegate-task` scoped file access, `kickoff-branch` worktree isolation, `agent-locks.yaml` concurrency — `docs/references/context-engineering.md`
- `state.yaml` tracking, resume-via-survey-context, stale-lock detection — `docs/references/gsd.md`, `docs/references/semantic-context-bridge.md`

## B8 · Self-Describing Artifacts

Every planning artifact has exactly one owning file — `specs/execution-status.yaml`
is the sole source of truth for story status, `specs/release-plan.yaml` for
epic ordering, and so on. Generated artifacts (`.cursor/`, `.gemini/`,
`.pi/`, `website/`) are never hand-edited; their `SKILL.md` sources are.

- Full specs/ ownership model, Documentation Responsibilities table, Generated artifact targets, docs/references SSOT Sync — `CONVENTIONS.md` §specs/
- Never-edit-generated-artifacts, single-source-of-truth `SKILL.md` — `CLAUDE.md`
- OKF bundle frontmatter (`okf_kind`/`okf_version`/provenance), kind-aware validation, "gate on pipeline not value" — `docs/references/okf.md`
- CLAUDE.md/AGENTS.md dual-pattern — `docs/references/agent-config-files-and-okf.md`
- Skill graph, OKF wiki bundle, targets-registry as the single Integration Registry — `docs/references/semantic-context-bridge.md`, `docs/references/targets-registry.md`

*Note: `docs/references/okf.md` describes OKF-bundle conformance as achievable
"if all `SKILL.md` files add frontmatter fields" — that's a conditional, not a
claim that every generated file already carries this envelope today. Making
that universal across the whole `specs/` tree is e57's job (adopt-okf-envelope),
not yet built.*

## B9 · Effort Accounting (BCP)

BCP (Business Complexity Points) sizes a story before it's built, from a
6-step method summing per-element Fibonacci scores. It lives at the story
level only — there is no per-task `[BCP N]` annotation in the current method.

- Full BCP accounting mandate, Timestamp mandate, story-level-only rule — `CONVENTIONS.md` §BCP accounting mandate, §Timestamp mandate
- `effort:` frontmatter (light/standard/heavy) — `docs/references/context-engineering.md`, `docs/references/model-profiles.md`
- 6-step sizing method, size bands, velocity tracking — `docs/references/bcp.md`
- BCP-Plus 13-dimension framework — `docs/references/bcp-plus.md`

*Note: some older docs (`docs/references/workflow-artifacts.md`,
`docs/references/orchestration.md`) still reference a per-task `[BCP N]` tag
convention that `CONVENTIONS.md` has since superseded — a live drift instance
this consolidation surfaces rather than resolves. Resolving it is a
`docs/references` sync task, not this story's job.*

## B10 · The Synthesis

The 6-phase core loop — Discover → Elaborate → Plan → Build → Verify →
Release — runs at project, epic, and story scope alike. *Sustain* is a
session-flow state, not a seventh lifecycle phase.

- 6-Phase Lifecycle, Hard Gates, 94% threshold — `docs/PRINCIPLES.md` §6
- Same 6-phase loop, `orchestrate-project` phase sequencing — `docs/references/orchestration.md`, `docs/references/workflow-steps.md`
- BMAD's Discover→Elaborate→Plan→Build→Sustain arc, TEA's workflows, SDD lifecycle integration — `docs/references/bmad.md`, `docs/references/tea.md`, `docs/references/wasowski.md`

## ★ Capstone · Outcome Evals

The foundation should prove it produces better software, not just that it
follows its own rules. Bigpowers doesn't have this yet in the target form —
what exists today is described honestly in B6 above: a 94% Gherkin
self-compliance gate. `reborn-constitution.md`'s Capstone block names the
target (with-skill vs without-skill delta, pass@k + token cost) as what
**e58 (evals-over-compliance)** is expected to build. Until then:

- Request-review checklist / quality-score gate as today's closest analog — `docs/references/code-review.md`
- Human-in-the-loop UAT mandate after every story — `docs/references/spec-kit.md`
- `run-evals` + regression UAT phase, `specs/EVALS-<feature>.md` — `docs/references/workflow-steps.md`, `docs/references/workflow-artifacts.md`

---

## What this file deliberately doesn't do (yet)

- **No content migration.** Full rule text stays in `CONVENTIONS.md`,
  `CLAUDE.md`, `docs/PRINCIPLES.md`, and `docs/references/*.md`. Moving
  rule-classified content in is e56's job (reclassify-catalog) — this file
  only builds the destination structure.
- **No cross-references back from `CLAUDE.md`/`CONVENTIONS.md` yet.** Those
  files don't point here yet; that's e55s03.
- **No amendment/versioning scheme.** `constitution_version`, SemVer bumps,
  and ADR-gated amendments are e59's job (absorb-fresh-references).
- **No universal OKF envelope claim.** Not every generated file in this repo
  carries `okf_kind`/`okf_version` frontmatter yet — that's e57's job
  (adopt-okf-envelope).
- **No `count-bcp` skill.** BCP sizing today is the 6-step method in
  `docs/references/bcp.md`, applied by hand during `plan-work`/`plan-release` —
  not a dedicated skill or kernel module.
