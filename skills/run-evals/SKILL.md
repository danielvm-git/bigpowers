---
# story: e45s37
name: run-evals
description: Eval-Driven Development — define capability and regression evals before building; code graders use verify commands, model graders use explicit rubrics; log pass@k. Use before develop-tdd on new features, or when measuring agent capability over runs.
model: sonnet
effort: standard
---

# Run Evals

> **HARD GATE** — Define evals before implementation. Code graders = runnable `verify:` commands; model graders = explicit rubric with pass/fail criteria.

## Process

1. Name the capability under test (one sentence).
2. Write `specs/EVALS-<feature>.md` with:
   - **Capability evals** (does it do the job?)
   - **Regression evals** (did we break anything?)
3. Assign grader type per eval: `code` (shell verify) or `model` (rubric).
4. Assign **strictness tier** per eval (graduated promotion — e45s37):

   | Tier | Meaning | Promotion rule |
   |------|---------|------------------|
   | `EXPERIMENTAL` | New eval, may flake | Not gating |
   | `USUALLY_PASSES` | Stable in dev; ≥2/3 recent runs pass | Blocks BUILD only when combined with ALWAYS_PASSES suite |
   | `ALWAYS_PASSES` | Zero tolerance; required for release | Any single failure blocks BUILD and merge |

   Promote: `EXPERIMENTAL → USUALLY_PASSES` after 3 consecutive passes; `USUALLY_PASSES → ALWAYS_PASSES` after 5 consecutive passes with zero flakes documented in `specs/state.yaml`.

5. Run evals; log results table with pass@k (e.g. 3/3 runs) and tier per eval.
6. Block BUILD phase until all `ALWAYS_PASSES` evals pass at agreed k. `USUALLY_PASSES` failures warn; `EXPERIMENTAL` failures log only.

## Artefact

`specs/verifications/eNNsYY-eval-report.md` — see [REFERENCE.md](REFERENCE.md) for template. Eval reports are stored alongside verification evidence in `specs/verifications/`, keyed by story ID for traceability.

## Verify

→ verify: `test -d specs/benchmarks && test -f specs/benchmarks/SCHEMA.md`


<!-- story: e02s01 -->
