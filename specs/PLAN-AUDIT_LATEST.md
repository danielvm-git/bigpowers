# Plan Audit — e31 "Quality Guarantee Infrastructure" strategy (re-run)

**Date:** 2026-07-02 · **Verdict:** NOT READY (as specced) — direction is right, Gate 1 feasibility is unproven and hides an undecided design problem

**Plan audited:** `specs/epics/e31-quality-guarantee/epic.yaml` (8 stories, 22 BCP), `specs/QUALITY-GUARANTEE-STRATEGY.md` (source doc), `specs/RELEASE-PLAN-v2.45.0-DEEPENING.md` §e31, cross-checked against `specs/benchmarks/SCHEMA.md`, `skills/run-benchmark/SKILL.md`, and `.github/workflows/*.yml`.

**Question asked:** Is the e31 strategy the best and most feasible way to guarantee each improvement is an improvement?

**Short answer:** The three-gate *concept* is sound and sequencing quality gates before the content epics (e32–e36) is the right call. But e31 as specced bundles a cheap, deterministic, immediately-buildable half with an expensive, undesigned, agent-execution half — and prices the hard half at 5 BCP as if it were a shell script. Split it.

---

## Strategy Assessment (the core question)

### What is genuinely strong

| Aspect | Assessment |
|---|---|
| Three-gate structure (behavior / compliance / cost) | ✅ Sound. Mirrors standard regression + budget gating; each gate answers a distinct question. |
| Code graders over rubric graders | ✅ Correct diagnosis. Deterministic exit-0/1 graders are the only thing that can run in CI for free. |
| Sequencing e31 second, before e32–e36 | ✅ Right in principle — build the net before walking the wire. |
| G-04 (sync-pipeline self-test) | ✅ Fully deterministic, no agent needed, directly protects e33 (the sync refactor). Cheapest, highest-certainty story in the epic. |
| Baseline-pinning + delta reporting | ✅ Good pattern, reuses the existing `specs/benchmarks/reports/` convention. |

### Feasibility gaps (why NOT READY)

**Gap A — The execution mechanism for golden stories is undefined, and it's the whole problem.**
Golden stories G-01, G-02, G-03, G-05 require an *LLM agent* to execute 3–6-skill chains (e.g. survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code). A bash script cannot run a SKILL.md. The strategy doc waves at this once — "Runs the skill chain (**or a mock agent that follows the chain**)" — and never resolves it. The options are materially different products:
- **Headless agent** (`claude -p` / Agent SDK): real signal, but ~10–30 min and real API dollars *per story per run* — not the "12.3s" the doc's sample report shows. That sample output is only achievable for grader-only re-runs.
- **Mock agent**: circular — a scripted actor following the chain tests the graders, not the skills. Zero regression signal.
- **Manual runs**: not a gate.
This decision is a textbook **HARD GATE candidate** and it is not surfaced anywhere in the epic. e31s03 ("create run-golden-suite.sh", BCP 5) silently contains it.

**Gap B — Non-determinism is unaddressed.** Even with headless execution, agent runs flake. A single-run PASS/FAIL golden suite will produce false regressions and erode trust in the gate. The existing `specs/benchmarks/SCHEMA.md` already defines **pass@k** for exactly this reason — e31's golden stories ignore it.

**Gap C — The "after each story" cadence is unaffordable if Gate 1 is agent-driven.** The Deepening track has 38 stories. 4 agent-chain stories × 38 runs ≈ many hours and real API cost, solo. A gate that expensive gets skipped, and a skipped gate is worse than a cheaper one that always runs.

**Gap D — Gate 3's heuristic is a static file-size check wearing a token costume.** `sum(SKILL.md sizes) + state.yaml size + tool_calls × 500`: the first two terms are computable with `wc -c` (fine — a decent *skill-bloat* detector), but `tool_calls` is unknowable without an actual agent run. As specced, Gate 3 either quietly degrades to a static size budget (useful! but name it that) or silently depends on Gap A being solved.

**Gap E — A premise of the strategy doc is factually wrong.** §Gap 4 claims "`npm run compliance` runs in CI and enforces 94%." It does not — `.github/workflows/publish.yml` runs only `run-skill-verify.sh` + semantic-release; `sync-skills.yml` regenerates artifacts. Compliance is manual today. This matters because **wiring compliance into CI is the single cheapest, highest-value quality gate available** and it isn't even a story in e31.

**Gap F — e31's own verify commands are the tautology anti-pattern e30s04 exists to remove.** e31s04/s05/s07/s08 all verify by grepping for a keyword (`grep -q 'compliance…'`, `grep -q 'token…'`) — satisfiable by a comment. e31s03's `--dry-run` check is the only behavioral verify in the epic.

**Gap G — Match the gate to the actual threat.** What do the *following* epics threaten? e32/e34/e35/e36 are markdown/docs work; e33 refactors the sync scripts. Their regression surface is: sync pipeline breaks, compliance score drops, skill files bloat — **all covered by the deterministic gates** (G-04 self-test + compliance-in-CI + size budget). The agent-driven golden stories guard against behavioral chain regressions, which matter most when skill *content/logic* changes — real value, but the least urgent protection for this specific release, and by far the most expensive and uncertain part of the epic (e31s01 + e31s02 + most of e31s03 ≈ 11+ of 22 BCP).

## Principles Alignment (e31-specific)

| Check | Status | Note |
|---|---|---|
| Vertical slices | ⚠️ | s01 (fixture) and s02 (5 YAMLs) deliver nothing runnable until s03 exists — horizontal setup layers. G-04 alone would be a true vertical slice (runnable gate, day one). |
| Scope bounded | ❌ | Carried over from previous audit: `SCOPE_LATEST.yaml` still has no entry for the Deepening track. Unchanged since last run. |
| Success criteria | ⚠️ | "Golden suite passes" is well-defined *only if* the execution mechanism is; today it isn't. No flake policy, no pass@k threshold for golden stories. |
| HARD GATE candidates | ❌ | The Gate-1 execution-mechanism decision (headless vs mock vs manual) is unidentified and unpriced — buried in e31s03. |
| Domain language | ✅ | Golden story / gate / baseline / pass@k vocabulary is consistent with existing benchmark infra. |

## Pre-flight Answers

Unchanged from the previous audit (see git history of this file): test N/A, build `install.sh`, lint `sync-skills.sh`, CI GitHub Actions, solo-git, Markdown/Bash, existing codebase. One correction surfaced this run: **compliance is not currently a CI gate** — treat "CI platform" answers about quality gating accordingly.

## Recommended Restructure

Split e31 into two epics; the split preserves ~80% of the protection at ~40% of the cost, and defers the uncertain half behind an explicit design decision:

**e31-lite — Deterministic Quality Gates (~10 BCP, buildable today, no design risk):**
1. G-04 sync-pipeline self-test script (from e31s02's G-04 only — no fixture repo needed, it self-tests this repo).
2. Wire `npm run compliance` into **CI** (`publish.yml`) *and* as step 1 of the suite runner — fixes the false premise and closes the biggest real gap today.
3. Static size/bloat budget: per-skill and total SKILL.md byte budget vs pinned baseline (honest rename of Gate 3's feasible half).
4. Pin baseline report; CLAUDE.md/CONVENTIONS.md pre-merge mandate; evolve-skill integration.
5. Write **behavioral** verify commands for all of the above (run the script, assert the exit code — not `grep` for a keyword).

**e31-golden — Agent-Driven Golden Stories (defer; spike first):**
- Precondition: run `spike-prototype` on the execution harness — can a golden story chain run headless (`claude -p` / Agent SDK) with acceptable cost, wall-clock, and flake rate? Decide pass@k policy (e.g. 2-of-3) from the spike data.
- Only after the spike answers yes: build the minimal-api fixture, the 4 agent-chain golden YAMLs (G-01/02/03/05), and the agent-execution mode of run-golden-suite.sh.
- Cadence: per-**epic**, not per-story (Gap C) — per-story cadence is reserved for the free deterministic gates.

## Open Gaps

- [ ] **HARD GATE:** decide the golden-story execution mechanism before any golden-story BCP is spent — `spike-prototype` (headless harness) is the cheapest way to decide with data.
- [ ] Split e31 per above — re-run `plan-work` on the e31 capsule (currently a bare epic.yaml with no story specs or task files).
- [ ] Add a story to wire `npm run compliance` into `publish.yml` — currently missing entirely.
- [ ] Rewrite e31s04/s05/s07/s08 verify commands as behavioral checks (the e30s04 standard).
- [ ] Define flake policy / pass@k for golden stories (schema already supports it).
- [ ] Carried over, still open: `scope-work` back-fill for the Deepening track; `release-plan.yaml` e30–e36 duplication; `execution-status.yaml` e30s02 reconciliation.

## Verdict

**NOT READY** — e31 as specced is *not* the most feasible form of a sound strategy. The three-gate idea and the "gates before content" ordering survive scrutiny; the epic's construction doesn't: half of its BCP funds an agent-execution capability whose mechanism, cost, and flake behavior are undecided, while the cheapest highest-value gate (compliance in CI) is absent. Ship the deterministic half now (it fully covers the actual regression surface of e32–e36), and gate the golden-story half behind a spike.

Recommended next skill: **`spike-prototype`** (golden-story headless-execution harness) in parallel with **`plan-work`** to split the e31 capsule; then re-run `audit-plan` on the restructured epic.
