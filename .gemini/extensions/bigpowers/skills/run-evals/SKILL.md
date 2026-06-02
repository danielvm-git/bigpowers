---
name: run-evals
description: "Eval-Driven Development — define capability and regression evals before building; code graders use verify commands, model graders use explicit rubrics; log pass@k. Use before develop-tdd on new features, or when measuring agent capability over runs.model: sonnet"
---


# Run Evals

> **HARD GATE** — Define evals before implementation. Code graders = runnable `verify:` commands; model graders = explicit rubric with pass/fail criteria.

## Process

1. Name the capability under test (one sentence).
2. Write `specs/EVALS-<feature>.md` with:
   - **Capability evals** (does it do the job?)
   - **Regression evals** (did we break anything?)
3. Assign grader type per eval: `code` (shell verify) or `model` (rubric).
4. Run evals; log results table with pass@k (e.g. 3/3 runs).
5. Block BUILD phase until capability evals pass at agreed k.

## Artefact

`specs/EVALS-<feature>.md` — see [REFERENCE.md](REFERENCE.md) for template.

## Verify

→ verify: `ls specs/EVALS-*.md 2>/dev/null | head -1 | grep -q EVALS && echo OK || echo MISSING`

---

# Run Evals — Reference

## EVALS template

```markdown
# EVALS: <feature>

## Capability
| ID | Eval | Grader | verify / rubric |
|----|------|--------|-----------------|
| C1 | ... | code | `verify: npm test -- <file>` |
| C2 | ... | model | Rubric: [ ] criterion A [ ] criterion B |

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
