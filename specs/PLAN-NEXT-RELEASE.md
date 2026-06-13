# Plan: bigpowers Consolidation Release

**Status:** Proposed · **Date:** 2026-05-25 · **Shape:** one release, everything in it
**Supersedes:** `PLAN-ECC-INTEGRATION.md` and the phased v2.2.0→v3.0.0 sequence in `RELEASE-PLAN.md`
**Decision:** No deferred / "future" / "planned 📋" items remain. Every planned and forecasted
feature — plus the ECC harvest and the benchmark/stack-profile ideas — ships in this single cut.

> Versioning note: `semantic-release` picks the actual number at merge. This is a major release
> (new lifecycle phase + breaking taxonomy change), so it lands as the next **v3.0.0**.

---

## 1. Decision Lens

Every item ships only if it passes both filters:

1. **bigpowers principles** — curation over volume, language-agnostic core, documentation-based
   (Markdown/Bash, zero external SDK), minimum-code mandate, verb-noun naming (ADR-0001),
   `specs/` as the single output location.
2. **Feature-test gates** — it must *reinforce*, never dilute, the suites in
   `specs/verifications/features/` (`karpathy`, `superpowers`, `pocock`, `akita`, `cleancode`,
   `conventions`).

The ECC **Decline** list (§7) is load-bearing: it is precisely the set that would have
regressed a gate or broken the architecture.

---

## 2. Release at a Glance

| Dimension | Before | After |
|---|---|---|
| Active skills | 44 | **58** (+14) |
| Planned (📋) skills | 6 | **0** (all promoted/built) |
| Lifecycle phases | (no Verify) | **+ Verify** phase (Build → Verify → Review) |
| Stack support | per-project ad hoc | `profiles/` packs stamped by `seed-conventions` |
| Self-evolution | none | benchmark-gated `evolve-skill` loop |

**14 new skills:** `research-first`, `verify-work`, `run-evals`, `scope-work`, `slice-tasks`,
`grill-with-docs`, `diagnose-root`, `setup-environment`, `reset-baseline`, `stocktake-skills`,
`evolve-skill`, `search-skills`, `compose-workflow`, `simulate-agents`.

**~17 enhanced skills** (no count change) — see §5.

---

## 3. New Lifecycle Phase: Verify

`SPIKE-verify-work.md` flagged that the lifecycle ends at Build → Review with no "prove it
works" gate. The two verification skills get a dedicated **Verify** phase between Build and
Review:

```
Build (develop-tdd, execute-plan…) → ★ VERIFY ★ → Review (audit-code, request-review…)
                                       run-evals     (define + measure pass/fail across runs)
                                       verify-work   (multi-phase UAT gate, loop on gaps)
```

Review answers "is the code good?"; Verify answers "does the built thing do what was promised?"
Taxonomy edits: `SKILL-INDEX.md` phase table + Lifecycle Arc, and `survey-context` lifecycle map.

---

## 4. Workstreams

One release, executed in WSJF order so it is not a blind big-bang. Each workstream is
benchmark-gated (run `bigpowers-benchmark` before/after) so the cut never regresses the score.

### WS1 — Security (slopcheck + code) · WSJF 4.5
- slopcheck in `plan-work`: tag every external package `[OK]` / `[SUS]` / `[SLOP]`; `[SUS]`/`[SLOP]` = HARD GATE.
- slopcheck checklist item in `audit-code`.
- **ECC fold:** OWASP Top 10 rubric → `audit-code`; secret-detection patterns (`sk-`, `ghp_`, `AKIA`) → `guard-git`.
- Reconcile `docs/references/security-threats.md` with the implementation (no drift).

### WS2 — Verification & Evals · WSJF 4.3
- **NEW `verify-work`** (Verify): cold-start smoke → build → typecheck → lint → tests → step-by-step UAT → gaps-closure loop. HARD GATE: no story "done" until its `## Verification Script` is confirmed.
- **NEW `run-evals`** (Verify): EDD — define capability + regression evals before building; code graders are `verify:` commands, model graders are an explicit rubric; log pass@k. Artefact `specs/EVALS-<feature>.md`.
- **ECC enhance `develop-tdd`:** RED (`test:`) → GREEN (`feat:`/`fix:`) → optional REFACTOR commit checkpoints; reuse `commit-message`.
- `plan-work` template gains a `## Verification Script` per story; `execute-plan` gains an interactive verification checkpoint.

### WS3 — Discovery & Planning skills · WSJF 4.0
- **NEW `research-first`** (Discover): look-before-build — search registries / repo / existing skills / web → adopt | extend | compose | build → implement minimum. Appends `## Prior Art` to the spec. After `survey-context`, before `elaborate-spec`.
- **NEW `scope-work`** (Plan): in/out boundaries → `specs/SCOPE.md`.
- **NEW `slice-tasks`** (Plan): vertical slices → `specs/TASKS.md`.
- **NEW `grill-with-docs`** (Elaborate): grill assumptions grounded in real library docs.

### WS4 — Ergonomics & Context economy · WSJF 3.8
- **NEW `setup-environment`** (Utility): pre-install deps / configure tools before work.
- **NEW `reset-baseline`** (Utility): restore project to a known clean state between runs.
- `handoff` capability folded into `session-state`: compact open decisions, last step, required reading into a single cold-start doc.
- **ECC fold:** strategic-compaction decision table → `session-state` (when to compact at phase transitions).
- `terse-mode` hardened with Pocock `caveman` rules (drop articles/filler; target 30% token reduction).
- `organize-workspace` gains an automated `.gitignore` suggester.

### WS5 — Context Isolation + Model Routing · WSJF 3.3
- `execute-plan` spawns every skill with a fresh, isolated context window.
- Every `SKILL.md` declares a `model:` tier (haiku / sonnet / opus) in frontmatter.
- `orchestrate-project` reads `model:` and routes accordingly; `STATE.md` is the sole decision-passing channel between spawns.
- **ECC fold:** iterative-retrieval priming section → `dispatch-agents` + `delegate-task` (dispatch → evaluate → refine, max 3 cycles).

### WS6 — Taxonomy & Provenance · WSJF 3.0
- Plan templates carry `type:` (feat/fix/refactor) and `context:` (domain/infra) metadata.
- `plan-work` mandates linking every step to an ADR or commit SHA; `audit-code` verifies metadata presence.

### WS7 — Architectural Complexity · WSJF 2.8
- Law of Demeter checklist in `audit-code` + `CONVENTIONS.md`.
- `deepen-architecture` emits a numeric Module Depth score (Ousterhout).
- `model-domain` adds a concurrency-safety audit (shared mutable state detection).
- **NEW `diagnose-root`** (Bug): 4-phase root cause — reproduce → isolate → hypothesize → verify.

### WS8 — Wave-Based Parallel Execution · WSJF 2.5
- `execute-plan` groups independent tasks into parallel waves; parses `depends-on:` from task entries; atomic `STATE.md` writes prevent races. (Built on WS5 isolation.)

### WS9 — Self-Evolution & AI Tier · WSJF 2.0
- **NEW `stocktake-skills`** (Sustain): sequential subagent batch audit of the catalog (Quick Scan: changed only; Full: all).
- **NEW `evolve-skill`** (Sustain): benchmark-driven, plan-gated evolution. Consumes a `bigpowers-benchmark` report → proposes a `plan-work` change → `craft-skill`/edit → re-runs benchmark to prove the lift → records the decision via `session-state`/ADR. This is `run-evals` pointed at bigpowers itself; learning is measured and versioned, never implicit (the opposite of ECC's declined instinct-extraction).
- **NEW `search-skills`**: natural-language → right skill. Implemented as a local lexical/keyword index over SKILL.md frontmatter (no embedding-service dependency — see §7 note).
- **NEW `compose-workflow`**: chain skills into a custom workflow recipe.
- **NEW `simulate-agents`**: run "Mock User" + "Auditor" agents against a feature before human review.
- `craft-skill` enhancement: draft a `SKILL.md` from a library README / API docs (auto-skill generator).
- Methodology Lenses: `specs/METHODOLOGY.md` encoding project reasoning modes (STRIDE, Cost-of-Delay); applied via `orchestrate-project` (mechanism, not a new skill).

### WS10 — Stack Profiles (optional, opt-in) · WSJF 1.8
- New `profiles/` directory with convention fragments: `swift.md` (swift test, swiftlint, MVVM), `typescript-vue.md` (vitest, vite, SFC conventions, prettier), `node-service.md`.
- `seed-conventions` stamps the chosen profile into a project's `CONVENTIONS.md`. Core skills stay language-agnostic — specifics live in the project, never in the shared catalog. Validated against `bigpowers-dock` (Swift) and a Vue repo as real profiles.

---

## 5. New & Changed Skills

**New (14):** `research-first`, `verify-work`, `run-evals`, `scope-work`, `slice-tasks`,
`grill-with-docs`, `diagnose-root`, `setup-environment`, `reset-baseline`, `stocktake-skills`,
`evolve-skill`, `search-skills`, `compose-workflow`, `simulate-agents`.

**Enhanced (no count change):** `plan-work`, `audit-code`, `guard-git`, `develop-tdd`,
`execute-plan`, `session-state`, `dispatch-agents`, `delegate-task`, `orchestrate-project`,
`terse-mode`, `organize-workspace`, `model-domain`, `deepen-architecture`, `survey-context`,
`seed-conventions`, `craft-skill`, plus `CONVENTIONS.md` (Demeter, verification mandate,
metadata mandate) and every `SKILL.md` (`model:` frontmatter).

---

## 6. Feature-Test Alignment

| Gate | Effect |
|---|---|
| `karpathy` | `research-first` (minimum viable), `run-evals` (verifiable success), `verify-work` (loop-until-correct). **Reinforced.** |
| `superpowers` | `verify-work` HARD-GATE + two-stage UAT; `simulate-agents` fresh-context review; iterative-retrieval. **Reinforced.** |
| `pocock` | compaction fold, `terse-mode` hardening, `model:` routing → token economy + cold-start compaction. **Reinforced.** |
| `conventions`/`cleancode` | RED/GREEN/REFACTOR checkpoints; metadata/provenance mandates. **Reinforced.** |
| `akita` | No language-specific skill added; specifics confined to `profiles/`; naming stays verb-noun. **No regression.** |

---

## 7. What NOT to Leverage (held firm)

Bulk-porting ECC's 232 skills (dilutes curation); `document-adr` / `handle-errors` / `test-e2e`
(redundant or language-specific); `google-antigravity-sdk` (external SDK breaks
documentation-based architecture); ECC `hooks.json` runtime (CLI-native vs cross-harness;
`hook-commits` covers git); ECC continuous-learning v2 instinct-extraction (unversioned drift —
replaced here by the benchmark-gated `evolve-skill`); ECC dashboard app (the `visual-dashboard`
*primitive* already covers it); AgentShield NPM (kept the OWASP rubric, not the tool).

> **Principle note on `search-skills`:** semantic vector search would imply an embedding
> dependency. To honor zero-external-dependency, it ships as a local lexical index over SKILL.md
> frontmatter. If true semantic search is later wanted, that becomes its own ADR'd decision.

---

## 8. Implementation Steps (ordered)

1. Add **Verify** phase to `SKILL-INDEX.md` (phase table + Lifecycle Arc) → verify: `grep -c "Verify" SKILL-INDEX.md`
2. Build the 14 new SKILL.md via `craft-skill`, verb-noun, each < 300 lines → verify: each path exists
3. Apply WS1–WS10 enhancements to the ~17 existing skills + `CONVENTIONS.md`
4. Add `model:` frontmatter to every SKILL.md → verify: `grep -rl "^model:" */SKILL.md | wc -l`
5. Create `profiles/` with `swift.md`, `typescript-vue.md`, `node-service.md`; wire `seed-conventions`
6. Update `survey-context` lifecycle map with the Verify phase
7. Register all new skills in `SKILL-INDEX.md` (count 44 → 58, 0 planned); update counts in `CLAUDE.md`, `GEMINI.md`, `README.md`
8. Rewrite `RELEASE-PLAN.md` + `STATE.md` to reflect the single consolidation release
9. Run `bash scripts/sync-skills.sh` → verify: reports `58 skills synced`; `.cursor/rules` + `.gemini/extensions` regenerate

## 9. Verification Plan

- **Count integrity:** `find . -maxdepth 2 -name "SKILL.md" | grep -v ".git\|.cursor\|.gemini" | wc -l` == 58, matches `SKILL-INDEX.md`.
- **Gates hold:** `npm run compliance` — all six suites ≥ 94% (no regression vs current ~94%).
- **Benchmark gate:** `bigpowers-benchmark` score ≥ pre-release baseline; `evolve-skill` loop demonstrated on one skill end-to-end.
- **Sync + naming + size:** sync clean; every new SKILL.md verb-noun and < 300 lines.

## 10. Sequencing & Risk (honest note)

This is a large major release: +14 skills, ~17 edits, a new phase, and a profiles mechanism.
Shipping it as one tag is the explicit choice — but it is executed in the WS1→WS10 order above,
with the benchmark gating each workstream, so a regression is caught at the workstream boundary
rather than at merge. If any single workstream fails its benchmark gate, it is the natural cut
line to split the release — but the default plan keeps it whole.

## 11. Out of Scope

External SDK / NPM runtime dependencies; an ECC-style hooks runtime; embedding-based semantic
search (lexical index instead); remote rule fetching; any of ECC's 232 skills imported wholesale.
