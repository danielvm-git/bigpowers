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
