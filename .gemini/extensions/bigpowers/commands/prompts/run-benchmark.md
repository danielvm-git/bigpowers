
# Run Benchmark

> **HARD GATE** — Do NOT use benchmark scores to declare a skill "good" or "bad" in isolation. Benchmarks measure relative quality vs. a baseline — they catch regressions, they do not certify correctness.

Reads benchmark definitions from `specs/benchmarks/`, executes each scenario's grader, and writes a structured `pass@k` report that `evolve-skill` consumes.

## Usage

```bash
# Benchmark a single skill
run-benchmark <skill-name>

# Benchmark all skills with definitions
run-benchmark --all

# Pin current results as baseline
run-benchmark <skill-name> --baseline
```

## Process

1. **Locate definition** — Read `specs/benchmarks/<skill>.yaml`. If absent, report: `"No benchmark definition found for <skill>. Create specs/benchmarks/<skill>.yaml first."` and stop.

2. **Run each scenario** — For each scenario in `scenarios[]`:
   - **Code grader:** Run `grader.command` in repo root via `bash -c`. Exit 0 → PASS. Non-zero → FAIL. Timeout: 15 seconds.
   - **Rubric grader:** Present each criterion to the agent as a yes/no question about the scenario output. ≥ 80% yes → PASS, else FAIL.

3. **Calculate pass@k** — `pass@k = sum(weight of PASS scenarios) / sum(all weights)`. Round to 2 decimal places.

4. **Write report** to `specs/benchmarks/reports/BENCHMARK-<skill>-<YYYY-MM-DD>.yaml`:

```yaml
skill: survey-context
run_date: "2026-06-22"
pass_at_k: 0.83
total_scenarios: 3
passed: 2
failed: 1
scenarios:
  - id: s01
    name: "detects active epic from state.yaml"
    result: PASS
    weight: 1.0
  - id: s02
    name: "reads release-plan.yaml and reports next epic"
    result: PASS
    weight: 1.0
  - id: s03
    name: "handles missing state.yaml gracefully"
    result: FAIL
    weight: 0.5
    failure_note: "crashed instead of suggesting state.yaml creation"
```

5. **Baseline mode** (`--baseline`) — Copy the report to `specs/benchmarks/reports/BASELINE-<skill>.yaml`. This is the reference point for regression checks in `evolve-skill`.

6. **Compare to baseline** — If a `BASELINE-<skill>.yaml` exists, compare `pass_at_k`. Report:
   - `IMPROVED: 0.67 → 0.83`
   - `REGRESSION: 0.83 → 0.67 — do NOT ship this change`
   - `STABLE: 0.83 = 0.83`

## Verify

→ verify: `test -f run-benchmark/SKILL.md && grep -q 'pass_at_k\|pass.at.k' run-benchmark/SKILL.md && echo OK || echo FAIL`
