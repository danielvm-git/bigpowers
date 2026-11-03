# e58s01: Outcome A/B eval runner — vanilla agent vs bigpowers

<!-- story: e58s01 -->

```
STORY KEY: e58s01
TITLE:     Run the same tasks with and without bigpowers and grade only the outcome
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      L (5)
```

Source: [`specs/TRUE-NORTH_LATEST.md`](../../TRUE-NORTH_LATEST.md) §4 — "e58 first: build a with-vs-without runner and publish the first honest numbers."

## Requirements

### ADDED

- `scripts/run-ab-eval.sh` MUST run every selected task once per arm per run (`--k`, default 3) in a fresh temporary git workdir outside the repository, copied from the task's fixture.
- An **arm** is a named setup command from `specs/benchmarks/ab/config.yaml`. Arm `vanilla` adds nothing. Arm `bigpowers` provisions the workdir the way a bigpowers user has it (skills in `.claude/skills/` and `.agents/skills/`, `scripts/`, `specs/` folders, a `CLAUDE.md`/`AGENTS.md` seed).
- An **adapter** is a named command template from the same config (`claude`, `gemini`, `codex`), or a custom `--adapter-cmd`. The prompt reaches the adapter as `$AB_PROMPT`. The task prompt never names bigpowers.
- The `claude` adapter MUST load only project-level settings (`--setting-sources project --strict-mcp-config`) so the user's global skills (including a global bigpowers install), CLAUDE.md, hooks, plugins and MCP servers never leak into either arm. `AB_CLAUDE_CONFIG_DIR` optionally points it at a separate config directory.
- Grading MUST be outcome-only: after the agent exits, the runner copies the task's hidden tests (never visible to the agent) into the workdir and runs the task's `grade` command. Exit 0 = pass.
- The runner MUST record per run: `pass`, `tampered` (any `protected` file changed or deleted), `diff_lines` (added + deleted, excluding hidden tests), `duration_s`, and — when the adapter output parser supports it — `cost_usd`, `input_tokens`, `output_tokens`, `turns`, `agent_error`.
- The runner MUST write `specs/benchmarks/reports/AB-<YYYY-MM-DD>.yaml` with per-arm and per-task pass rate, tamper rate, mean cost/tokens/duration, and the pass-rate delta (`bigpowers − vanilla`) with a seeded bootstrap 95% confidence interval, plus the raw runs as `ab-runs-<YYYY-MM-DD>.jsonl`.
- `--dry-run` MUST print the run matrix and resolved commands and spend nothing.
- The runner is **advisory**: it exits 0 after a completed run regardless of the delta, and 2 on configuration errors. It does not touch the compliance gate (that is e58s03).
- Three starter tasks ship in `specs/benchmarks/ab/tasks/`: a small feature (`ab-01`), a bug fix (`ab-02`), and a red suite where deleting or weakening tests is the cheap way out (`ab-03`).

### MODIFIED: run-benchmark without-skill arm

**Before:** `scripts/lib/run-benchmark.py` replaced every code grader with `test -f /dev/null` for the without-skill arm. That command always fails, so `without_skill` was always 0 and every reported delta favored the skill by construction.
**After:** the without-skill arm is reported as `unmeasured` (pass rate `null`, delta `null`, summary line `UNMEASURED`) until a real agent run exists. Real with/without numbers come from `run-ab-eval.sh`.

## Sections

### 1. Business narrative [reviewed]
bigpowers says it delivers senior-grade quality, but it has never compared itself with a plain agent. The existing benchmark hard-codes the without-skill arm to fail, and the golden suite grades bigpowers-only artifacts (`tasks.yaml`, `next_skill`), so a plain agent cannot pass by design. This story builds the first fair comparison.

### 2. Value statement [reviewed]
As the solo maintainer, I want to run the same real tasks with and without bigpowers and see pass rate, test tampering and cost side by side, so that roadmap decisions (which skills to keep, e56) rest on measured outcomes, not self-compliance.

### 3. Actors and permissions [reviewed]
- Maintainer: runs the runner locally; pays the agent cost.
- Agent CLI (claude, gemini, codex): runs headless in a temp workdir with permission prompts bypassed.
- CI: runs only the unit tests with the `fake` adapter (no agent spend).

### 4. Trigger and preconditions [reviewed]
Manual `bash scripts/run-ab-eval.sh`. Requires Python 3 + PyYAML (`requirements.txt`), git, the task's toolchain (Node for the starter tasks), and, for a live run, an authenticated agent CLI. For `claude`, a working `claude -p` login (or `ANTHROPIC_API_KEY`).

### 5. Main flow and business logic [reviewed]
1. Load `config.yaml` and the selected task files; validate arms, adapter and fixtures.
2. For each task × arm × run: copy fixture to a temp dir; `git init` + commit; run the arm setup; commit; hash the `protected` files.
3. Run the adapter in the workdir with a timeout (`timeout_s`, default 900); capture stdout; parse metrics.
4. Copy hidden tests in; run `grade`; compute `tampered` and `diff_lines`.
5. Append the run record; delete the workdir unless `--keep`.
6. Aggregate per arm and per task; bootstrap the delta CI (1,000 resamples, seed 58); write the YAML + JSONL reports; print a summary table.

### 6. Alternative flows and exceptions [reviewed]
- Unknown arm, adapter or task → exit 2 with the valid names.
- Agent exits non-zero or times out → run recorded with `agent_error: true`; grading still runs (partial work can pass).
- Adapter output not parseable → cost/token fields `null`; run still graded.
- Only one arm selected → report has no delta (`null`).

### 7. Interface elements [reviewed]
CLI: `run-ab-eval.sh [--tasks ID,..] [--arms A,..] [--k N] [--adapter NAME | --adapter-cmd CMD] [--model M] [--out DIR] [--keep] [--dry-run]`.

### 8. Domain model [reviewed]
Task {id, fixture, prompt, protected[], hidden_dir, grade, timeout_s}; Arm {name, setup}; Adapter {name, command, env, parser}; Run {task, arm, run, pass, tampered, diff_lines, duration_s, cost_usd, input_tokens, output_tokens, turns, agent_error}.

### 9. Integrations and boundaries [reviewed]
Agent CLIs via shell command templates only. `claude -p --output-format json` returns `total_cost_usd`, `usage`, `num_turns`, `is_error` (code.claude.com/docs/en/headless). Skills load through the `user` and `project` setting sources, so `--setting-sources project` keeps only the workdir's (code.claude.com/docs/en/agent-sdk/skills).

### 10. Background processes [reviewed]
Not applicable — synchronous CLI run.

### 11. Notifications [reviewed]
Not applicable — summary printed to stdout.

### 12. Audit and logging [reviewed]
Every run is a JSONL line with the git SHA of bigpowers, adapter, model and timestamp.

### 13. Solution variabilities [reviewed]
Arms and adapters are data, not code: a new harness or a trimmed bigpowers arm (e56 experiments) is one config entry.

### 14. Quality attributes *NFR* [reviewed]
Deterministic aggregation (seeded bootstrap). Unit tests run in < 30 s with the fake adapter. Runner is stdlib + PyYAML only.

### 15. Security and compliance *NFR* [reviewed]
Agents run with permissions bypassed, so workdirs live under the system temp dir, never inside the repo, and hidden tests stay outside the workdir until grading. Config commands come from the repo only. Do not run untrusted task files.

### 16. UX and accessibility *NFR* [reviewed]
Not applicable — CLI only; output is plain text tables.

### 17. Acceptance criteria [reviewed]

```gherkin
Scenario: Fair A/B run with a fake adapter
  Given a fake adapter that solves the task only when .claude/skills exists
  When I run the runner on one task with arms vanilla,bigpowers and k=2
  Then bigpowers pass_rate is 1.0, vanilla pass_rate is 0.0 and the delta is 1.0

Scenario: Hidden tests are not visible to the agent
  Given a fake adapter that fails if any hidden test file is in the workdir
  When the runner runs
  Then the run passes

Scenario: Test tampering is detected
  Given a fake adapter that deletes a protected test file
  When the runner grades the run
  Then the run is recorded with tampered true

Scenario: Agent failure is recorded, not fatal
  Given a fake adapter that exits 1
  When the runner runs
  Then the run has agent_error true and the runner exits 0

Scenario: Claude JSON metrics are parsed
  Given adapter stdout containing a claude result JSON object
  When the runner parses it
  Then cost_usd, input_tokens, output_tokens and turns are filled

Scenario: Configuration errors stop the run
  Given an unknown arm name
  When I run the runner
  Then it exits 2 and lists valid arms

Scenario: Dry run spends nothing
  When I run the runner with --dry-run
  Then it prints the matrix and resolved commands and runs no adapter

Scenario: Without-skill arm is no longer faked
  Given a benchmark with a code grader
  When run-benchmark reports it
  Then without_skill is null and the summary says UNMEASURED
```

### 18. Out of scope [reviewed]
- Running the live eval and publishing numbers (needs the maintainer's go-ahead for agent spend; next step after this story).
- Growing the suite past 3 tasks (follow-up story, target ~15 incl. brownfield bugs).
- Calibration window (e58s02) and demoting the 94% gate (e58s03).
- Receipts page wiring.

### 19. Open questions [reviewed]
- Which model and k for the first published run? Default: the current Claude default model, k=3.
- Should the bigpowers arm seed name a starting skill? Kept minimal and configurable; record the choice with every report.

### 20. References [reviewed]
- `specs/TRUE-NORTH_LATEST.md`
- `specs/benchmarks/SCHEMA.md`, `scripts/lib/run-benchmark.py`
- SkillsBench (arXiv 2602.12670), Scaffold Effect (arXiv 2607.22585)

## Acceptance

```bash
python3 tests/test_ab_eval.py && bash scripts/run-ab-eval.sh --dry-run && echo OK
```
