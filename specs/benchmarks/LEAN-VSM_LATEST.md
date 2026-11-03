# Lean value-stream measurement for the A/B benchmark — proposal

Status: proposal, 2026-11-03. Steps 2 and 3 (e58s08 stage classifier, e58s09 waste metrics) are
built; steps 4–6 are designs. Builds on e58s01–e58s07.

**First VSM at scale (e58s08, 2026-11-03).** 120 sandboxed runs (`pi-docker`, deepseek-v4.1-flash,
ab-09/11/13/17/19/20 × 2 arms × k=10): outcome equal (pass 0.98 vs 0.97, delta −0.02
[−0.08, +0.03]); bigpowers costs 2.0× and takes 1.7× the lead time.

| Arm | Lead | First build | Stage switches | Plan | Design | Build | Test | Deploy | Maintain |
|---|---|---|---|---|---|---|---|---|---|
| vanilla | 72 s | 16 s | 6.4 | 7% | 24% | **39%** | 31% | 0% | 0% |
| bigpowers | 124 s | **69 s** | 11.9 | 10% | 15% | **16%** | **50%** | 6% | 2% |

The extra time is mostly Test (50% of a longer run) and a 4× later first build, with twice the
task switching, and it buys no outcome on these tasks. 5 of 6 tasks were 10/10 on both arms, so
the tasks are still too easy to show where that testing would pay off.

**Waste metrics on the same 120 runs (e58s09, transcript part):**

| Arm | Test runs | Rework loops | Re-edits | Rereads | First-time-through | PCE |
|---|---|---|---|---|---|---|
| vanilla | 3.7 | 0.48 | 0.32 | 0.08 | 0.58 | 0.69 |
| bigpowers | **8.5** | **0.77** | **0.90** | 0.08 | 0.60 | 0.66 |

bigpowers runs 2.3× more tests, has 60% more failing runs after its first build and re-edits 2.8×
as often, for the same first-time-through rate. **Caveat:** PCE counts all test time as value
added, so heavy testing looks efficient. Step 4 should split test time into runs that found a
defect (value) and runs that repeated a green result (overprocessing). Patch metrics (`diff_ratio`,
leftovers, review load) need runs made after e58s09, since older runs kept no patch.

## Why

The benchmark answers "does bigpowers pass more tasks?". The answer so far is "not measurably",
while bigpowers costs more:

| Run | Result |
|---|---|
| k=10, 8 easy tasks (opencode, flash) | delta +0.01 [−0.05, +0.06] |
| Ablation, 3 tasks × 6 arms × k=10 (opencode, flash) | no arm beats vanilla; all cost +26% to +67% |
| ab-06 refactor gain | 13/13 vs 8/13 earlier; 9/10 vs 9/10 in the ablation, so it did not replicate |

Pass rate alone cannot say *where* the extra cost goes, so it cannot say what to remove. Lean asks
a different question: which steps of the value stream add value, and which are waste? Each run
already has a full transcript (e58s05), so we can map every run onto the stages of the
before/after-agents diagram and measure waste per stage.

## 1. A value stream map for every run

### Stages

Each assistant turn is assigned to one stage by the action it takes. Its wall time, tokens and
cost go to that stage.

| Stage (diagram) | In an agent run | Classified from |
|---|---|---|
| Plan (requirements) | reading the prompt, issue, spec, AGENTS.md, skills; writing plans | read/bash on `ISSUE`, `SPEC`, `AGENTS.md`, `skills/`, `specs/`; writes under `specs/` |
| Design | exploring the code to decide the change | read/grep/find/ls on source |
| Build | changing product code | edit/write on non-test source files |
| Test (review) | writing tests, running suites and checks | edit/write on test files; bash running `node --test`, `npm test`, scripts |
| Deploy (release) | branch, commit, tag, package | bash `git checkout -b/commit/merge/tag`, `npm version/publish` |
| Maintain | docs, bug notes, state files, cleanup | edit/write on `README`, `docs/`, `CHANGELOG`, `specs/bugs`, `state.yaml` |
| Wrap-up | final answer with no action | assistant turn with no tool call |

Outside the agent, recorded separately: **Grade** (hidden tests, in the no-network container) and
**Wait** (provider errors and retries, timeouts, container start).

The rules live in data, `specs/benchmarks/ab/vsm.yaml` (ordered regexes per tool and target), so
they can be tuned and unit-tested against saved transcripts, never hard-coded.

### What the probe on 4 saved pi runs showed (2026-11-03)

- Tool execution is only **1–3%** of lead time. About 97% is the model generating. A VSM that times
  tools shows nothing; time must be credited per *turn*, as above.
- pi stamps an assistant message when it *starts*. A turn lasts until the next message's timestamp.
- The thinking that leads to an action is credited to that action. For example, ab-11 bigpowers'
  `git checkout -b` turn took 84 s because the model planned the fix in it. Where the provider
  reports reasoning tokens separately, record them per stage so this stays visible.

| Run (ab-11, k=1) | Lead | Build | Test | Plan | Design | Deploy | Maintain |
|---|---|---|---|---|---|---|---|
| vanilla | 117 s | **55%** | 27% | 1% | 16% | – | – |
| bigpowers | 228 s | **3%** | 27% | 16% | 16% | 37% | 2% |

Same outcome (both passed, score 1.0). bigpowers doubled the lead time, and its build share fell
from 55% to 3%. One run proves nothing, but this is the signal to collect at scale.

## 2. Lean metrics per run

Added to each run record as a `vsm` block, so they flow into `ab-live.jsonl`, `ab_progress` and the
report.

### Flow

| Metric | Definition | Lean principle |
|---|---|---|
| `lead_time_s` | first to last agent message | Deliver fast |
| `time_to_first_build_s` | start to the first build edit | Deliver fast / delays |
| `value_add_s` | build + test turns whose edits survive in the final diff | Eliminate waste |
| `pce` | process cycle efficiency = `value_add_s / lead_time_s` | Eliminate waste |
| `stage_share` | time, tokens and cost per stage (the VSM bar) | Value stream mapping |
| `cost_per_pass` | arm cost ÷ passed runs (aggregate) | Optimize the whole |

### The seven wastes of software (Poppendieck), measured

| Waste | Metric | Source |
|---|---|---|
| Partially done work | failed hidden tests; untracked leftovers (e.g. `prop.tmp.mjs`) in the final tree | grade + `git status` at end |
| Extra features | `diff_ratio` = agent diff lines ÷ reference-solution diff lines; files touched that the solution does not touch | saved patch + `solution/` |
| Relearning | the same file read twice or more; the same command repeated | transcript |
| Handoffs | 0 for one agent today; counted later for multi-agent or multi-session tasks | transcript |
| Task switching | stage transitions per run (plan → build → plan → …) | VSM sequence |
| Delays | wait share (provider errors, retries, timeouts); model latency per turn | transcript + runner |
| Defects | `rework_loops` (red test runs after the first build edit); `rework_lines` (lines edited more than once); escaped defects (hidden tests failing) | transcript + patch |
| *(overprocessing)* | `process_share` = time and tokens on Plan + Maintain artifacts and skill reading | VSM |

Plus **first-time-through** (`ftt`): the first full test run after the last build edit passes, with
no later rework. This is "build integrity in" expressed as a number.

### The human-speed stages (the point of the diagram)

Build now costs seconds; people's requirements and review time are the constraint. A run that
produces more for a person to read moves cost to the slow part of the stream. Measure it:

- `review_load` = changed lines + files changed + words of generated docs/notes a reviewer would
  read.
- At equal pass rate, lower review load wins ("optimize the whole"). A bigpowers arm that writes a
  BUG note, a state file and docs must earn that load with fewer escaped defects.

## 3. Views

- **`ab_progress.py`:** one VSM bar per arm, like the diagram, plus PCE, FTT, review load and the
  top three wastes with deltas against vanilla. Shown live during sharded runs.

  ```text
  vanilla    [plan|design|====build====|==test==]          117 s  PCE 0.82  FTT 0.9
  bigpowers  [==plan==|design|b|==test==|===deploy===|m]   228 s  PCE 0.30  FTT 0.8
  ```

- **Report:** a `vsm` section per arm and task, a waste table, and stage-level deltas with
  bootstrap CIs.
- **Optional:** an HTML page per pinned report with the bars, for sharing.

## 4. Lean principles as benchmark decision rules

| Principle | Rule in the benchmark |
|---|---|
| Eliminate waste | A skill or arm whose pass/score delta CI includes 0 **and** that adds more than 20% lead time or cost is a cut candidate. The ablation already flags all five variants. |
| Amplify learning | Small experiments: one change per arm, streamed results, the evolution view. Every catalog change ships with an A/B run. |
| Decide as late as possible | Do not cut on one run. Cut when the CI excludes a benefit at an agreed k, or after two consistent runs on two models. Pinned baselines keep the option to revert. |
| Deliver fast | Track `lead_time_s` and `time_to_first_build_s`; a slower arm needs a quality gain to pay for it. |
| Empower the team | Fewer, stronger defaults (hooks, gates) instead of prose a model must obey; measure how often skills are actually read. |
| Build integrity in | `ftt`, rework loops, escaped defects, tamper rate. |
| Optimize the whole | `review_load` and `cost_per_pass`, not only agent pass rate. |
| Pull / WIP limits | Shard concurrency is a WIP limit: lower it when the `errors` column rises (provider rate limits). |
| Set-based concurrent engineering | Ablation arms run in parallel and are narrowed by evidence. |

## 5. Changes, in order

1. **Finish e58s07 (Docker sandbox).** The runner is mid-edit, and grading must run in the
   no-network container before more data is collected. Record container start and grade time as
   Grade/Wait.
2. **e58s08 — VSM classifier.** `specs/benchmarks/ab/vsm.yaml` rules plus `scripts/lib/ab_vsm.py`
   turning a pi transcript into stage time, tokens and cost and the stage sequence. Unit-tested on
   saved transcripts. The runner adds `vsm` to every record.
3. **e58s09 — Waste metrics.** Save each run's final patch next to its transcript. Compute
   `diff_ratio` against the reference solution, leftovers, relearning, task switching,
   rework, `ftt`, `pce` and `review_load`.
4. **e58s10 — Views.** VSM bars and waste table in `ab_progress.py` and the report; stage deltas
   with CIs.
5. **e58s11 — Waste gate.** The report flags arms and skills that meet the "eliminate waste" rule
   above, so cutting the catalog (e56) is driven by data.
6. **Tasks.** Retire or harden saturated tasks (ab-13 is 10/10 on every arm). Add spec-heavy
   tasks (ab-09, ab-15, ab-16, and the anonymized payment-alias and statement-filter shapes) where
   Plan time *should* pay off. That is the fair test of whether planning is waste or value.
