---
story_id: e23s01
title: "Define specs/benchmarks/ schema and 3 seed benchmark definitions"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e23s01: benchmark schema + seed definitions

`evolve-skill` says to "consume bigpowers-benchmark report" but no benchmark
format or tool exists. This is a broken dependency that prevents the
self-evolution loop from running. Define the schema first; build the runner
in e23s02.

A benchmark definition specifies: the skill under test, a scenario prompt, the
expected output pattern, and a grader (code or rubric).

## Acceptance Criteria

- [ ] `specs/benchmarks/SCHEMA.md` documents the benchmark YAML format
- [ ] `specs/benchmarks/survey-context.yaml` is a seed benchmark definition
- [ ] `specs/benchmarks/develop-tdd.yaml` is a seed benchmark definition
- [ ] `specs/benchmarks/verify-work.yaml` is a seed benchmark definition
- [ ] Each benchmark has at least one `pass` scenario and one `fail` scenario

## Gherkin Scenarios

```gherkin
Given a benchmark file specs/benchmarks/survey-context.yaml
When run-benchmark reads it
Then it finds: skill, scenario_prompt, expected_pattern, grader fields
And can determine pass/fail from the grader

Given a "code" grader benchmark
When the scenario output contains the expected_pattern
Then the result is pass
And when not found, the result is fail
```

## Verification

```bash
test -f specs/benchmarks/SCHEMA.md && \
test -f specs/benchmarks/survey-context.yaml && \
test -f specs/benchmarks/develop-tdd.yaml && \
test -f specs/benchmarks/verify-work.yaml && \
echo "OK: schema + 3 seed benchmarks" || echo "FAIL"
```

## Benchmark YAML format (canonical)

```yaml
skill: survey-context
version: "1"
scenarios:
  - id: s01
    name: "detects active epic from state.yaml"
    prompt: "Run survey-context for the active epic."
    grader:
      type: code
      command: "grep -q 'active_epic_id' specs/state.yaml && echo PASS || echo FAIL"
    weight: 1.0
  - id: s02
    name: "reports missing state.yaml gracefully"
    prompt: "Run survey-context when specs/state.yaml is absent."
    grader:
      type: rubric
      criteria:
        - "Reports the missing file clearly"
        - "Suggests creating state.yaml"
        - "Does not crash or produce an error stack"
    weight: 0.5
```
