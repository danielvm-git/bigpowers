# Value Engineering — Anthropic AI-native SDLC Playbook Compatibility

**Date:** 2026-10-30 · **Version analysed:** bigpowers v2.88.16 (main @ b814ed1a)
**Method:** CPSBok ch. 10 Value Engineering (driver → capability → value component → value/cost → risk → activation roadmap), sized with BCP 13D (ciandt-oss/bcp-agent rubric), ordered with WSJF.
**Inputs:** "The AI-native SDLC playbook" (Anthropic, 2026-08-21) · a red-team review in a fresh context · Claude Code `mods/agents-md` source.

## 1. What changed after the red team

A reviewer in a fresh context checked the first analysis against bigpowers' own doctrine. Corrections that change the plan:

| First analysis said | Red team found | Effect |
|---|---|---|
| 63% coverage, 15 plays | The arithmetic gave 66.7%. Play 15 (on-call in a chat tool) is out of scope ("SaaS tracker integrations", SCOPE/VISION). | Baseline is **9.5 / 14 applicable plays = 68%** |
| Plan intent: Partial | P0 `[no-direct-coding]` and the SCOPE/VISION/epic `source:` fields already carry intent | Strong |
| CLAUDE.md: Strong | 399 lines breaks bigpowers' own P2 300-line cap; ~60% is tool boilerplate | Partial |
| Generated paths: prose only | CI `git diff --exit-code` already catches `.cursor/`, `.gemini/`, `.pi/` drift; `website/src/content/docs` is not in the diff, and there is no edit-time hook | Shift left, add website docs |
| No test lock | `verify-tdd-red-commit.sh` exists (e80s03) but nothing calls it except prose | Wire it into CI and a hook |
| Ship evals, retire the 94% first | Duplicates e58, whose own order is advisory first, demote after calibration | Merged into e58 as one added story |
| New `watch-bands` skill | Breaks the catalog freeze; detection is deterministic, so B3 makes it a tool | Kernel script on the existing daily cron |
| Prose intent.md views | Solo-developer target; writable copies would create a second source of truth | Dropped (epics-wiki already renders YAML) |
| Plugin distribution | Deliberately deferred in SCOPE (depends on the MCP server) | Dropped; reopen through change-request |
| Drift fix is a one-day job | Each defect goes through the fix-or-log ladder | Sliced as e83, 47 BCP |

The red team also found issues the first pass missed: five catalog-freeze breaks, `check-spec-version-gap` reports `blocked`, and the receipts read the wrong metrics source. It also named the main risk of this goal: **chasing playbook compatibility could quietly turn a multi-harness framework into a Claude-only one**. Every story below is harness-neutral or opt-in.

## 2. Driver analysis

| Driver | Source | How it constrains the components |
|---|---|---|
| **D1 Playbook compatibility** (primary) | User request | Adherence = coverage points each story adds |
| D2 Senior-grade quality while scaling agentic autonomy | VISION north star | Closing the loop must keep gates and human triage |
| D3 Harness neutrality | Multi-harness hooks and adapters | Claude-only features ship as an adapter with a fallback |
| D4 Doctrine | B3 skill = procedure, catalog freeze, Always Green, P0–P3 | No new skill directories; tools go in the kernel |
| D5 Solo developer | SCOPE / VISION | Team-only plays are out of scope; paid API steps are opt-in |

## 3. Capabilities and KPIs

**KPI:** weighted play coverage (strong 1, partial ½, weak ¼, gap 0) over the 14 applicable plays.
**KGI:** 100% of applicable plays at Strong.

| Play | Now | Target | Activated by |
|---|---|---|---|
| P1 Intent | Strong | Strong | — |
| P2 Requirements and design | Strong | Strong | — |
| P3 Plan before code | Strong | Strong | — |
| P4 Instruction file | Partial | Strong | e84s01 |
| P5 Skills | Strong | Strong | — |
| P6 Build hooks | Partial | Strong | e86s01, e86s03 |
| P7 Parallel sessions | Strong | Strong | — |
| P8 Feedback loop | Strong (advisory RED gate) | Strong (enforced) | e86s02 (no coverage points, closes a known hole) |
| P9 CI evals | Partial | Strong | e58 (+ runner) |
| P10 PR review | Partial | Strong | e87s01 |
| P11 Approval gates | Partial | Strong | e86s04 |
| P12 CI/CD | Partial | Strong | e87s02, e87s03 |
| P13 Closing the loop | Weak | Strong | e88s01, e88s03 |
| P14 Recurring scans | Weak | Strong | e88s02, e88s03 |
| P15 On-call in chat | N/A | N/A | Out of scope |

## 4. Value components (sliced epics)

BCP comes from a 13D element table per story (in each `epic.yaml` under `bcp_13d`), never typed by hand. Calibration: none yet, so recount with the e85 procedure once it ships.

| Epic | Stories | BCP | Coverage points | Points per 100 BCP | WSJF |
|---|---|---|---|---|---|
| **e84** AGENTS.md First | 2 | 36 | 0.50 | 1.39 | 10.5 |
| **e83** Truth in the Cockpit | 5 | 47 | 0 (enabling) | — | 6.0 |
| **e58** Evals Over Compliance (+ runner story) | +1 | 26 added | 0.50 | 1.92 | 5.3 (existing) |
| **e85** Count BCP the 13D Way | 2 | 42 | 0 (beyond playbook) | — | 4.3 |
| **e86** Hooks Enforce | 5 | 98 | 1.00 | 1.02 | 4.2 |
| **e87** Agent at the PR | 3 | 71 | 1.00 | 1.41 | 2.6 |
| **e88** Maintain Loop Starts Itself | 3 | 80 | 1.50 | 1.88 | 2.4 |

WSJF ranks whole epics. Value engineering ranks stories, because three epics (e86, e87, e88) mix high- and low-yield stories.

## 5. Value analysis — the cost curve

Stories ordered by coverage per BCP. A story whose value needs a prerequisite is ranked as a package with it.

| # | Story | BCP | +Coverage | Cumulative BCP | Coverage |
|---|---|---|---|---|---|
| 0 | e83s05 spec-version-gap blocked (Always Green, not VE) | 7 | — | 7 | 67.9% |
| 1 | e84s01 AGENTS.md canonical in this repo | 14 | 0.50 | 21 | 71.4% |
| 2 | e86s04 production deploys ask first | 21 | 0.50 | 42 | 75.0% |
| 3 | e58 runner (+ e58 calibration and gate flip) | 26 | 0.50 | 68 | 78.6% |
| 4 | e88s01 control bands on the daily cron | 32 | 0.25 | 100 | 80.4% |
| 5 | e88s03 read-only agent diagnosis and scheduled review | 28 | 1.00 | 128 | 87.5% |
| 6 | e87s01 opt-in PR review | 31 | 0.50 | 159 | 91.1% |
| 7 | e87s02 build triage note | 18 | 0.25 | 177 | 92.9% |
| 8 | e86s01 generated paths blocked at edit time | 19 | 0.25 | 196 | 94.6% |
| 9 | e88s02 weekly deterministic security scan | 20 | 0.25 | 216 | 96.4% |
| 10 | e86s03 secrets blocked before commit | 22 | 0.25 | 238 | 98.2% |
| 11 | e87s03 rollback and risk-tier autonomy | 22 | 0.25 | 260 | **100%** |

The curve bends early: **100 BCP reaches 80%, 159 BCP reaches 91%, 260 BCP reaches 100%**. The other 140 BCP (e83 s01–s04, e84s02, e85, e86s02, e86s05) add no playbook coverage. They carry doctrine value, so they run in a parallel lane rather than being cut.

## 6. Risk mapping

| Risk that can destroy value | Stories | Mitigation |
|---|---|---|
| Claude-only features break harness neutrality | e86s04, e87s01, e88s03, e58 runner | Adapter per harness; deny or skip fallback where a harness lacks the feature |
| The e58 calibration window delays P9 and P13/P14 credit | e58, e88s03 | Ship e88s01/s02 (deterministic) first; agent steps switch on after calibration |
| A solo developer pays for API calls they did not choose | e87s01, e87s02, e88s03 | All opt-in templates; nothing paid runs by default |
| Gate fatigue from new hooks | e86 | Fast, path-scoped hooks; deny messages name the fix; freeze guard lifts when e56 merges |
| Agents read stale indicators | all | e83 makes ledgers, receipts and mirrors truthful before value is reported |
| AGENTS.md fallback differs from CLAUDE.md (8 known gaps in the mod README; Claude Code < 2.1.277; Bedrock/Vertex/Foundry) | e84 | Keep CLAUDE.md as a symlink to AGENTS.md: deduped in every agents-md mode, works on every version |

## 7. Value activation roadmap

| Wave | Stories | Cumulative BCP | Coverage at end |
|---|---|---|---|
| **0 — Green first** | e83s05 | 7 | 68% |
| **1 — One file, one gate** | e84s01, e84s02, e86s04 | 64 | 75% |
| **2 — Evals and the self-starting loop** | e58 (with runner), e88s01, e88s03 | 150 + e58's own 9 | 87.5% |
| **3 — Agent at the PR** | e87s01, e87s02 | 199 | 93% |
| **4 — Close the rest** | e86s01, e88s02, e86s03, e87s03 | 282 | 100% |
| **Parallel lane** (disjoint files, no playbook points) | e83s01–s04, e85s01–s02, e86s02, e86s05 | +118 | — |

e84s02 moves into Wave 1 despite zero coverage points. It touches the same files as e84s01, and Claude Code 2.1.277 just made AGENTS.md-first the default for every seeded project (time criticality).

## 8. Decisions for the owner

1. **Where the BCP counting procedure lives.** The owner wants a skill, not a program. During the catalog freeze, e85 ships it as `skills/plan-release/BCP-13D.md` (skill content, allowed by the freeze). Alternative: a new `count-bcp` skill now, with a `freeze-exception` marker.
2. **Upgrade Claude Code.** The local install is 2.1.270. The agents-md fallback needs 2.1.277 or later. The symlink plan works either way.
3. **Accept the drops.** Prose intent views (R3) and plugin distribution (R6) are dropped for now, per SCOPE.
