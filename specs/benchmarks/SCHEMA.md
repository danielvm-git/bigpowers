# Benchmark YAML Schema

Each file in `specs/benchmarks/` defines how to measure a skill's quality via
pass@k scoring. The `run-benchmark` skill reads these definitions.

## File naming

`specs/benchmarks/<skill-name>.yaml` — one file per skill under test.

## Full schema

```yaml
skill: <skill-name>          # must match the directory name in the repo
version: "1"                 # schema version; bump when format changes
scenarios:
  - id: s01                  # unique within this benchmark file
    name: "short description"
    prompt: |                # what you tell the agent / what state you set up
      "..."
    grader:
      type: code | rubric    # code: runs a bash command; rubric: LLM checklist
      # --- code grader ---
      command: "bash -c '...'"   # exit 0 = PASS, non-zero = FAIL
      # --- rubric grader ---
      criteria:              # list of yes/no questions asked of the output
        - "The output contains X"
        - "The skill does not produce Y"
    weight: 1.0              # contribution to pass@k (default 1.0)
```

## pass@k calculation

`pass@k = sum(weight of passing scenarios) / sum(all weights)`

A score of 1.0 = all scenarios pass. Regression = new score < baseline score.

## Grader types

| Type | When to use | How it works |
|------|-------------|--------------|
| `code` | Output is machine-verifiable (file exists, grep matches, exit code) | Runs `command` in repo root; PASS if exit 0 |
| `rubric` | Output is a text response that needs judgment | Agent answers each criterion yes/no; PASS if ≥ 80% yes |

## Reports

`run-benchmark` writes results to `specs/benchmarks/reports/BENCHMARK-<skill>-<YYYY-MM-DD>.yaml`.
Reports are gitignored (regenerated on demand) except when pinned as baselines.
