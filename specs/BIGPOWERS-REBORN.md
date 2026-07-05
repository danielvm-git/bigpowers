# bigpowers, Reborn — a greenfield design (empty repo, today's knowledge)

> A thought-exercise, not a migration. Assume: **new repository**, nothing to preserve, everything you learned across 98 releases and 74 skills is in your head, and the 2026 ecosystem (Agent Skills as a portable format, plugins/marketplaces, MCP) already exists on day 0.
> Companion to `specs/CLEAN-SLATE-ARCHITECTURE.md` (which was a *refactor* of the current tree). This one throws the tree away.
> **Reborn doc set:** [`REBORN-DOC-INDEX.md`](REBORN-DOC-INDEX.md) · [`reborn-constitution.md`](reborn-constitution.md) · [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md)

---

## 0. What changes when there is no legacy

The refactor doc was dominated by legacy gravity: fix `get_phase()`, cutover shims, permanent aliases, absorbing epics e28–e48. **None of that exists here.** A reborn build is free to (a) choose the right primitives instead of the historical ones, (b) name things as a public API from the first commit, and (c) *not build* the accidental complexity that accreted over 41 days. So the interesting question isn't "what's the new folder layout" — it's **which of the current core ideas survive contact with a blank page.**

## 1. The primitives, on trial

Each load-bearing idea in today's bigpowers, cross-examined. Verdict, then the reborn form.

| Primitive (today) | Verdict | Reborn form & why |
|---|---|---|
| **"Skill" as the unit** (74 SKILL.md files) | **KEEP but purify** | The market validated skill-as-unit (Anthropic Agent Skills, plugins). The *error* was encoding three different things as "skills": procedures, rules, and tools. Reborn: a skill is **only a procedure** — a repeatable multi-step workflow. Rules move to the constitution; deterministic tools move to the kernel. Cuts the corpus by ~half before any merging. |
| **74-skill count as a feature** | **DROP** | A count is a vanity metric that fights maintenance (see refactor red-team §9.2). Reborn tracks *coverage of the loop*, not headcount. Target ≈ 28 procedures. |
| **6-phase lifecycle** (Discover→Elaborate→Plan→Build→Verify→Release) | **REPLACE** | PMBOK-shaped and Discover/Elaborate blur. Reborn uses **5 fractal movements** (§4) that run identically at project, epic, and story scope, with the **spec as the fixed point** rather than the phase boundary. |
| **BCP (Business Complexity Points) as a size/effort unit** | **KEEP** | BCP is how *you* size the software you build — it answers the two questions that actually run a solo roadmap: **"how much effort is still left to finish?"** and **"how big is this new epic I'm considering?"** That is a real, load-bearing use, so BCP stays as the **primary sizing unit** on every story and epic. Reborn *adds* verification and context signals alongside it (§7) as quality telemetry — it does **not** replace BCP with them. (BCP/hr velocity stays optional: useful if you want it, never a required ceremony.) |
| **File-based YAML cockpit** | **KEEP as source of truth** | Git-versioned, diffable, greppable, portable across runtimes — the 2026 SDD consensus and a genuine strength. At MVP, state is read/written **directly** through a tiny helper lib (`bp-yaml` get/set) — no server. An MCP interface over the cockpit is desirable but is explicitly the **last piece built** (§8), never part of MVP. Files stay authoritative forever; MCP, when it arrives, is a convenience layer that can be deleted without losing state. |
| **94% Gherkin self-compliance gate** | **REPLACE** | Testing "does the framework obey its own philosophy" is self-referential. Reborn spends that budget on **outcome evals**: with-skill vs without-skill pass@k and token deltas on real tasks (the anthropic/skills method). A thin `constitution-lint` keeps structural invariants; the *proof* is task success, not principle-conformance. |
| **Bespoke 4-target sync** (Claude/Cursor/Gemini/pi via copy-paste pipeline) | **DROP from core** | In 2026 the portable **Agent Skill format** + **plugin/marketplace** distribution exist. Reborn authors *in the native format* and ships as a plugin; runtime adapters (Cursor/Gemini) become an optional **pack**, not a core pipeline. The single biggest source of today's duplication (G1/G2) simply never gets built. |
| **27 reference docs** (uncle-bob.md, akita.md, …) | **DROP** | They mostly restate CONVENTIONS + PRINCIPLES (G5). Reborn has **one `constitution.md`** with provenance footnotes. The layer-cake lives as a single narrative, not 27 parallel files. |
| **Prescriptive hard gates everywhere** ("you MUST use a skill") | **REPLACE with risk-tiered gates** | Uniform gates cause gate fatigue and bypass training. Reborn bakes **TEA risk tiers** (P0–P3) in from day 0: trivial changes get a fast lane, risky changes get the full gauntlet. |
| **Dual epic format** (`e01.yaml` *and* `e01-slug/` capsule) | **DROP** | One format: the capsule directory, always. |
| **`next_skill` handoff chain** | **KEEP** | Genuine differentiator; cheap; survives interruption. Stays. |
| **semantic-release + Conventional Commits** | **KEEP** (kernel) | Automated truth for versioning. Stays, in the kernel. |
| **Gherkin acceptance criteria in specs** | **KEEP** | Testable specs are the point of SDD. Kept — but kept *distinct* from the (now-deleted) self-compliance meta-tests. |

The survivors define the soul: spec-as-source-of-truth, the layer-cake doctrine, verb-noun procedures, the fractal loop, file cockpit, **BCP sizing**, next_skill, semantic-release, testable specs. Everything else is negotiable — and much of it is cut.

## 2. The reborn conceptual model — 7 nouns

A blank repo needs a small, orthogonal vocabulary. These seven are the whole model:

1. **Constitution** — one file. Immutable principles (the layer cake), risk tiers, coding/testing conventions. The Spec Kit "constitution," but carrying bigpowers' doctrine. Single source of rules.
2. **Spec** — the durable, testable statement of intent (product scope, glossary/ubiquitous language, acceptance criteria). Lives in git; survives code regeneration.
3. **Cockpit** — machine state (active epic/story, handoff, metrics). YAML OKF bundles under `specs/cockpit/`, read and written at MVP through **`bp-yaml` file helpers** (no server). An optional MCP mirror is added post-v1.0 (§8, M5); files stay authoritative forever.
4. **Skill** — a *procedure*: a verb-noun, progressively-disclosed workflow the agent runs. Nothing else is a skill.
5. **Kernel** — the deterministic runtime. At MVP: file-based state helpers (`bp-yaml`), the risk-tiered gate engine, semantic-release, the eval harness, and the plugin/native-format renderer. Tools, not prose. **An MCP server over this kernel is added last** (§8, final milestone) — it is not an MVP dependency.
6. **Pack** — an optional, independently-versioned bundle of skills+templates (deploy, web-design, runtime-adapters, migration). Distributed via marketplace.
7. **Cycle** — one pass of the loop at any scope; the unit the ledger and metrics attach to.

Note the discipline: **rules are not skills, tools are not skills, docs are not skills.** That single rule is what keeps the corpus from ballooning back to 74.

## 3. Repo layout — and the split that day-1 bigpowers never made

The original repo conflated *the methodology's own source* with *the artifact it drops into your project*. Reborn separates them cleanly:

```
bigpowers/                      # the methodology package (this repo)
├── constitution.md             # THE doctrine file (principles + risk tiers + conventions)
├── README.md
├── kernel/                     # the runtime (TypeScript)
│   ├── src/                    #   gate engine · bp-yaml · release · eval harness · renderer (MCP added M5)
│   └── tests/                  #   golden fixtures (one per output format & gate)
├── skills/                     # ~28 procedures, authored in native Agent Skill format
│   └── <verb-noun>/SKILL.md    #   frontmatter: effort · spawn · risk · verify(behavioral)
├── packs/                      # optional bundles, independently versioned
│   ├── deploy/  web-design/  runtime-adapters/  migration/
├── scaffold/                   # WHAT A NEW PROJECT RECEIVES (the drop-in)
│   ├── constitution.template.md
│   ├── specs/                  #   empty cockpit + spec templates
│   └── CLAUDE.md GEMINI.md AGENTS.md
├── evals/                      # with/without-skill datasets + runner
├── marketplace.json            # plugin/marketplace manifest (Claude Code / Cowork)
└── package.json
```

Two things ship: the **plugin** (kernel + skills, installed once, globally) and the **scaffold** (per-project spec+cockpit templates, seeded on `init`). They never entangle again.

## 4. The loop — 5 fractal movements, spec-anchored

The same five run at project scale (once), epic scale (per epic), and story scale (per story). The spec is the invariant that each movement reads and refines — you never "leave" the spec behind a phase gate.

```
        ┌──────────────────────── the spec (fixed point) ────────────────────────┐
        │                                                                          │
   FRAME → SPECIFY → PLAN → BUILD → PROVE → (ship)                                  │
        │        │       │       │      │                                          │
        └────────┴───────┴───────┴──────┴──── handoff.next_skill → resume anytime ─┘

FRAME    understand problem + context      survey-context · research-first · map-codebase
SPECIFY  intent → durable testable spec    elaborate-spec · grill · define-language · define-acceptance
PLAN     decompose, risk-tier, order       plan-work(scope→slice→tasks) · assess-impact · order-release
BUILD    TDD vertical slices, isolated     kickoff-branch · develop-tdd · delegate
PROVE    verify by risk tier, then ship    verify-work · critique(gaps) · review · security · commit · release
```

Two loops, not one: a **fast lane** (P3/trivial: `quick-fix` → verify → ship) and the **full lane** (P0–P2: the whole movement chain). The risk tier assigned in PLAN picks the lane — gate discipline without gate fatigue.

## 5. The reborn skill corpus (~28 procedures)

Authored in native Agent Skill format; every one carries `effort`, `spawn`, `risk`, `movement`, and a **behavioral** `verify:` (asserts an artifact, never `test -f SKILL.md`). Grouped by movement. Target ≈ **29** procedures (28 + native `count-bcp`).

**Meta / bootstrap (3):** `using-bigpowers` · `orchestrate-project` (drives the fractal loop) · `build-epic` (per-story cycle)

**Frame (4):** `survey-context` · `research-first` (opensrc/prior-art) · `map-codebase` · `search-skills`

**Specify (5):** `elaborate-spec` · `grill` (`--docs`/`--domain`) · `define-language` · `design-interface` · `define-acceptance` (Gherkin + verify commands)

**Plan (5):** `plan-work` (scope→slice→failing `tasks.yaml`→ambiguity critic) · `count-bcp` (story + glossary → `bcp-count` OKF bundle) · `assess-impact` · `order-release` (WSJF) · `seed-conventions`

**Build (5):** `kickoff-branch` (+env) · `develop-tdd` (RED-GREEN-REFACTOR, F.I.R.S.T inline) · `delegate` (`--mode seq|parallel`) · `spike-prototype` · `quick-fix` (fast lane)

**Prove (6):** `verify-work` (`--scope full|fix`, completeness/gap critic) · `audit-code` · `review` (`--stage request|respond`) · `security-review` · `fix-bug` (`--rca`) · `trace-requirement`

**Sustain (5, transversal, effort:light):** `session-state` · `terse-mode` (auto) · `craft-skill` (`--evolve`/`--audit`) · `run-evals` · `compose-workflow`

Everything that is *not* a procedure is deliberately absent from this list — `guard-git`, `hook-commits`, index/lock/compliance, sync-to-target, deploy, dashboard, migrate — because they are **kernel tools or packs**, not skills. That reclassification, more than any merge, is what turns 74 into ~28.

## 6. Distribution — born as a plugin, not a sync pipeline

Day-0 packaging choices the original couldn't make:

- **Author once in the portable Agent Skill format.** No bespoke IR→4-target renderer in the core. The kernel's only render job is packaging the plugin bundle.
- **Ship as a plugin on a marketplace** (Claude Code / Cowork). `install` gives you kernel + core skills globally; `bigpowers init` seeds the scaffold into a project.
- **Runtime reach is a pack.** Cursor `.mdc` and Gemini `.toml` adapters live in `packs/runtime-adapters/`, generated on demand — off the critical path, so their drift can never break the core.
- **State is a file surface at MVP; MCP comes last.** Through v1.0, agents read/write the cockpit through the `bp-yaml` helpers and the `next_skill` handoff — plain files, no server. Only after the loop is proven end-to-end does an MCP layer (`bigpowers_get_state`, `_next_skill`, `_open_gate`, `_record_cycle`) get added as the final convenience surface, killing the string-edit fragility class without ever becoming a hard dependency.

## 7. Metrics, reborn — BCP for effort, plus quality telemetry

**BCP stays the headline.** It is the unit that lets you run the roadmap: sum the open stories' BCP to see **effort still remaining**, and BCP-size a **new epic** before committing to it. Every story carries a BCP; every epic's `epic.yaml` sums them; `release-plan.yaml` shows total remaining. This is unchanged from today because it works.

What's *new* is a thin quality ledger written **alongside** BCP, per cycle, to `specs/cockpit/ledger.yaml` — these complement BCP, they don't replace it:

| Signal | What it measures | Role |
|---|---|---|
| **BCP (remaining / per-epic)** | size of software still to build; size of a candidate epic | **primary — roadmap & effort management** |
| **assertions failing→passing** | acceptance checks flipped green by real verify runs (MoAI-style) | done-ness proof (not self-report) |
| **first-pass gate rate** | % of gates passed without rework | quality signal |
| **context cost** | tokens to complete a cycle (from PreToolUse accounting) | efficiency signal |
| **with/without-skill Δ** | eval pass@k + token delta per skill | proves each skill earns its place |
| **risk tier** | P0–P3, set in PLAN | picks fast vs full lane (§4) |
| **BCP/hr velocity** | *optional* — BCP per elapsed hour | keep if you find it useful; never required |

So the roadmap question — "how many BCP are left, and how big is this next epic?" — is answered exactly as today. The added signals just tell you *whether the work is actually done and whether the skills are helping*, which BCP alone never claimed to.

## 8. Day-0 → v1.0 — how you'd actually build it (bootstrap by dogfooding)

The reborn repo builds *itself* with a minimal seed of itself — the tightest possible proof the methodology works.

- **M0 · Seed (hand-written, ~1 week).** Write `constitution.md`, the scaffold templates, a thin **file-based** kernel (`bp-yaml` get/set over the cockpit + one risk-tiered gate — no server), and **5 bootstrap skills** — survey-context, elaborate-spec, plan-work, develop-tdd, verify-work. Just enough to run the loop by hand, on plain files.
- **M1 · Self-host.** Use the seed to *specify and build the rest of the kernel*: the gate engine, BCP roll-up (epic + remaining-effort sums), semantic-release, the eval harness, plugin packaging. All still file-based. From here the repo is built with its own loop; every commit is a dogfooding datapoint.
- **M2 · Skill corpus.** Author the remaining ~23 skills with `craft-skill`, each shipping a behavioral verify **and** an eval case in `evals/`. No skill lands without proving it helps.
- **M3 · Packaging.** `marketplace.json`, plugin bundle, `bigpowers init` scaffold. Optional packs (deploy, web-design, runtime-adapters) split out.
- **M4 · Proof.** Build one real showcase project end-to-end with it; publish the BCP burn-down + eval deltas + ledger as public receipts.
- **v1.0** = the loop builds a real project cold on **plain files**, and evals show a positive with-skill delta across the core skills. **No MCP required.**
- **M5 · MCP (the last piece, post-v1.0).** Only now wrap the already-proven file cockpit in an MCP server (`get_state`, `next_skill`, `open_gate`, `record_cycle`). Because files stayed authoritative the whole way, MCP is a pure convenience layer — removable, and never a thing v1.0 depended on.

Sequencing note: this is deliberately **kernel-first but MCP-last**, the inverse of the original (which grew skills first and extracted infra late — the source of most debt). Constitution and cockpit *file* contracts are frozen at M0; skills are written against stable file contracts, so the corpus never churns from underneath, and the MCP layer at M5 simply mirrors a schema that's already battle-tested.

## 9. What we deliberately do NOT build

Naming the non-goals is half the value of a blank page:

- No bespoke multi-runtime sync pipeline (native format + packs instead).
- No 27 reference docs (one constitution).
- No self-referential compliance suite (outcome evals instead).
- No dual epic formats, no `bp-` prefix, no flat 31-script grab-bag.
- No skills for things that are tools (guard-git) or rules (F.I.R.S.T) — those are kernel and constitution.
- No skill-count branding.
- No obsidian-wiki / archive sprawl in the methodology repo — history lives in git, not in `specs/archive/`.

## 10. Red-team (brief)

- **Bootstrap paradox is real.** M0's 5 hand-written skills are written *without* the methodology, so their quality is unverified until M1 evals exist. Mitigation: keep M0 skills explicitly "provisional," re-derive them under eval in M2.
- **Native-format bet is a dependency risk.** If the portable Agent Skill format shifts, the "no sync pipeline" saving partially reverses. Mitigation: the renderer is one kernel module behind a stable interface — a format change is a renderer change, not a corpus change.
- **Keeping BCP means keeping its calibration burden.** BCP is only useful for "effort remaining" if sizing stays consistent across epics; a solo dev's sense of an XS/L drifts over months. Mitigation: anchor BCP with 2–3 reference stories in the constitution (a known-3, a known-8) so new epics are sized *against exemplars*, not gut feel — otherwise the remaining-effort sum lies.
- **Risk-tiered gates need calibration data you won't have at v1.0.** Ship P0–P3 tiers advisory-first (WARNING), promote to BLOCKER only after M4 gives false-positive rates. Same lesson as the refactor red-team.
- **MCP-last is the right call, but don't let the file schema ossify carelessly.** Because M5 mirrors the file cockpit, any sloppy YAML shape you tolerate through v1.0 becomes the MCP contract by default. Treat the cockpit schema as the real API from M0 — version it — so the eventual MCP layer isn't wrapping accidental structure. Files stay authoritative; a broken/absent MCP layer must never mean lost state (you can always hand-edit the YAML).

## 11. Compliance projection — reborn vs current against `specs/verifications/features`

Empirical baseline (harness run 2026-07-04): **current bigpowers = 98%** (91 pass / 1 fail / 2 waived; threshold 94%; gate PASS). The single fail is a sandbox permission artifact (`sync-preserves-plus` couldn't `rm` a `.gemini` file) — effectively ~99% in a normal env. The 2 waivers are current-implementation debt (grep-`<5` false positives from duplicated `show_help`/`main` helpers; two Python files over the 300-line cap).

The harness is two tests wearing one coat: ~90% of steps assert **principles** (fair to any design); ~10% assert **this repo's specific mechanisms** (structurally biased toward current bigpowers). Projected reborn results:

| Feature | Tests | Current | Reborn (projected) | Why |
|---|---|---|---|---|
| cleancode | SRP, 4–20 line fns, DRY, F.I.R.S.T | PASS | **PASS+** | behavioral `verify:` kills tautological checks; kernel removes sync/path duplication → DRY improves |
| pocock | deep modules, token economy, context managed | PASS | **PASS+** | `effort:`/`spawn:` + auto terse-mode + deep kernel — closes the gap current only mentions |
| karpathy | assumptions, MVP, surgical, verify-loop | PASS | **PASS** | preserved (grill, define-acceptance, risk-tiered verify) |
| akita | grep `<5`, `<300` lines, remediation, DI | PASS *(2 waived)* | **PASS+ (un-waives both)** | lib consolidation removes duplicate-helper false positives; redesigned trace engine clears the Python offenders |
| plan-tests | risk matrix, `SC-eNNsYY-P{0-3}` IDs | PASS | **PASS+** | risk tiers P0–P3 are core from day 0 (currently still-rolling e46) |
| conventions | Conv-Commits, SemVer, size/SRP/F.I.R.S.T | PASS | **PASS** | all principles kept in one constitution; packaging round-trip step replaces legacy sync-preserves-plus (§11) |
| superpowers | hard gates, fresh-subagent review, quality gate | PASS | **PASS** | gates/reviews kept (risk-tiered); 94% step replaced by risk-tier gate + eval Δ steps (§11) |
| harness-smoke | trivial | PASS | **PASS** | — |

**Bottom line.** Against the harness *as rewritten for reborn* (2026-07-04): reborn ≈ **100%** on principle steps — the 2 current waivers flip to genuine passes, tautological-verify is fixed by construction, and the two legacy mechanism steps are replaced (below). Current bigpowers still carries the old steps until the new repo ships; this tree's feature files are updated to match the reborn gate model.

### Two feature steps rewritten for the new architecture (applied 2026-07-04)

1. **`conventions.feature`** — removed `sync skills preserves plus in descriptions` (guarded a BSD-`sed` bug in the bespoke 4-target renderer reborn never builds). Replaced with **`the skill packaging pipeline round-trips a golden fixture without data loss`** — tests packaging integrity via a golden fixture, not string-preservation in a deleted pipeline.
2. **`superpowers.feature`** — removed `reject PRs that do not meet the 94% quality threshold`. Replaced with **`reject work that fails its risk-tier verification gate`** (P0–P3) and **`each core skill should prove a positive with-skill versus without-skill eval delta`** — tests the Capstone gate instead of a legacy magic number.

## 12. Document & Artifact Model — OKF as the universal envelope

Today the doc layer runs **three overlapping conventions**, each retrofitted onto a different slice: the **countable-story** 20-section contract (stories only), the **`_LATEST`** filename pointer (specs/tech-arch only), and **OKF** frontmatter (metrics/migrations/reports only, added last in e40–e45). Same drift pattern as the references (G5): the best idea (OKF) governs a fraction of the surface while older conventions cover the rest.

**Reborn rule (constitution B8): every generated file is an OKF bundle.** One envelope, one validator, templates as data.

### One envelope for every artifact

| Family | Reborn `okf_kind` | Body template |
|---|---|---|
| Product intent | `scope`, `vision`, `glossary` | YAML + provenance |
| Story | `story` | the 20-section countable body |
| Epic | `epic` | metadata + BCP roll-up + story list |
| Execution | `tasks` | failing→passing assertion ledger (derived from story §17) |
| Cockpit | `cockpit-state`, `cockpit-release`, `cockpit-exec` | versioned schema (the "real API from M0") |
| Tech arch | `tech-stack`, `test-plan`, `impact` | prose + provenance |
| Verification | `verification-report`, `story-metrics`, `bcp-count` | score/provenance-gated |
| Registries | `bug`, `adr`, `migration` | structural |

### Three things fall out of the single move

- **Uniform validation.** `validate-okf` becomes *the* gate for all of `specs/`. The countable-story "counter" is just the validator for `okf_kind: story` (checks the 20 sections present, scores maturity). One kind-aware dispatcher, structure + provenance for everything, never a value.
- **Templates become data.** The kernel ships one body template per kind in `templates/`. Skills fill templates (`plan-work` emits `story`; `verify-work` emits `verification-report`). New doc type = new template + validator entry, not a skill edit.
- **`_LATEST` is deleted.** Git already versions and freezes. The canonical path is latest; git tags freeze baselines; OKF `supersedes` + `generated_at` + `commit_range` make "latest" a *query*, not a filename hack. The `snapshots/` duplication disappears.

### The spec vs. the count are two artifacts

`okf_kind: story` is the **human-authored input**; `okf_kind: bcp-count` is the **machine-derived, provenance-gated size** (Router elements + per-dimension subtotals + `total_bcp` + `calibration_id` + `confidence_verdict`). The story is never hand-stamped with a gestalt size; the count is derived and carries the provenance of the native counter that produced it. Gate on `calibration_id` and structure, never on the number.

### Native BCP counting — implement the specs, don't depend on a tool

The BCP-Plus methodology (formerly documented as `big-counter` ADRs) defines counting precision: an **Element Router** owns dimension classification (ADR-0001); **canonical elements via identity rules** (ADR-0002); **aspect-splitting with Business Rules as residual** (ADR-0003); **criteria-defined sizes via decision tables** (ADR-0006); **pure dimension modules** for replay (ADR-0007); **retry-then-fail, no partial totals** (ADR-0008); **`calibration_id` provenance** (ADR-0010). The `big-counter` repository is **spec-only now** — not an executable dependency. Reborn **natively implements** these rules via a `count-bcp` skill or kernel module.

Three consequences for the reborn doc model:

1. **The `story` format's job is coverage and clarity, not pre-partitioning.** The Element Router logic owns element partitioning and aspect-splitting — so the story must *not* try to pre-assign elements to dimensions (that would fight the Router). It just needs complete, unambiguous input.
2. **`bcp-count` is generated natively** as an OKF result bundle — `elements/`, `dimensions/`, `provenance.md` — by `count-bcp`, not an external tool.
3. **The domain glossary is counting ground truth.** Author `define-language` output as an OKF **knowledge bundle**; `count-bcp` consumes it for dims 5/6/7/11–13.

**Ledger rule:** every `bcp-count` and the velocity series it feeds are **segmented by `calibration_id`** — a chart mixing calibrations is a silent lie (ADR-0010). The cockpit stores `calibration_id` next to every BCP.

## 13. Building blocks map — features, references, prior art → B0–B10

The reborn philosophical foundation is poured in dependency order (constitution Part I). Blocks are **dependency-driven, not chronological** — each assumes the ones above it exist.

| Layer | Blocks | What it establishes |
|---|---|---|
| How the agent thinks | **B0–B2** | Token budget → code floor → cognitive floor |
| How work is structured | **B3–B4** | Procedure as unit → spec as contract |
| How quality is enforced | **B5–B6** | Risk tiers → hard gates (Confirm / Risk / Quality / Completeness) |
| How context is managed | **B7–B8** | Fresh-context isolation → universal OKF envelope |
| How effort is tracked | **B9** | BCP from spec → roadmap (native `count-bcp`) |
| How it all coheres | **B10** | Fractal loop, one constitution, spec as invariant |
| How it proves itself | **Capstone** | Outcome evals, not self-compliance |

This section maps the 8 compliance features, the `docs/PRINCIPLES.md` layer cake, and the e48/opensrc prior-art survey onto those blocks.

### 13.1 M0 document foundation (complete)

| Document | Role | Constitution blocks |
|---|---|---|
| [`reborn-constitution.md`](reborn-constitution.md) | Single source of **rules** — B0–B10, risk tiers, gates, conventions | B0–B10 + Capstone + Parts II–IV |
| [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md) | Single source of **file contracts** — OKF envelope + 6 core kinds | B8 (envelope); B4/B9 (story, glossary); B10 (epic, tasks); cockpit schema |
| This file (`BIGPOWERS-REBORN.md`) | **Architecture** — nouns, loop, skills, metrics, build sequence | All blocks (synthesis) |
| [`REBORN-DOC-INDEX.md`](REBORN-DOC-INDEX.md) | Cross-link index and read order | — |

Seed skills at M0 author against all three; the kernel implements `validate-okf` against the spine; skills reference the constitution, never restate it.

### 13.2 Eight verification features → constitution blocks

| Feature | What it tests | Primary blocks | Reborn treatment |
|---|---|---|---|
| **cleancode** | SRP, 4–20 line fns, DRY, F.I.R.S.T, public-API tests | **B1**, Part III | Rules in constitution only; behavioral `verify:` on every skill |
| **pocock** | Deep modules, token economy, context managed | **B0**, **B7** | `effort`/`spawn` + isolation; auto `terse-mode`; deep kernel |
| **karpathy** | Assumptions, MVP, surgical edits, verify loop | **B2** | `grill`, `define-acceptance`, loop-until-verified |
| **akita** | grep `<5`, `<300` lines, remediation, DI | **B1**, **B8** | Craftsmanship + OKF structural validation |
| **plan-tests** | Risk matrix, `SC-eNNsYY-P{0-3}` IDs | **B5** | P0–P3 core from day 0; NFR gates for P0/P1 |
| **conventions** | Conv-Commits, SemVer, size/SRP/F.I.R.S.T | Part III | One constitution; packaging round-trip step (§11) |
| **superpowers** | Hard gates, fresh subagent review, quality gate | **B6**, **Capstone** | Risk-tier gate + eval Δ replace 94% magic number |
| **harness-smoke** | Harness wiring | **Capstone** | Meta-check that the eval/compliance harness runs |

### 13.3 `docs/PRINCIPLES.md` layer cake → construction order

| Era / source (PRINCIPLES) | Block | Poured when |
|---|---|---|
| Context engineering (Write/Select/Compress/Isolate) | **B0** | First — every artifact is token-aware |
| Uncle Bob — Clean Code (2008) | **B1** | Craftsmanship floor |
| Ousterhout — deep modules (2018) | **B1** | Abstraction unit (module), not function size |
| Karpathy — think-first (2023–24) | **B2** | Cognitive floor before code |
| Pocock — Agent Skills (2023–24) | **B3** | Procedure primitive |
| Superpowers — hard gates (2023–24) | **B6** | Enforcement (risk-scaled) |
| Wasowski — SDD + BDD (2024) | **B4** | Spec-as-contract |
| BCP / BCP-Plus (2024) | **B9** | Effort accounting via native `count-bcp` |
| Akita — Clean Code for AI Agents (2026) | **B1** | Agent-native grep/remediation/token rules |
| GSD — context rot, fresh subagents | **B7** | Isolation + `handoff.next_skill` |
| BMAD — document lifecycle + TEA P0–P3 | **B5**, **B10** | Risk tiers + fractal loop |
| OKF — Open Knowledge Format (e40–e45) | **B8** | Universal envelope |
| anthropic/skills — eval methodology | **Capstone** | Outcome proof replaces self-compliance |

Full lineage narrative may live in a thin `docs/PRINCIPLES.md` in the new repo; rules live once in the constitution.

### 13.4 Prior art (e48 opensrc survey + 2026 landscape) → what Reborn steals

| Source | Mechanism | Block / home |
|---|---|---|
| **github/spec-kit** | Constitution + clarify/ambiguity critic | B4; `plan-work` critic |
| **get-shit-done (GSD)** | Context rot, fresh subagents, effort budget | B7; `effort`/`spawn` |
| **bmad-code-org/BMAD-METHOD** | Document lifecycle, TEA P0–P3, NFR gates | B5, B10 |
| **MoAI-style ledgers** | Failing→passing task assertions | B8 `okf_kind: tasks` |
| **anthropics/skills** | with/without-skill eval Δ | Capstone; `run-evals` |
| **opensrc / vercel-labs** | Prior-art fetch before build | `research-first` (Frame) |
| **Agent Skills format** | Portable skill unit + plugin distribution | B3; no 4-target sync |
| **BCP-Plus methodology** (former `big-counter` ADR specs) | Element Router, calibration_id, glossary ground truth | B9; native `count-bcp` — spec reference, not external tool |

### 13.5 Three shapes, not eleven templates (M0 spine rule)

From the conversation: OKF is one envelope; bodies cluster into three shapes only.

| Shape | `okf_kind` examples | Authored? |
|---|---|---|
| **Spec-bundle** (envelope + structured body) | `story`, `epic`, `glossary`, `scope`, `vision`, `adr`, `bug` | Yes — M0 drafts 4; others on first use |
| **Cockpit schema** (versioned machine state) | `cockpit-state`, `cockpit-release`, `cockpit-exec` | Yes — schema at M0 |
| **Tool-owned result** | `bcp-count`, `story-metrics`, `verification-report` | **No** — producing tool owns schema |

See [`reborn-m0-okf-spine.md`](reborn-m0-okf-spine.md) for the six M0-authored kinds (envelope + cockpit + story + glossary + epic + tasks).

---
*Design doc for a **new repository**. M0 foundation complete: constitution + OKF spine + this architecture. Next: stand up the empty repo, copy the trilogy, hand-write the 5 seed skills, and dogfood.*
