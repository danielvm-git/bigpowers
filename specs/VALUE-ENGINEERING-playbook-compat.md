# Value Engineering — Anthropic AI-native SDLC Playbook Compatibility

**Date:** 2026-10-30 (pass 2, after the epic renumbering) · **Version analysed:** bigpowers v2.88.17
**Method:** CPSBok ch. 10 Value Engineering (driver → capability → value component → value/cost → risk → activation roadmap), sized with BCP 13D (ciandt-oss/bcp-agent rubric), ordered by value per BCP. WSJF stays the epic-level index in `release-plan.yaml`.
**Inputs:** "The AI-native SDLC playbook" (Anthropic, 2026-08-21) · a red-team review in a fresh context · Claude Code `mods/agents-md` source · every epic with status `scoped`.

**Epic IDs** follow the renumbering: e82 → **e49**, e58 → **e50**, e57 → **e52**, e59 → **e58**, e75 → **e59**. Each renamed `epic.yaml` carries the old ID in `formerly:`.

## 1. What changed in pass 2

Pass 1 ranked only the six new epics (e83–e88) plus one story added to the evals epic. Pass 2 ranks **all 12 scoped epics** on one scale. Four findings change the plan:

| Finding | Evidence | Effect |
|---|---|---|
| **e49 is already shipped.** The cockpit ranks it second (WSJF 6.0). | PR #118 merged `feat(e82): upstream fork innovations`. 10 of the 11 task `verify:` commands pass. The one that fails (`e49s03` t04) checks `package.json` for `omp.extensions`, but the key is `pi.extensions` (see the pi fork contract). | Remove it from the queue. One 6-BCP close-out: fix the stale verify, mark s01–s04 done with evidence. |
| **e59 targets the wrong repository.** | `aaditmshah/augment` is "the world's smallest and fastest classical JavaScript inheritance pattern", last pushed 2019-03-01. The Augment Code agent CLI is `augmentcode/auggie`. | Send it back to elaboration (CMS 1). Do not build. |
| **The BCP column mixes two scales.** The `*` values (e50 9, e52 8, e56 13, e58 6, e59 4) are old size points; e83–e88 are 13D counts. | Recounting the planned stories with the 13D rubric gives e50 71, e52 55, e56 70, e58 50, e59 28: **5.4–8.3× the old figures**. | Compare epics only on 13D. Record `bcps_projected_13d` next to `bcps_projected`. |
| **The evals package costs 57 BCP, not 26 + 9.** | P9 credit needs the runner (26) + the representative subset (e50s01, 13) + calibration in CI (e50s02, 18). | Value per BCP falls from 1.92 to 0.88. "Agent at the PR" now comes before evals. |

### Red-team corrections from pass 1 (still in force)

| First analysis said | Red team found | Effect |
|---|---|---|
| 63% coverage, 15 plays | The arithmetic gave 66.7%. Play 15 (on-call in a chat tool) is out of scope ("SaaS tracker integrations", SCOPE/VISION). | Baseline is **9.5 / 14 applicable plays = 68%** |
| Plan intent: Partial | P0 `[no-direct-coding]` and the SCOPE/VISION/epic `source:` fields already carry intent | Strong |
| CLAUDE.md: Strong | 399 lines breaks bigpowers' own P2 300-line cap; ~60% is tool boilerplate | Partial |
| Generated paths: prose only | CI `git diff --exit-code` already catches `.cursor/`, `.gemini/`, `.pi/` drift; `website/src/content/docs` is not in the diff, and there is no edit-time hook | Shift left, add website docs |
| No test lock | `verify-tdd-red-commit.sh` exists (e80s03) but nothing calls it except prose | Wire it into CI and a hook |
| Ship evals, retire the 94% first | Duplicates e50, whose own order is advisory first, demote after calibration | Merged into e50 as one added story |
| New `watch-bands` skill | Breaks the catalog freeze; detection is deterministic, so B3 makes it a tool | Kernel script on the existing daily cron |
| Prose intent.md views | Solo-developer target; writable copies would create a second source of truth | Dropped (epics-wiki already renders YAML) |
| Plugin distribution | Deliberately deferred in SCOPE (depends on the MCP server) | Dropped; reopen through change-request |
| Drift fix is a one-day job | Each defect goes through the fix-or-log ladder | Sliced as e83, 47 BCP |

The main risk is unchanged: **chasing playbook compatibility could quietly turn a multi-harness framework into a Claude-only one**. Every story below is harness-neutral or opt-in.

## 2. Driver analysis

| Driver | Weight | Source | How it constrains the components |
|---|---|---|---|
| **D1 Playbook compatibility** (primary) | ranks first | User request | Adherence = coverage points each story adds |
| D2 Senior-grade quality and a truthful cockpit | 3 | VISION north star, Always Green | Gates and human triage stay; agents read only true indicators |
| D3 Harness neutrality | 2 | Multi-harness hooks and adapters | Claude-only features ship as an adapter with a fallback |
| D4 Doctrine and the bigspec migration | 3 | B3, B8, B9, Capstone, catalog freeze | No new skill directories during the freeze; tools go in the kernel |
| D5 Solo developer | 2 | SCOPE / VISION | Team-only plays are out of scope; paid API steps are opt-in |

D1 orders the main curve (§5). D2–D5 order the parallel lane (§6) as Σ(weight × adherence 0–3) per 100 BCP. These adherence scores are judgement calls; challenge them in review.

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
| P9 CI evals | Partial | Strong | e50 runner + e50s01 + e50s02 |
| P10 PR review | Partial | Strong | e87s01 |
| P11 Approval gates | Partial | Strong | e86s04 |
| P12 CI/CD | Partial | Strong | e87s02, e87s03 |
| P13 Closing the loop | Weak | Strong | e88s01, e88s03 |
| P14 Recurring scans | Weak | Strong | e88s02, e88s03 |
| P15 On-call in chat | N/A | N/A | Out of scope |

## 4. Value components — every scoped epic

BCP is counted from a 13D element table per story, never typed by hand. For e83–e88 the tables are in each `epic.yaml` under `bcp_13d`. For the unsliced epics they are projections from `planned_stories`. No count is calibrated yet: recount everything with the e85 procedure once it ships.

| Epic | WSJF | BCP (13D) | Old `*` | Coverage points | Maturity (CMS ≥ 3) | VE verdict |
|---|---|---|---|---|---|---|
| **e84** AGENTS.md First | 10.5 | 36 | — | 0.50 | pass | Wave 1 |
| **e49** Fork Innovations | 6.0 | 6 to close | 8 | 0 | pass | **Shipped — close in Wave 0** |
| **e83** Truth in the Cockpit | 6.0 | 47 | — | 0 (enabling) | pass | s05 Wave 0; rest parallel lane |
| **e50** Evals Over Compliance | 5.3 | 71 | 9 | 0.50 | pass | s01, s02 + runner Wave 3; s03 parallel lane after calibration |
| **e52** Adopt OKF Envelope | 5.0 | 55 | 8 | 0 | pass | Parallel lane; s03 pairs with e83s03 |
| **e85** Count BCP the 13D Way | 4.3 | 42 | — | 0 (beyond playbook) | pass | Parallel lane, middle |
| **e86** Hooks Enforce | 4.2 | 98 | — | 1.00 | pass | s04 Wave 1; s01, s03 Wave 4; s02 lane; **s05 cut** |
| **e56** Reclassify Catalog | 3.8 | 70 | 13 | 0 | s03, s04 fail | s01, s02 parallel lane; elaborate s03, s04 |
| **e58** Absorb Fresh References | 3.7 | 50 | 6 | 0 | s01 fails | Park — after e52 |
| **e59** Integration: Augment | 3.0 | 28 | 4 | 0 | fails (CMS 1) | **Return to elaboration** |
| **e87** Agent at the PR | 2.6 | 71 | — | 1.00 | pass | s01, s02 Wave 2; s03 Wave 4 |
| **e88** Maintain Loop Starts Itself | 2.4 | 80 | — | 1.50 | pass | s01, s03 Wave 3; s02 Wave 4 |

**Backlog total: 654 BCP.** 284 BCP buys every playbook point (§5). 370 BCP carries doctrine and quality value (§6), 93 of it parked or cut (e58, e59, e86s05).

Projected 13D counts for the unsliced stories:

| Story | BCP | CMS | Story | BCP | CMS |
|---|---|---|---|---|---|
| e50s01 subset with real deltas | 13 | 3 | e56s01 classify every skill | 16 | 4 |
| e50s02 calibration beside compliance | 18 | 3 | e56s02 rules → constitution | 13 | 3 |
| e50s03 demote compliance | 14 | 4 | e56s03 tools → kernel | 14 | 2 |
| e50 runner (pass 1) | 26 | 4 | e56s04 merge and rename to ~28 | 27 | 2 |
| e52s01 OKF gap audit | 11 | 4 | e58s01 track constitution_version | 21 | 2 |
| e52s02 narrative envelopes | 30 | 3 | e58s02 diff-and-flag script | 18 | 3 |
| e52s03 data-OKF contracts | 14 | 4 | e58s03 absorb process doc | 11 | 3 |
| e49 close-out | 6 | 5 | e59 Wave A + Wave B | 15 + 13 | 1, 2 |

e52s02 sits at the 30-BCP slice limit, because it extends ten document kinds. Slice it by template family before you build it.

## 5. Value analysis — the playbook cost curve

Stories are picked greedily by coverage per BCP. Each pick carries its unmet prerequisites, and a prerequisite's own points count toward the package.

| # | Package | BCP | +Coverage | Per 100 BCP | Cumulative BCP | Coverage |
|---|---|---|---|---|---|---|
| — | Baseline | — | — | — | 0 | 67.9% |
| 1 | e84s01 AGENTS.md canonical in this repo | 14 | 0.50 | 3.57 | 14 | 71.4% |
| 2 | e86s04 production deploys ask first | 21 | 0.50 | 2.38 | 35 | 75.0% |
| 3 | e87s01 opt-in PR review | 31 | 0.50 | 1.61 | 66 | 78.6% |
| 4 | e50 runner + e88s01 bands + e88s03 diagnosis | 86 | 1.25 | 1.45 | 152 | 87.5% |
| 5 | e50s01 + e50s02 evals in CI, calibrating | 31 | 0.50 | 1.61 | 183 | 91.1% |
| 6 | e87s02 build triage note | 18 | 0.25 | 1.39 | 201 | 92.9% |
| 7 | e86s01 generated paths blocked at edit time | 19 | 0.25 | 1.32 | 220 | 94.6% |
| 8 | e88s02 weekly deterministic security scan | 20 | 0.25 | 1.25 | 240 | 96.4% |
| 9 | e86s03 secrets blocked before commit | 22 | 0.25 | 1.14 | 262 | 98.2% |
| 10 | e87s03 rollback and risk-tier autonomy | 22 | 0.25 | 1.14 | 284 | **100%** |

**66 BCP reaches 79%, 152 reaches 88%, 183 reaches 91%, 284 reaches 100%.** Pass 1 said 260; the extra 24 BCP is the honest cost of e50s01 and e50s02.

## 6. Value analysis — the parallel lane

These stories add no playbook points. They run on disjoint files beside the waves and are ranked by weighted driver value per 100 BCP.

| Rank | Story | BCP | D2 | D3 | D4 | D5 | Value | Per 100 BCP | Note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | e83s04 VISION refresh, freeze breaks | 8 | 1 | | 3 | | 12 | 150 | |
| 2 | e83s01 last_tag mirror, count stamping | 11 | 3 | | 1 | | 12 | 109 | |
| 3 | e50s03 demote compliance to advisory | 14 | 2 | | 3 | | 15 | 107 | Only after the e50s02 calibration data |
| 4 | e83s02 status counts owned skills only | 8 | 2 | | | 1 | 8 | 100 | |
| 5 | e56s01 classify every skill | 16 | 1 | | 3 | 1 | 14 | 88 | Read-only. Settles decision 1 and whether e86s05 is needed |
| 6 | e52s03 data-OKF contracts | 14 | 2 | | 2 | | 12 | 86 | Same files as e83s03: run them together |
| 7 | e52s01 OKF gap audit | 11 | 1 | | 2 | | 9 | 82 | |
| 8 | e83s03 receipts read the cycle-time ledger | 13 | 3 | | | | 9 | 69 | |
| 9 | e56s02 rules → constitution | 13 | | | 3 | | 9 | 69 | |
| 10 | e86s02 test lock and RED commit in CI | 21 | 3 | | 1 | | 12 | 57 | |
| 11 | e84s02 seed-conventions AGENTS.md-first | 22 | | 3 | | 3 | 12 | 55 | Pulled into Wave 1 for time criticality |
| 12 | e56s04 merge and rename to ~28 | 27 | | | 3 | 2 | 13 | 48 | CMS 2: slice before building |
| 13 | e56s03 tools → kernel | 14 | | | 2 | | 6 | 43 | CMS 2: elaborate after e56s01 |
| 14 | e85s01 + e85s02 count BCP the 13D way | 42 | 1 | | 2 | 3 | 15 | 36 | Calibrates every number in this file |
| 15 | e52s02 narrative envelopes | 30 | | | 2 | | 6 | 20 | Slice by template family |
| — | e86s05 freeze guard | 15 | | | 1 | | 3 | 20 | **Cut:** e56 ends the freeze it guards |
| — | e58 absorb fresh references | 50 | | | 1 | | 3 | 6 | Parked: needs e52; s01 fails maturity |
| — | e59 Augment integration | 28 | | 1 | | | 2 | 7 | Parked: wrong target repository |

## 7. Risk mapping

| Risk that can destroy value | Stories | Mitigation |
|---|---|---|
| Claude-only features break harness neutrality | e86s04, e87s01, e88s03, e50 runner | Adapter per harness; deny or skip fallback where a harness lacks the feature |
| The e50 calibration window delays P9 and P13/P14 credit | e50, e88s03 | Ship e88s01/s02 (deterministic) first; agent steps switch on after calibration |
| A solo developer pays for API calls they did not choose | e87s01, e87s02, e88s03, e50 runner | All opt-in templates; nothing paid runs by default |
| Gate fatigue from new hooks | e86 | Fast, path-scoped hooks; deny messages name the fix; e86s05 cut because e56 lifts the freeze |
| Agents read stale indicators | all | Wave 0 closes e49 and parks e59; e83 makes ledgers, receipts and mirrors truthful |
| e56 renames skills that other stories edit (seed-conventions, plan-release, deploy, survey-context) | e84s02, e85, e87s03, e56s04 | Every rename goes through `tombstone-skill.sh`; run e56s04 after the waves that edit those `SKILL.md` files |
| Old size points read as 13D BCP | e50, e52, e56, e58, e59 | Record `bcps_projected_13d`; the cockpit shows 13D only |
| AGENTS.md fallback differs from CLAUDE.md (8 known gaps in the mod README; Claude Code < 2.1.277; Bedrock/Vertex/Foundry) | e84 | Keep CLAUDE.md as a symlink to AGENTS.md: deduped in every agents-md mode, works on every version |

## 8. Value activation roadmap

| Wave | Stories | Wave BCP | Cumulative BCP | Coverage at end |
|---|---|---|---|---|
| **0 — Green and truthful first** | e83s05, e49 close-out, e59 back to elaboration | 13 | 13 | 68% |
| **1 — One file, one gate** | e84s01, e84s02, e86s04 | 57 | 70 | 75% |
| **2 — Agent at the PR** | e87s01, e87s02 | 49 | 119 | 80% |
| **3 — Evals and the self-starting loop** | e50 runner, e50s01, e50s02, e88s01, e88s03 | 117 | 236 | 93% |
| **4 — Close the rest** | e86s01, e88s02, e86s03, e87s03 | 83 | 319 | 100% |
| **Parallel lane** (disjoint files, no playbook points) | §6 ranks 1–15 except e84s02 | 242 | — | — |
| **Parked** | e58, e59 build, e86s05 | 93 | — | — |

Changes from pass 1:

- e87s02 moves up into Wave 2 next to e87s01. Both edit the CI templates, and its ratio (1.39) is almost equal to the evals package (1.45).
- Evals move from Wave 2 to Wave 3.
- e56s01 enters the lane early. It is read-only, and it answers decision 1.

## 9. Decisions for the owner

1. **Where the BCP counting procedure lives.** The owner wants a skill, not a program. During the catalog freeze, e85 ships it as `skills/plan-release/BCP-13D.md`. Alternative: a new `count-bcp` skill now, with a `freeze-exception` marker. e56s01's classification will show whether counting is a procedure (a skill) or a rule (constitution B9).
2. **Cut e86s05 (freeze guard) in favour of finishing e56.** The guard has value only while the freeze lasts, and e56 is what ends the freeze.
3. **Close e49 and send e59 back to elaboration** (Wave 0). The e59 target should probably be `augmentcode/auggie`. Confirm before anyone slices it.
4. **Upgrade Claude Code.** The local install is 2.1.270. The agents-md fallback needs 2.1.277 or later. The symlink plan works either way.
5. **Accept the drops.** Prose intent views (R3) and plugin distribution (R6) stay dropped, per SCOPE.
