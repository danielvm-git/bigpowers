# story: e23s01
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

`run-benchmark.sh` runs no agent, so it cannot measure the without-skill arm. Since e58s01 it
reports that arm as `null` and prints `UNMEASURED` (it used to force it to 0, which made every
delta look positive). Real with/without numbers come from the A/B runner below.

## A/B outcome eval (e58s01)

`bash scripts/run-ab-eval.sh` runs the same tasks with and without bigpowers through a real
agent CLI and grades only the outcome. It is advisory: exit 0 after a run, 2 on config errors.

```bash
bash scripts/run-ab-eval.sh --dry-run                       # print the matrix, spend nothing
bash scripts/run-ab-eval.sh --tasks ab-01 --k 1             # one task, both arms, default adapter (pi)
bash scripts/run-ab-eval.sh --adapter opencode              # opencode CLI, default opencode-go/deepseek-v4-pro
bash scripts/run-ab-eval.sh --adapter claude --model <m>    # Claude Code
bash scripts/run-ab-eval.sh --adapter gemini --model <m>    # another harness
```

- **Config:** `specs/benchmarks/ab/config.yaml` — `arms` (setup commands) and `adapters`
  (command templates; the prompt is in `$AB_PROMPT`). The `claude` adapter runs with
  `--setting-sources project --strict-mcp-config`, so user-level skills (including a global
  bigpowers install), CLAUDE.md, hooks, plugins and MCP servers do not leak into either arm.
- **Tasks:** `specs/benchmarks/ab/tasks/<id>/` with `task.yaml` (`id`, `prompt`, `protected`,
  `grade`, `timeout_s`, optional `score`), `fixture/` (what the agent sees), `hidden/` (copied in only after the
  agent exits) and `solution/` (reference; the unit tests check fixture fails, solution passes).
  Prompts never name bigpowers.
- **Default adapter (e58s06):** `pi` (`default_adapter` in config), model
  `opencode-go/deepseek-v4.1-flash`, parser `pi-json` (sums assistant `message_end` usage; a
  `stopReason` of `error`/`aborted` or an aborted run marks an agent error). Isolation: `HOME` and
  `PI_CODING_AGENT_DIR` point inside `$AB_HOME`, which gets only a copy of the user's pi
  `auth.json`; user settings and packages (which may load bigpowers globally) never load.
  `--approve` lets the bigpowers arms' `.agents/skills` load.
- **Isolation:** each run gets a fresh empty `$AB_HOME`; the `opencode` adapter points `HOME` and
  `XDG_CONFIG_HOME` at it (global skills, AGENTS.md and plugins never load) and keeps
  `XDG_DATA_HOME` for credentials. Adapter stdin is always closed. An adapter may set
  `default_model`, used when `--model` is absent and recorded in the report.
- **Per run:** `pass`, `tampered` (an original line of a `protected` file was removed or changed,
  or the file was deleted), `protected_lines_added` (lines added to protected files, e.g. new
  tests from a TDD arm: counted, not flagged, since hidden tests decide `pass`), `diff_lines`, `duration_s`,
  `agent_error`, plus `cost_usd`, `input_tokens`, `output_tokens`, `turns` from the adapter's
  parser (`scripts/lib/ab_metrics.py`): `claude-json` (one result object) or `opencode-jsonl`
  (sums `step_finish` events; an `error` event marks an agent error).
- **Partial credit (e58s03):** a task's optional `score` command runs **hidden tests only**
  (`node --test --test-reporter=tap test-hidden/*.test.js`; piped output is not TAP without the
  flag). `score` = passed / (passed + failed + cancelled) over every `# pass` / `# fail` summary,
  or `null`. Tests an agent adds to visible files cannot raise it.
- **Suite:** `ab-01`–`ab-03` (written for e58s01) and `ab-04`–`ab-08`, ported from the legacy
  bigpowers-benchmark T01–T05 with neutral prompts, protected visible tests and hidden tests.
  Hard tasks with `score` (e58s03): `ab-11` (ledger rounding bug from a user report, two
  trap fixes; fixture 11/18) and `ab-13` (split a 240-line module, oracle on ~420 seeded orders
  plus structure checks; fixture 15/18). Candidates: `HARDER-TASKS_LATEST.md`.
- **Ablation arms (e58s04):** `ab-arm-bigpowers.sh` takes `AB_BP_SKILLS` (`all` | `none` | comma
  list) and `AB_BP_SEED` (seed path or `none`). Config arms: `bp-core` (seed + 6 named skills),
  `bp-seed` (seed only), `bp-skills` (all skills, no seed), `tdd-line` (3-line TDD rule, no skills).
- **Live progress (e58s05):** runs go round-robin (run 1 of every task and arm, then run 2, …).
  Each record is appended to `<out>/ab-live.jsonl` as it finishes, and each agent transcript is
  saved to `<out>/traces/<task>-<arm>-<run>.jsonl.gz`. Watch one or many shards with
  `python3 scripts/lib/ab_progress.py <out-dir>... [--watch 600]`: runs, pass, score, cost and
  errors per task and arm, deltas against vanilla with CIs, and their evolution by run index.
- **Reports:** `specs/benchmarks/reports/AB-<date>.yaml` (per-arm and per-task rates and
  `mean_score`, `per_task_score`, delta `bigpowers − vanilla` for pass rate and score, each with a
  seeded bootstrap 95% CI; `deltas_vs_vanilla` gives the same for every non-vanilla arm) and
  `ab-runs-<date>.jsonl` (raw runs).

## Reports

- **YAML:** `specs/benchmarks/reports/BENCHMARK-<skill>-<YYYY-MM-DD>.yaml`
- **JSON:** `specs/benchmarks/reports/benchmark-<skill>.json` — `with_skill` / `without_skill` mean columns + delta

Reports are gitignored except when pinned as baselines.
