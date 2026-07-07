---
name: run-evals
description: "Eval-Driven Development — define capability and regression evals before building; code graders use verify commands, model graders use explicit rubrics; log pass@k. Use before develop-tdd on new features, or when measuring agent capability over runs."
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

→ verify: `find specs/verifications -name "*-eval-report.md" | wc -l | awk '{if($1>0) print "OK: "$1" eval reports"; else print "MISSING"}'`

---

# Run Evals — Reference

## Strictness tiers (e45s37)

Add a `tier:` column to each eval row:

| Tier | Gate behaviour |
|------|----------------|
| `EXPERIMENTAL` | Log only — does not block |
| `USUALLY_PASSES` | Warn on failure; blocks only when paired with failing `ALWAYS_PASSES` |
| `ALWAYS_PASSES` | Hard block on any failure |

## EVALS template

```markdown
# EVALS: <feature>

## Capability
| ID | Eval | Grader | Tier | verify / rubric |
|----|------|--------|------|-----------------|
| C1 | ... | code | ALWAYS_PASSES | `verify: npm test -- <file>` |
| C2 | ... | model | USUALLY_PASSES | Rubric: [ ] criterion A [ ] criterion B |

## Regression
| ID | Eval | Grader | verify / rubric |
|----|------|--------|-----------------|
| R1 | Full suite passes | code | `verify: npm test` |

## Results
| Run | C1 | C2 | R1 | pass@k |
|-----|----|----|-----|--------|
| 1 | PASS | PASS | PASS | 3/3 |
```

## pass@k

Run capability evals k times (default k=3). Ship when all k pass or document known flake in `specs/state.yaml` `handoff.open_decisions`.
