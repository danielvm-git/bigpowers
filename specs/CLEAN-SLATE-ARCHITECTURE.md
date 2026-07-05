# bigpowers v3 — Clean-Slate Architecture Proposal

> Author: architecture review (Cowork session, 2026-07-04)
> Question answered: *If we rebuilt bigpowers from scratch — closing every documented gap and non-conformance — with the leanest skill set that still covers everything we ship today and everything on the roadmap, what would it look like?*
> Grounded in: `README.md`, `docs/PRINCIPLES.md`, `SKILL-INDEX.md` (74 skills), `specs/DEEPEN-ARCHITECTURE-REVIEW.md`, `specs/sdd-adequacy-ranking.md`, `specs/release-plan.yaml` (e28–e48), `specs/epics/e48-prior-art-audit` (28-repo opensrc survey), and a web scan of the 2026 SDD landscape (BMAD, Spec Kit, GSD, OpenSpec).

---

## 1. What bigpowers is today

A prescriptive, spec-driven, test-first methodology for solo developers building with AI agents. It is a **chronological layer cake** of engineering discipline compiled into 74 verb-noun *skills*, a YAML *cockpit* (`specs/state.yaml` + `release-plan.yaml`), a 6-phase lifecycle with hard gates, a 94% Gherkin-compliance threshold, BCP velocity tracking, and a sync pipeline that projects one `SKILL.md` source into Claude Code, Cursor, Gemini CLI, and pi artifacts.

## 2. How software engineering "evolves" through the stack

Each layer resolves a tension the previous one created — this is the intellectual spine we must preserve in any rebuild:

| Era | Layer | Adds | Fixes the flaw of |
|---|---|---|---|
| 2008 | Uncle Bob — Clean Code | SRP, Boy Scout, F.I.R.S.T, naming | (foundation) |
| 2018 | Ousterhout | Deep modules, information hiding | small-functions-only → shallow modules |
| 2023–24 | Karpathy / Superpowers / Pocock | think-first, verb-noun skills, zoom-out | raw LLMs have no discipline |
| 2024 | Wasowski (SDD) / BCP | spec-as-interface, BDD loop, sizing unit | agents drift without a verifiable spec |
| 2026 | Akita | grep-ability, JSON logs, token economy, remediation hints | Clean Code was written for humans, not agents |
| Synthesis | BMAD + GSD | 6-phase loop, hard gates, 94% gate, YAML cockpit | principles aren't an executable discipline |

The rebuild keeps the layer cake as *doctrine* but stops letting doctrine sprawl into 74 overlapping skills and 27 restating reference docs.

## 3. The gaps and non-conformances a rebuild must close

Drawn directly from `DEEPEN-ARCHITECTURE-REVIEW.md` and the e48 prior-art audit:

| # | Gap / non-conformance | Evidence |
|---|---|---|
| G1 | **Sync is copy-paste-variant, not parse→IR→render** — adding a target edits the loop body; frontmatter is parsed 5× per run in 3 drifting awk variants | Review §5.1 |
| G2 | **Path-resolution boilerplate duplicated across 13 scripts**; flat 31-script dir with abandoned `bp-` prefix | §5.2, §5.7 |
| G3 | **~50 of 74 skills have tautological verify commands** (`test -f SKILL.md`) — violates the "every change verifiable by one command" mandate | §5.3 |
| G4 | **Near-cousin skill clusters** — bug (3), delegate (2), grill (2), verify (3), review (3) share 70–80% of their body | §5.4 |
| G5 | **Hub-and-spoke doc duplication** — F.I.R.S.T restated in 6 places, Boy Scout in 5; 27 reference docs largely re-state CONVENTIONS + PRINCIPLES | §5.5 |
| G6 | **No context-rot mitigation as a first-class concern** — no `effort:` frontmatter, no lifecycle hooks, no spawn-vs-inline signal (GSD's core idea) | §5.6 |
| G7 | **Index integrity bug** — `get_phase()` hardcoded case statement silently drops 3 skills; badge/table count mismatch | Bugs 1 & 3 |
| G8 | **Broken references** — 4 skills point at `specs/tech-architecture/*.md` files that don't exist; stale `.bak` in features dir | Bugs 2 & 4 |
| G9 | **Missing verification depth** — no ambiguity critic (Spec Kit), no completeness/gap critic (GSD nyquist), no failing→passing task ledger (MoAI), no with/without-skill eval delta (anthropic/skills) | e48 s05–s07, s01 |
| G10 | **No caching/backstop** — doc fetches un-cached; token limits are prose advice, not a mechanical PreToolUse hook | e48 s02, s04 |

## 4. Clean-slate architecture

The core insight: **most of the 74 "skills" are really three different kinds of thing wearing the same costume.** Separate them.

```
┌──────────────────────────────────────────────────────────────┐
│ KERNEL  (runtime — not skills; this is what "installs")       │
│  • Cockpit:  specs/ YAML (state, release-plan, exec-status)   │
│  • Sync engine: parse → IR (skill.json) → render N targets    │
│  • scripts/lib/: one shared bash+py library (paths, frontmtr) │
│  • Effort-aware loader: reads effort: light|standard|heavy    │
│  • Guardrails: PreToolUse token/size hooks + guard-git        │
│  • Doc cache: ETag-revalidated fetch (Context7/bts docs)      │
│  • Benchmark harness: with/without-skill pass@k + token delta │
│  • Compliance: Gherkin features + 94% gate + rule-matrix.json │
└──────────────────────────────────────────────────────────────┘
        ▲ every skill is authored once as SKILL.md, projected everywhere
┌───────────────┬───────────────┬──────────────────────────────┐
│ CORE-LOOP     │ SPECIALISTS   │ SUSTAIN / UTILITIES           │
│ (the golden   │ (called on    │ (transversal, any phase)      │
│  path, ~12)   │  demand, ~18) │  (~8)                         │
└───────────────┴───────────────┴──────────────────────────────┘
        +  OPTIONAL PACKS (not core): web-design, docs-site,
           distribution, migration — installed only if needed
```

Three doctrine rules make the rebuild *conformant by construction*:

1. **One canonical statement of every principle.** Rules live only in `CONVENTIONS.md` (behavioral) and `docs/PRINCIPLES.md` (provenance). Reference docs become thin pointers, not restatements. (closes G5)
2. **Every skill's `verify:` asserts an artifact, not a file's existence.** No skill ships without a behavioral verify command; the sync engine rejects tautological ones. (closes G3)
3. **Every skill declares `effort:` and `spawn: inline|subagent`.** The loader and orchestrators use it to stay lean. (closes G6)

## 5. The lean skill catalog (74 → 41 core + optional packs)

Merges use a **mode flag** instead of a sibling skill (the review's recommendation for clusters A–C, E). Kernel-ized items leave the catalog entirely.

### Core loop — 12 (the path every project walks)

| New skill | Absorbs / replaces | Note |
|---|---|---|
| `using-bigpowers` | using-bigpowers | one-time bootstrap |
| `orchestrate-project` | orchestrate-project | 6-phase meta-loop; now effort:heavy, spawns |
| `survey-context` | survey-context + session-state (resume half) | cold-start + handoff read |
| `research-first` | research-first | opensrc/prior-art gate |
| `elaborate-spec` | elaborate-spec | rough idea → spec |
| `plan-work` | scope-work + slice-tasks + plan-work + define-success | one 3-stage planning spine; emits failing→passing `tasks.yaml`; runs ambiguity critic |
| `plan-release` | plan-release + change-request | WSJF release index + reorder |
| `build-epic` | build-epic + execute-plan | 8-step story cycle / batch |
| `develop-tdd` | develop-tdd + enforce-first | RED-GREEN-REFACTOR with F.I.R.S.T inline |
| `verify-work` | verify-work + validate-fix + simulate-agents | `--scope full\|fix`; completeness/gap critic built in |
| `commit-message` | commit-message | Conventional Commits + semver |
| `release-branch` | release-branch | land / PR / semantic-release |

### Specialists — 18 (invoked when the situation calls)

| New skill | Absorbs / replaces |
|---|---|
| `map-codebase` | map-codebase |
| `search-skills` | search-skills |
| `grill` | grill-me + grill-with-docs + model-domain (`--docs`, `--domain`) |
| `define-language` | define-language |
| `design-interface` | design-interface |
| `deepen-architecture` | deepen-architecture |
| `seed-conventions` | seed-conventions |
| `assess-impact` | assess-impact |
| `plan-refactor` | plan-refactor |
| `kickoff-branch` | kickoff-branch + setup-environment |
| `spike-prototype` | spike-prototype |
| `quick-fix` | quick-fix |
| `fix-bug` | fix-bug + investigate-bug + diagnose-root (`--rca`) |
| `audit-code` | audit-code + inspect-quality |
| `review` | request-review + respond-review (`--stage request\|respond`) |
| `run-evals` | run-evals + run-benchmark |
| `security-review` | security-review |
| `trace-requirement` | trace-requirement + validate-contracts |

### Sustain / utilities — 8 (transversal; effort:light)

| New skill | Absorbs / replaces |
|---|---|
| `session-state` | session-state (write half) |
| `terse-mode` | terse-mode (now auto-triggered by kernel hook) |
| `delegate` | delegate-task + dispatch-agents (`--mode seq\|parallel`, `--review staged\|none`) |
| `organize-workspace` | organize-workspace |
| `reset-baseline` | reset-baseline |
| `write-document` | write-document + edit-document (`--edit`) |
| `craft-skill` | craft-skill + evolve-skill + stocktake-skills (`--evolve`, `--audit`) |
| `compose-workflow` | compose-workflow |

### Optional packs — installed only when relevant (not in the 41)

| Pack | Skills folded in |
|---|---|
| **web-design** | align-grid, extract-design |
| **ops/deploy** | wire-ci, wire-observability, deploy + smoke-test, publish-package |
| **distribution** | cross-tool sync targets, docs-site generator, public-receipts |
| **migration** | migrate-spec + migrate-version |
| **dashboard** | visual-dashboard |

Kernel-ized (leave the skill catalog): `guard-git`, `hook-commits` → guardrail hooks; `setup-environment` → folded into kickoff; index/lock/compliance scripts → kernel.

**Result: 74 skills → 41 authored skills (12 core + 18 specialist + 8 sustain + 3 orchestrators counted in core), plus 5 optional packs and a kernel that owns everything that was previously a shallow script or duplicated rule.**

## 6. User journey (the golden path)

```
INSTALL                bigpowers setup            → kernel + core loop linked to your agent
FIRST RUN              using-bigpowers            → learns the loop, picks first skill

DISCOVER   survey-context → research-first → elaborate-spec        (map-codebase if brownfield)
ELABORATE  grill (--docs/--domain) → define-language → design-interface → deepen-architecture
PLAN       plan-work  ── scope → slice → tasks.yaml(failing) → ambiguity critic
           plan-release (WSJF) → assess-impact for risky changes
BUILD      per story, build-epic drives:
             kickoff-branch → develop-tdd → verify-work → audit-code
             → commit-message → release-branch
VERIFY     verify-work (completeness critic) → run-evals → security-review → trace-requirement
RELEASE    release-branch → semantic-release → tag

Anytime: session-state (resume), terse-mode (auto), delegate (offload), fix-bug (--rca),
         quick-fix (trivial), reset-baseline, craft-skill (--evolve/--audit)
```

A single `handoff.next_skill` in `state.yaml` still lets any interruption resume exactly where it stopped — but now `effort:` + `spawn:` tell the orchestrator when to fan work out to a fresh-context subagent instead of bloating the main context.

## 7. Feature-parity map — nothing is lost

Every capability shipping today (or planned) has a home. Grouped by outcome:

| Current capability | Where it lives in v3 | Disposition |
|---|---|---|
| 6-phase lifecycle + hard gates | `orchestrate-project` + kernel gates | kept |
| 8-step story cycle | `build-epic` | kept |
| Planning spine (scope/slice/plan/success) | `plan-work` (3-stage) | **merged 4→1** |
| Bug pipeline (investigate/diagnose/fix) | `fix-bug --rca` | **merged 3→1** |
| Grilling (me/docs/domain) | `grill --docs --domain` | **merged 3→1** |
| Delegation (single/parallel) | `delegate --mode` | **merged 2→1** |
| Verify + validate-fix + simulate | `verify-work --scope` | **merged 3→1** |
| Review request/respond | `review --stage` | **merged 2→1** |
| Evals + benchmark | `run-evals` | **merged 2→1** |
| Skill lifecycle (craft/evolve/stocktake) | `craft-skill --evolve --audit` | **merged 3→1** |
| Docs (write/edit) | `write-document --edit` | **merged 2→1** |
| BCP velocity, cycle-times, WSJF | kernel cockpit + `plan-release` | kept |
| Gherkin 94% compliance gate | kernel compliance | kept |
| semantic-release automation | kernel + `release-branch` | kept |
| YAML cockpit + next_skill handoff | kernel + `survey-context`/`session-state` | kept |
| Multi-runtime sync (Claude/Cursor/Gemini/pi) | kernel parse→IR→render | **re-architected (G1)** |
| MCP server (10 tools) | kernel | kept |
| guard-git / hook-commits / env setup | kernel guardrails / `kickoff-branch` | **kernel-ized** |
| CI / observability / deploy / publish | **ops/deploy pack** | pack |
| align-grid / extract-design / design-interface | **web-design pack** (design-interface stays core) | pack |
| migrate-spec / migrate-version | **migration pack** | pack |
| visual-dashboard | **dashboard pack** | pack |
| effort budgeting / context-rot | kernel effort-loader + auto terse-mode | **NEW (closes G6)** |
| ambiguity + completeness + gap critics | `plan-work` / `verify-work` | **NEW (closes G9)** |
| failing→passing task ledger | `plan-work` tasks.yaml | **NEW (closes G9)** |
| doc cache + token PreToolUse hooks | kernel | **NEW (closes G10)** |
| versioned rule-matrix.json | kernel compliance | **NEW (from e48 s09)** |

## 8. Sequential roadmap — delivering it all in order

Six releases. Each row shows the existing epics it subsumes, so the current backlog (e28–e48) is fully absorbed, not discarded. Ordering follows impact-to-effort from the review's priority tiers.

| Release | Theme | Delivers | Absorbs existing epics | Gaps closed |
|---|---|---|---|---|
| **R0 — Foundation Fixes** | make it conformant | Fix `get_phase()` + count; remove tautological verifies (or make behavioral); delete stale `.bak`; repair 4 broken refs | (hotfix) | G3, G7, G8 |
| **R1 — The Kernel** | extract the runtime | `scripts/lib/` shared library; parse→IR→render sync engine; effort-aware loader; guard-git/hook-commits → hooks | e28 (sync refactor), e37 (BCP sizing) | G1, G2 |
| **R2 — Lean Catalog** | 74 → 41 | Execute all cluster merges via mode flags; kernel-ize scripts; split optional packs; regenerate index from IR | e36 (doc dedup), e35 (historical refs → provenance pointers) | G4, G5 |
| **R3 — Context Discipline** | close GSD's gap | `effort:` + `spawn:` frontmatter live; auto terse-mode via PreToolUse token/size hooks; doc ETag cache | e39 (semantic bridge), e48 s02/s04 | G6, G10 |
| **R4 — Verification Depth** | close SDD-critic gap | ambiguity critic in `plan-work`; completeness/gap critic in `verify-work`; failing→passing `tasks.yaml`; with/without-skill eval delta; rule-matrix.json | e46 (risk-based verify), e42 (golden stories), e48 s01/s05/s06/s07/s09 | G9 |
| **R5 — Reach & Proof** | packs + evidence | ops/deploy, distribution, migration, dashboard packs; docs-site; public receipts; showcase repo; global install + per-project seed | e44, e45, e47, e41, e43, e33, e32 (done) | reach |

Cutover strategy: R0–R1 ship on the current tree (no user-visible change). R2 is the breaking rename — publish a `migrate-version` shim so existing projects re-point old skill names to merged skills automatically. R3–R5 are additive.

---

## 9. Red-team review

An adversarial pass over §4–§8. Each finding is rated **KILL** (could sink the plan), **WOUND** (needs a design change), or **SCRATCH** (watch it).

### 9.1 The mode-flag merges are the weakest claim — WOUND
The review that recommended merging clusters (A–C, E) is the *same* document that warns clusters D and F are "genuinely distinct — keep separate." My proposal merges more aggressively than the source evidence supports. Concrete risks:
- **`grill` absorbing `model-domain` is a category error.** grill-me stress-tests a *plan*; model-domain grills against an *existing domain model*. Different inputs, different failure modes. A `--domain` flag hides a real seam. **Fix:** keep `model-domain` separate, or make it a first-class mode with its own verify.
- **`verify-work` absorbing `simulate-agents` conflates a gate with a technique.** simulate-agents runs Mock-User/Auditor in fresh contexts; that's a *how*, not a scope. Folding it in risks the "party mode" bloat BMAD is criticized for. **Fix:** leave `simulate-agents` in Sustain.
- **Mode flags don't reduce cognitive load the way skill deletion does** — the surface area moves from "which skill?" to "which flags?", and flags are *less* discoverable than named skills in a `search-skills` lexicon. Net token savings may be smaller than implied.

### 9.2 "41" is a vanity metric that fights the product — SCRATCH→WOUND
The README markets the skill count as a feature and it's auto-stamped. Cutting to 41 is defensible for *maintenance*, but the redesign never proves users are confused by 74. There is no usage data cited. Optimizing a number nobody complained about, while forcing a breaking rename (R2), risks negative ROI. **Fix:** gate R2 on evidence — instrument `skill_timings`/invocation counts first; merge only clusters with measured co-invocation or drift.

### 9.3 The kernel/pack split moves complexity, doesn't delete it — WOUND
Kernel-izing guard-git, hook-commits, env-setup, and the sync scripts is the classic "shallow module → deep module" trade — but a kernel is *harder to change and test* than a script. The proposal asserts benefits (locality, one place for the BSD-sed bug) without a test strategy for the kernel itself. A monolithic kernel with an IR is exactly where a subtle regression can silently corrupt all four runtime targets at once — higher blast radius than today's copy-paste (which fails one target loudly). **Fix:** R1 must ship the parse→IR→render engine *with a golden-fixture test per target* (this is what e42 golden stories should gate), or the refactor trades visible breakage for invisible breakage.

### 9.4 Packs create a discovery + support-matrix problem — SCRATCH
Splitting into optional packs means the golden path can now *fail to find* a skill a user expects (e.g. `deploy`). For a solo-dev tool, "install another pack" is friction at exactly the wrong moment. It also multiplies the compliance/test matrix (core × pack combinations). **Fix:** ship packs but default-install the ops/deploy pack; treat only web-design/dashboard/migration as truly optional.

### 9.5 Sequencing risk: R4 depends on judgment the tool can't yet self-check — WOUND
The "critics" (ambiguity, completeness/gap) are LLM-judgment steps. Adding them as *hard gates* (BLOCKER aborts merge, per e48 s06) can produce false-positive stalls that train users to bypass gates — the exact failure the 94% threshold was meant to prevent. **Fix:** land critics as **advisory** (WARNING) for one release, measure false-positive rate against the golden suite, and only promote to BLOCKER once calibrated.

### 9.6 The cutover shim is under-specified — KILL-if-ignored
R2 renames skills that are referenced by string across `.cursor/rules`, `.gemini`, `.pi`, `CLAUDE.md`, epic capsules, and — critically — *users' own projects and muscle memory*. "publish a migrate-version shim" is one line covering the single highest-risk operation in the plan. Old skill names are also in the wild (npm-published, indexed by agents). **Fix:** R2 must ship (a) permanent name aliases in the IR (old→new) that never break, not a one-time migration, and (b) a deprecation window with telemetry before any name is removed. Treat skill names as a public API under semver.

### 9.7 Things the proposal got right (steelman survives)
- Closing G3 (behavioral verifies), G7/G8 (index + broken refs) is pure upside, low risk — R0 is correct and should ship immediately.
- Extracting `scripts/lib/` (G2) is unambiguously good; 49 duplicated lines across 13 scripts is real debt.
- Adding `effort:`/`spawn:` (G6) borrows GSD's best idea at low cost and is additive — safe.
- The doctrine rule "one canonical statement per principle" (G5) is the highest-leverage, lowest-risk change and is under-emphasized relative to the flashier merges.

### 9.8 Revised recommendation
Ship **R0 and R1 as proposed** (fixes + kernel with golden-fixture tests). **Before R2**, collect invocation telemetry and only merge measured-redundant clusters; keep `model-domain` and `simulate-agents` standalone. Make R4 critics advisory-first. Treat skill names as a semver'd public API with permanent aliases, not a migration. The strongest version of this plan optimizes for *drift elimination and conformance*, not for a smaller headline number.

---
*End of proposal.*
