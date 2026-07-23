# Doctrine Mapping — e55s01

<!-- story: e55s01 -->

Maps every rule stated in bigpowers' current doctrine sources to exactly one of
bigspec's 11 constitution blocks (B0–B10) or Capstone. Block **definitions** are
taken from `specs/reborn-constitution.md` Part I as a **structural taxonomy
reference only** — this document maps what bigpowers' doctrine *actually says
today*; it does not adopt any of that draft's content-level claims (which target a
hypothetical future rewrite, not this repo).

## Manifest — 49 source files audited

`CLAUDE.md`, `CONVENTIONS.md`, `docs/PRINCIPLES.md`, and all 46
`docs/references/*.md` files: `accelerate.md`, `agent-config-files-and-okf.md`,
`akita.md`, `bcp-plus.md`, `bcp.md`, `bigpowers-mcp.md`, `bmad.md`,
`checkpoints.md`, `code-review.md`, `context-engineering.md`, `ddd.md`,
`domain-probes.md`, `e33-abandoned.md`, `e36-abandoned.md`, `feathers.md`,
`fowler.md`, `gates.md`, `git-integration.md`, `gsd.md`, `karpathy.md`,
`kent-beck.md`, `model-profiles.md`, `okf.md`, `orchestration-modes.md`,
`orchestration-state.md`, `orchestration.md`, `ousterhout.md`, `pocock.md`,
`pragmatic-programmer.md`, `rich-hickey.md`, `sandi-metz.md`,
`security-threats.md`, `semantic-context-bridge.md`, `spec-kit.md`,
`superpowers.md`, `targets-registry.md`, `tdd.md`, `tea.md`,
`thinking-models.md`, `traceability-gate.md`, `uncle-bob.md`,
`verification-patterns-extended.md`, `verification-patterns.md`, `wasowski.md`,
`workflow-artifacts.md`, `workflow-steps.md`.

---

## B0 · Token/Context Substrate

- 300-line file cap and CLAUDE.md's `SKILL.md` size caps exist so content fits a
  single agent context window — source: `CONVENTIONS.md`, `docs/PRINCIPLES.md` §5/§8
- `terse-when-heavy` (P3): switch to `terse-mode` past ~20 turns — source: `CONVENTIONS.md`
- Context Routing table (load by glob, not full doc tree up front) — source: `CLAUDE.md`
- Full B0 framework — progressive disclosure (frontmatter→summary→detail), one-line
  `verify:` commands, `bts_map`/`bts_compress`/`sqz`/`rtk`/`terse-mode` token-savings
  tooling, greedy-linear-consumption writing model — source: `context-engineering.md`
- Token Economy / eliminating filler for the context window; high-density skill
  descriptions to minimize unnecessary loading — source: `docs/PRINCIPLES.md` §5/§8, `akita.md`
- CLAUDE.md tree-walk vs. single-root AGENTS.md progressive-disclosure patterns —
  source: `agent-config-files-and-okf.md`
- Tiered knowledge fragments (Core/Extended/Specialized) — source: `tea.md`
- Prefer simplicity/minimal code for token efficiency — source: `karpathy.md`
- `sqz`/`rtk`/bts-toolchain token-savings commands — source: `CLAUDE.md` (Token
  Management, bts toolchain, sqz, RTK sections)

## B1 · Agent-Grade Craftsmanship

- Full Code Style section: functions 4–20 lines, files <300 lines, SRP, grep<5
  names, explicit types, no duplication, early returns/max 2 indent, positive
  conditionals (G29), Stepdown Rule (G34), side-effect-revealing names (N7), no
  magic strings/numbers (G25), named boolean predicates (G28), exceptions over
  error codes, dead-code removal (G9/F4), Boy Scout Rule, Law of Demeter,
  remediation-hint error messages, SOLID/DIP — source: `CONVENTIONS.md` §Code Style
- Comments (WHY not WHAT, provenance links, no commented-out code C5),
  Dependencies (constructor injection, thin wrapper over 3rd-party), Structure
  (framework convention, small focused modules), Formatting (language-default
  formatter), Logging (structured JSON) — source: `CONVENTIONS.md`
- SRP, Boy Scout Rule, F.I.R.S.T, intention-revealing names (classical
  craftsmanship foundation) — source: `docs/PRINCIPLES.md` §1
- Deep modules, information hiding, define-errors-out-of-existence — source:
  `docs/PRINCIPLES.md` §2, `ousterhout.md`, `pocock.md`
- Grep-ability (<5 results), structured observability/JSON logging, remediation
  hints — source: `docs/PRINCIPLES.md` §5, `akita.md`
- Metz Rules (size limits), refactoring catalog + code-smell taxonomy, DRY,
  orthogonality, simple-vs-easy/no-complecting, functions-over-objects, SRP/OCP/ISP/DIP,
  small functions, seams for testability, G1–G30 clean-code heuristics —
  source: `sandi-metz.md`, `fowler.md`, `pragmatic-programmer.md`, `rich-hickey.md`,
  `uncle-bob.md`, `feathers.md`, `code-review.md`
- Conventional Commits message mechanics (type/scope/subject/body/squash-merge) —
  source: `git-integration.md`, `workflow-steps.md`
- Function-size/SRP/no-commented-code/no-debug-statements enforcement,
  RED-GREEN-REFACTOR per BCP task — source: `workflow-steps.md`
- Sizers receive only routed elements (no raw re-reading), specificity
  precedence in routing — source: `bcp-plus.md`
- One-assertion tests, reusable verification scripts, config keys must be used
  not just declared — source: `tdd.md`, `verification-patterns-extended.md`
- Context-boundary violation detection informs refactor planning — source: `ddd.md`

## B2 · Think-First Behavior

- Session Start sequence (read CLAUDE.md → CONVENTIONS.md → state.yaml →
  release-plan.yaml before acting) — source: `CLAUDE.md`
- "Write the minimum code", "one clarifying question beats a wrong assumption",
  read specs/CONVENTIONS before writing code — source: `CLAUDE.md` (Agent Rules)
- Think First (surface assumptions before code), Zoom-Out Strategy, Surgical
  Edits — source: `docs/PRINCIPLES.md` §3
- Surgical changes only, Loop-until-correct — source: `karpathy.md`
- Tidy First? (structural before behavioral changes), coherent small steps —
  source: `kent-beck.md`
- Tracer bullets, Stone Soup, good-enough software, prototype-to-learn —
  source: `pragmatic-programmer.md`
- Zoom-out before editing, Ubiquitous Language extraction — source: `pocock.md`
- System 1 vs System 2 thinking, cost-benefit model escalation — source: `thinking-models.md`
- Legacy Code Change Algorithm (identify → find test points → break deps →
  characterize → change → refactor) — source: `feathers.md`
- Discover/Elaborate phase discipline: understand fully before proposing, lock
  design decisions before code, "we'll decide during code" is a red flag,
  `define-success`/zoom-out hard gates — source: `orchestration.md`, `workflow-steps.md`
- Aspect Splitting in routing, behavior-not-implementation testing, domain
  probes (grill-me), model-domain invariant grilling — source: `bcp-plus.md`,
  `tdd.md`, `domain-probes.md`, `ddd.md`

## B3 · The Skill Primitive

- Workflow Mandate: route work through bigpowers skills, never write code
  directly in response to a build request — source: `CLAUDE.md`, `CONVENTIONS.md`
  §Agent Workflow Mandates
- Skill Naming (verb-noun kebab-case, grep<5, documented-exception table) —
  source: `CONVENTIONS.md` §Skill Naming
- Tombstone Aliases mechanism (rename/merge preserves a stub + story tags) —
  source: `CONVENTIONS.md` §Tombstone Aliases
- next_skill signaling mandate (every critical-path skill writes
  `handoff.next_skill`) — source: `CONVENTIONS.md`
- Skill-Based Architecture (verb-noun skills), zoom-out mandate — source:
  `docs/PRINCIPLES.md` §3
- Skill catalog only invocable in tools supporting discrete SKILL.md units;
  `seed-conventions` one-time bootstrap; state transitions write
  `handoff.next_skill`; `survey-context` maps phase and next skill — source:
  `agent-config-files-and-okf.md`, `workflow-steps.md`, `orchestration-state.md`
- BMAD structured personas (architect/developer/tester) — source: `bmad.md`
- Skill-Based Architecture / subagent delegation for isolated tasks — source: `superpowers.md`

## B4 · Spec-as-Contract

- `plan-work` fleshes out `verify:`-bearing tasks before any feature code;
  step-by-step manual verification + UAT sign-off before "done"; delta-tag
  requirement (`ADDED`/`MODIFIED`/`REMOVED`/`RENAMED`) — source: `CONVENTIONS.md`
  §Agent Workflow Mandates, §Risk Tiers
- Intent/delivery/execution file table (SCOPE/VISION/GLOSSARY/release-plan/epics/
  state.yaml), countable-story-format ownership — source: `CONVENTIONS.md` §specs/
- SDD (spec as primary driver), BDD/Gherkin as the link, verification loop —
  source: `docs/PRINCIPLES.md` §4, `wasowski.md`
- Ubiquitous Language, information-first design — source: `pocock.md`, `rich-hickey.md`
- Elaborate-phase ADRs (decisions locked, why not just what), Plan-phase epic
  YAML with `verify:` per task, spec-drift detection — source: `orchestration.md`,
  `workflow-artifacts.md`, `semantic-context-bridge.md`
- Story maturity/INVEST gates, epic split rule (≥30 BCP decomposes), NFR Gate
  pattern and its logging convention, exclusive-ownership/sum-integrity/
  count-preservation invariants, criteria-defined size labels, structured-spec
  pattern (YAML capsules), verify: pass/fail-criterion mandate, bounded
  context/context-mapping/ubiquitous-language, `define-language` — source:
  `bcp.md`, `bcp-plus.md`, `spec-kit.md`, `verification-patterns.md`,
  `verification-patterns-extended.md`, `ddd.md`

## B5 · Risk-Tiered Verification

- Full Risk Tiers (Effective Rule Matrix) P0–P3 list, Tests (F.I.R.S.T) section,
  Scenario ID format (`SC-eNNsYY-P{0-3}-NN`), `test-on-change`/
  `plan-tests-waiver` rules — source: `CONVENTIONS.md` §Risk Tiers, §Tests
- F.I.R.S.T Testing (from classical craftsmanship) — source: `docs/PRINCIPLES.md` §1
- Verification Loop closing spec→plan→proof (also touches B4) — source:
  `docs/PRINCIPLES.md` §4
- TDD Red-Green-Refactor, behavior-preserving transforms, characterization
  tests, message-level testing, Liskov substitution testing, ≥95% coverage in
  review — source: `kent-beck.md`, `fowler.md`, `feathers.md`, `sandi-metz.md`,
  `code-review.md`
- Full P0–P3 risk-based test-depth tables (twice: BMAD persona framing and TEA
  framing), F.I.R.S.T with concrete thresholds (Fast <10s, Independent,
  Repeatable in CI, Self-Validating exit codes, Timely), boundary-condition/
  public-interface-only mandates (T4/T5/T8), ≥95% coverage, NFR Evidence Audit
  (Performance/Reliability/Operability go/no-go), mock-anti-pattern guidance —
  source: `bmad.md`, `tea.md`, `tdd.md`, `wasowski.md`
- Unit/type/lint/integration/coverage pass criteria, anti-patterns (vague/
  unrunnable/no-exit-code verify commands), bash syntax validation, quality-gate
  scoring (Gherkin pass/total ×100, 94% threshold) — source:
  `verification-patterns.md`, `verification-patterns-extended.md`, `gates.md`
- Confidence Verdict (reliable/moderate/low) tied to maturity/stability targets —
  source: `bcp-plus.md`
- OKF validation gates on structure/provenance/freshness, never a value —
  source: `okf.md`
- Slopcheck [OK]/[SUS]/[SLOP] tiers, human-verify checkpoint for [SUS], supply-chain
  and security-audit checklists (secrets, auth algorithms, parameterized
  queries, shell escaping, HTTPS, rate limiting, CORS/CSRF) — source: `security-threats.md`

## B6 · Gates & Hard-Stops

- Always Green / Shift Left (Preflight+CI green before forward work, 1-10-100
  shift-left cost rationale), Discovered Defects fix-or-log ladder + banned
  dismissive phrases, Pre-Merge Verification Gates, `branch-protection`/
  `always-green` P0/P1 rules — source: `CONVENTIONS.md` §Always Green, §Discovered
  Defects
- Hard Gates (explicit blocks until quality criteria met) — source:
  `docs/PRINCIPLES.md` §6
- Broken Windows / Boiling Frogs, quality-score gate (94%/<90%), review
  workflow gate, model-escalation-as-gate, extended-thinking-as-gate for
  strategic/security decisions — source: `pragmatic-programmer.md`, `code-review.md`,
  `thinking-models.md`
- Checkpoint state machine (RUNNING→VERIFY_NEEDED→AWAITING_USER→APPROVED/
  REJECTED), safety checkpoints require typing the full command, never
  auto-merge, rebase-frequently, main-is-canonical — source: `checkpoints.md`,
  `git-integration.md`
- Confirm-gate at each of the 6 phases, deviation-from-plan red flag, scope
  creep deferred not acted on, mode-scaled gate strictness (Standard/Fast-Track/
  Ad-Hoc), release safety-gate confirmation — source: `orchestration.md`,
  `orchestration-modes.md`, `workflow-steps.md`
- Full Traceability Gate pipeline (3-tier Coverage Matrix oracle confidence,
  6 blind-spot categories A–F with severity, gate decisions R1–R5, verdicts
  PASS/CONCERNS/FAIL/WAIVED) — source: `traceability-gate.md`
- Four gate types (Confirm/Quality/Safety/Transition), Hard vs Soft gate
  pattern, checkpoint pattern, mode-scaled enforcement — source: `gates.md`
- Spec-first gating (no code before spec passes validation) — source: `spec-kit.md`
- CI-blocking OKF validation, supply-chain checklist enforcement — source:
  `okf.md`, `security-threats.md`
- Git-branch-test-review-merge workflow automation — source: `superpowers.md`

## B7 · Context Isolation

- Token Management section (context engineering Write/Select/Compress/Isolate,
  effort classification light/standard/heavy, Auto-Terse, Context Compaction) —
  source: `CLAUDE.md`
- Session Governance via `state.yaml`/`release-plan.yaml` to prevent context
  rot and drift — source: `docs/PRINCIPLES.md` §6
- Model-escalation to fresh-context subagents to avoid context rot — source:
  `thinking-models.md`
- Handoff-contract principle (clear boundaries, no hidden dependencies),
  `dispatch-agents` disjoint file scopes, `delegate-task` scoped file access,
  `kickoff-branch` worktree isolation, `session-state` cold-start handoff,
  `agent-locks.yaml` concurrency prevention — source: `context-engineering.md`
- `state.yaml` precise session-state tracking, resume-via-survey-context,
  `agent-locks.yaml` protocol + 24h stale-lock detection — source: `gsd.md`,
  `orchestration-state.md`, `semantic-context-bridge.md`
- Subagent delegation for isolated tasks — source: `superpowers.md`

## B8 · Self-Describing Artifacts (OKF)

- Full specs/ ownership model (YAML cockpit table, Documentation
  Responsibilities table — each fact owned by exactly one file), Generated
  artifact targets (`.cursor/`, `.gemini/`, `.pi/`, `website/` never
  hand-edited — edit `SKILL.md` sources), docs/references SSOT Sync (distilled
  from CLAUDE.md/PRINCIPLES.md/SKILL.md, never hand-edited ad hoc), Legacy
  paths migration table, semantic-release version-truth (git tags are the only
  authority, specs mirror not predict) — source: `CONVENTIONS.md` §specs/,
  §docs/references SSOT Sync
- `no-generated-edits` P0 rule — source: `CONVENTIONS.md` §Risk Tiers
- Never-edit-generated-artifacts convention, single-source-of-truth SKILL.md —
  source: `CLAUDE.md` §Learned User Preferences, §Conventions, §Never
- OKF bundle frontmatter (`okf_kind`/`okf_version`/provenance), kind-aware
  validator, per-kind required fields, aggregation-rule declarations,
  idempotent generation, "gate on pipeline not value" (e40 honesty rule) —
  source: `okf.md`
- CLAUDE.md/AGENTS.md dual-pattern + symlink strategy, frontmatter-based OKF
  compliance for the skill catalog, bundle conformance rules — source:
  `agent-config-files-and-okf.md`
- Checkpoint standard output format (Evidence/Status/Action Required),
  CLAUDE.md/CONVENTIONS.md/`.claude/settings.json` as generated-by-
  `seed-conventions` artifacts, cycle-times.yaml, dashboard tooling, release
  outputs (tag/notes/CHANGELOG), skill graph + OKF wiki bundle (skills-wiki/
  conventions-wiki/agent-guide), targets-registry as single Integration
  Registry — source: `checkpoints.md`, `workflow-artifacts.md`, `orchestration.md`,
  `semantic-context-bridge.md`, `targets-registry.md`
- BMAD's Bold/Minimal/Actionable/Durable documentation criteria, calibration_id
  provenance, TEST_PLAN artifact shape — source: `bmad.md`, `bcp-plus.md`, `tea.md`
- Coverage-matrix artifact set, documentation structural-validity checks —
  source: `traceability-gate.md`, `verification-patterns-extended.md`

## B9 · Effort Accounting (BCP)

- Full BCP accounting mandate (sizing via `bcp.md`'s 6-step method,
  `plan-work` writes `epic_cycle.story_bcps`, `release-branch` computes
  BCP/hour), Timestamp mandate (`story_start`/`story_end`), BCP is
  story-level only (no per-task `[BCP N]`) — source: `CONVENTIONS.md` §BCP
  accounting mandate, §Timestamp mandate
- `effort:` frontmatter (light/standard/heavy) for skill selection, token-budget
  escalation thresholds — source: `context-engineering.md`, `model-profiles.md`
- BCP measures functional complexity not time; classify functional vs
  non-functional; decompose into Business Rules/Interface Elements/
  Boundaries; Fibonacci element scoring; size bands (small/medium/large/
  must-split ≥30); baseline in release-plan.yaml; velocity tracking in
  cycle-times.yaml — source: `bcp.md`
- BCP-Plus 13-dimension framework, Element Router/Sizer separation for lower
  variance — source: `bcp-plus.md`
- Release-plan BCP baseline + WSJF ordering, BCP/hour ≥2.0 target, per-task
  `[BCP N]` tags in older workflow docs (superseded by story-level-only rule
  above — a duplication/drift example), state-tracking of `story_bcps` and
  `current_step` — source: `workflow-artifacts.md`, `orchestration.md`,
  `orchestration-state.md`, `workflow-steps.md`

## B10 · The Synthesis

- 6-Phase Lifecycle (Discover→Elaborate→Plan→Build→Verify→Release; *Sustain*
  is a session-flow state, not a lifecycle phase), Hard Gates, Session
  Governance, 94% quality threshold — source: `docs/PRINCIPLES.md` §6
- 6-phase core loop identically stated, `orchestrate-project` phase
  sequencing, semantic-release version progression from `0.0.0-β` — source:
  `orchestration.md`, `workflow-steps.md`, `git-integration.md`,
  `workflow-artifacts.md`
- BMAD's Discover→Elaborate→Plan→Build→Sustain arc, TEA's 9 workflows, SDD
  lifecycle integration across CLAUDE.md/elaborate-spec/plan-work/verify-work,
  DDD Strategic Design triage (Core/Supporting/Generic domain) — source:
  `bmad.md`, `tea.md`, `wasowski.md`, `ddd.md`

## ★ Capstone · Outcome Evals

**Tension flagged, not resolved here:** bigpowers' *current* proof mechanism is
a Gherkin-based self-compliance suite (`npm run compliance`, 94% threshold) —
source: `docs/PRINCIPLES.md` §6/§7, `CLAUDE.md` §Commands, `code-review.md`,
`gates.md`. `reborn-constitution.md`'s Capstone definition explicitly states
this target block "replaces the legacy 94% Gherkin self-compliance gate" with
outcome evals (with-skill vs without-skill delta). That replacement is **e58's
job (evals-over-compliance), not yet built** — today's 94% gate is what
actually exists and is what e55s02 must describe accurately under whichever
block it lands in, without presenting Capstone's target-state eval mechanism as
already true.
- Request-review checklist / quality-score gate as today's closest analog —
  source: `code-review.md`
- Human-in-the-loop UAT mandate after every story (not automated code
  generation) — source: `spec-kit.md`
- `run-evals` + regression UAT phase, `specs/EVALS-<feature>.md` results —
  source: `workflow-steps.md`, `workflow-artifacts.md`

---

## Duplication findings (rule restated across ≥2 files — the drift problem e55 exists to fix)

- **6-phase lifecycle**: stated near-identically in `docs/PRINCIPLES.md` §6,
  `orchestration.md`, and `workflow-steps.md`.
- **F.I.R.S.T testing**: stated in `CONVENTIONS.md` §Tests, `docs/PRINCIPLES.md`
  §1, `kent-beck.md`, `uncle-bob.md`, `tdd.md`, and `wasowski.md` — six sources
  for one rule.
- **P0–P3 risk-based verification depth**: stated in full in both `bmad.md` and
  `tea.md` with near-identical tier tables, and again (operationally) in
  `CONVENTIONS.md` §Risk Tiers.
- **BCP is story-level, not per-task**: `CONVENTIONS.md` states this as current
  policy; `workflow-artifacts.md`/`orchestration.md` still reference an older
  `[BCP N]` per-task tag convention — a live drift example, not just a stylistic
  duplication.
- **94%/quality-gate threshold**: stated in `docs/PRINCIPLES.md`, `CONVENTIONS.md`
  (indirectly via Preflight), `gates.md`, and `code-review.md`.
- **Zoom-out before editing**: `pocock.md`, `docs/PRINCIPLES.md` §3, and
  `orchestration.md`/`workflow-steps.md` (as a named HARD GATE) all state this.
- **Boy Scout Rule**: `CONVENTIONS.md`, `docs/PRINCIPLES.md` §1,
  `pragmatic-programmer.md`, `ousterhout.md`, and `workflow-steps.md`.

## No constitution-level content (reference/routing data, not stated rules)

- `accelerate.md` — DORA metrics mapped against existing skills; a capability
  audit, not a new rule.
- `bigpowers-mcp.md` — MCP server architecture/implementation detail.
- `model-profiles.md` — skill→model routing lookup table (operational
  reference; its token-budget escalation rule is the one piece counted under B9
  above).
- `e33-abandoned.md`, `e36-abandoned.md` — explicitly closed/abandoned epics
  (docs website, doc dedup); story-comment references only, no live rules.

## Unclear — needs a decision

- The `--fast` flag / BCP<3 zoom-out-skip optimization (`bcp.md`) sits between
  B9 (effort/sizing) and B10 (planning tempo) — doesn't cleanly fit either.
- **Catalog Freeze section** (`CONVENTIONS.md` §Catalog Freeze, e54-e59) is a
  migration-scoped, time-bound policy (expires when e56 merges) rather than a
  permanent doctrine rule — flagged for e55s02 to decide whether it belongs in
  `constitution.md` at all, or should stay only in `CONVENTIONS.md` as
  transitional process state.
