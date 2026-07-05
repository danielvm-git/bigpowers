# Benchmark YAML Schema
# story: e48s01

Each file in `specs/benchmarks/` defines how to measure a skill's quality via
pass@k scoring with N-run delta grading. The `run-benchmark` skill reads these definitions.

## File naming

`specs/benchmarks/<skill-name>.yaml` — one file per skill under test.

## Full schema (v2)

```yaml
skill: <skill-name>
version: "2"                 # v2 adds split, runs, with/without delta
runs: 3                      # runs per scenario for statistical significance (default 3)
scenarios:
  - id: s01
    name: "short description"
    split: train | validation # train = iteration guidance; validation = authoritative
    prompt: |
      "..."
    grader:
      type: code | rubric
      command: "bash -c '...'"   # code grader: exit 0 = PASS
      criteria:                  # rubric grader: ≥ 80% yes = PASS
        - "The output contains X"
    weight: 1.0              # contribution to pass@k (default 1.0)
```

## pass@k calculation

`pass@k = sum(weight × pass_rate per scenario) / sum(all weights)` where `pass_rate = passes / runs`.

Calculated separately for train/validation splits and with/without-skill modes.
Delta `Δ = pass@k_with − pass@k_without` isolates the skill's contribution. Negative delta = regression.

## Reports

- **YAML:** `specs/benchmarks/reports/BENCHMARK-<skill>-<YYYY-MM-DD>.yaml`
- **JSON:** `specs/benchmarks/reports/benchmark-<skill>.json` — `with_skill` / `without_skill` mean columns + delta

Reports are gitignored except when pinned as baselines.
