---
name: run-benchmark
# story: e45s01
model: haiku
effort: standard
description: Run skill quality benchmarks from specs/benchmarks/ definitions — N-run with/without-skill delta grading, train/validation split, pass@k + benchmark.json reports. Use before and after evolve-skill to prove quality changes are improvements, not regressions.
# story: e23s02
---

# Run Benchmark

> **HARD GATE** — Do NOT use benchmark scores to declare a skill "good" or "bad" in isolation. Benchmarks measure relative quality vs. a baseline — they catch regressions, they do not certify correctness.

Reads benchmark definitions from `specs/benchmarks/`, executes each scenario's grader with and without the skill loaded, and writes a structured `pass@k` report with delta grading that `evolve-skill` consumes.

## With/Without-Skill Delta Grading

Every scenario runs N times (default 3) in two modes: **with** the skill loaded and **without** (bare agent with only CLAUDE.md). The delta `Δ = pass@k_with − pass@k_without` isolates the skill's causal contribution. A negative delta is a regression flag.

## Train/Validation Split

Benchmark definitions partition scenarios into two sets:

| Set | Tag | Purpose |
|-----|-----|---------|
| **Train** | `split: train` | Development scenarios — used while iterating. Hitting 100% on train is expected. |
| **Validation** | `split: validation` | Held-out scenarios — the real quality signal. Overfitting train while validation stagnates is a design smell. |

`pass@k` is reported separately for train and validation. Validation score is authoritative; train score is iteration guidance only.

## Usage

```bash
bash scripts/run-benchmark.sh <skill-name>           # benchmark single skill
bash scripts/run-benchmark.sh --all                  # benchmark all with definitions
bash scripts/run-benchmark.sh <skill-name> --baseline # pin results as baseline
```

## Process

1. **Locate definition** — Read `specs/benchmarks/<skill>.yaml`. If absent, stop with message.

2. **Partition scenarios** — Split by `split` field (`train` → iteration, `validation` → authoritative, default: `validation`).

3. **Run each scenario (N-run delta)** — For each scenario, run grader N times (default 3, configurable via `runs:`):
   - **Without skill:** Agent with only CLAUDE.md/CONVENTIONS.md
   - **With skill:** Agent with the skill under test active
   - Code grader: `bash -c <command>`, exit 0 → PASS. Timeout: 15s.
   - Rubric grader: yes/no per criterion, ≥ 80% yes → PASS.
   - Record: `{scenario_id: {with: [P/F,...], without: [P/F,...]}}`

4. **Calculate scores** — Per split (train, validation) and mode (with, without):
   - `pass@k = sum(weight × pass_rate) / sum(weights)` where `pass_rate = passes/runs`
   - `Δ = pass@k_with − pass@k_without` — causal contribution
   - Round to 2 decimal places

5. **Write benchmark.json** to `specs/benchmarks/reports/benchmark-<skill>.json`:
   ```json
   {"skill":"survey-context","run_date":"2026-06-22","runs_per_scenario":3,"train":{"with_skill":0.92,"without_skill":0.67,"delta":0.25,"scenarios":["s01","s02"]},"validation":{"with_skill":0.83,"without_skill":0.60,"delta":0.23,"scenarios":["s03","s04","s05"]}}
   ```

6. **Write YAML report** to `specs/benchmarks/reports/BENCHMARK-<skill>-<YYYY-MM-DD>.yaml`:
   ```yaml
   skill: survey-context
   run_date: "2026-06-22"
   runs_per_scenario: 3
   train:
     pass_at_k_with: 0.92
     pass_at_k_without: 0.67
     delta: 0.25
   validation:
     pass_at_k_with: 0.83
     pass_at_k_without: 0.60
     delta: 0.23
   scenarios:
     - id: s01
       split: train
       with_pass_rate: 1.0
       without_pass_rate: 0.67
       delta: 0.33
       weight: 1.0
   ```

7. **Baseline** (`--baseline`) — Copy to `BASELINE-<skill>.yaml` + `baseline-<skill>.json`.

8. **Compare to baseline** — `IMPROVED: Δ 0.17 → 0.25` / `REGRESSION: Δ 0.25 → 0.17 — do NOT ship` / `STABLE`.

9. **Delta threshold gate** — Validation Δ < 0.0 blocks release. Δ < 0.05 warns (marginal). Min meaningful threshold: 0.05.
