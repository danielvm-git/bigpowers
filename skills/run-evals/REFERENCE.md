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
