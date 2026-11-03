# e58s02: opencode adapter + the five legacy benchmark tasks

<!-- story: e58s02 -->

```
STORY KEY: e58s02
TITLE:     Run the A/B eval through opencode (Go subscription) on eight tasks
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      M (3)
```

Source: the maintainer runs agents through **opencode with an OpenCode Go subscription**. The
legacy `bigpowers-benchmark` repos hold five realistic tasks (T01–T05) whose prompts name skills,
whose tests are visible and editable, and whose scores reward process artifacts. This story ports
the tasks into the outcome-only A/B format and adds an opencode adapter.

## Requirements

### ADDED

- `specs/benchmarks/ab/config.yaml` MUST define an `opencode` adapter that runs
  `opencode run --format json` with model `opencode-go/deepseek-v4-pro` (was kimi-k2.7-code until the 2026-11-02 smoke runs) unless `--model` is given.
- The opencode adapter MUST isolate both arms from the maintainer's global setup: a fresh empty
  `HOME` per run (`$AB_HOME`), `XDG_CONFIG_HOME` inside it, `OPENCODE_DISABLE_CLAUDE_CODE=1`
  (so only `.agents/skills` and `AGENTS.md` load), while `XDG_DATA_HOME` keeps the real
  credentials.
- The runner MUST create `$AB_HOME` per run, export it to the adapter, and delete it afterwards.
- The runner MUST close the adapter's stdin (`opencode run` otherwise waits on it forever).
- An adapter MAY declare `default_model`; the runner exports it as `$AB_MODEL` when `--model` is
  absent, and the report records the model actually used.
- A parser `opencode-jsonl` MUST sum `step_finish` events: `cost_usd` (Σ `part.cost`),
  `input_tokens` (Σ input + cache.read + cache.write), `output_tokens` (Σ output + reasoning),
  `turns` (number of steps); any `error` event sets `agent_reported_error`.
- Five tasks `ab-04` … `ab-08` ported from T01–T05 with neutral prompts (no skill or bigpowers
  names), the original `test.js` as a protected visible test, extra hidden tests, and a reference
  solution:
  - `ab-04` rate limiter window bugs (T01)
  - `ab-05` `/users` pagination with `X-Total-Count` (T02)
  - `ab-06` stepdown refactor of `processData` (T03) — graded by hidden behaviour tests plus a
    structural check, because the visible test passes before any work
  - `ab-07` retry with exponential backoff from a vague feature request (T04)
  - `ab-08` per-key single-flight fix for the TTL cache race (T05)

### MODIFIED: parse_metrics location

**Before:** `parse_metrics` lived in `scripts/lib/ab-eval.py`.
**After:** parsers live in `scripts/lib/ab_metrics.py` (keeps the runner under the 300-line cap).

## Acceptance criteria

```gherkin
Scenario: opencode JSONL metrics are summed across steps
  Given two step_finish events with tokens and cost
  When the opencode-jsonl parser reads them
  Then cost, input tokens, output tokens and turns are the sums

Scenario: An opencode error event marks the run as an agent error
  Given an error event in the output
  When the parser reads it
  Then agent_reported_error is true

Scenario: Each run gets a fresh, empty HOME that is removed afterwards
  Given an adapter that records $AB_HOME and lists it
  When the runner runs it
  Then $AB_HOME was empty during the run and no longer exists after it

Scenario: Adapter stdin is closed
  Given an adapter that reads stdin before solving the task
  When the runner runs it
  Then the run finishes and passes

Scenario: Adapter default model is used and recorded
  Given an adapter with default_model and no --model flag
  When the runner runs it
  Then $AB_MODEL equals the default and the report records it

Scenario: Every ported task fails as given and passes with its solution
  Given tasks ab-04 to ab-08
  When graded on the fixture alone and with the reference solution
  Then the fixture fails and the solution passes
```

## Out of scope

- Connecting the OpenCode Go key (a maintainer step: `opencode auth login` → OpenCode Go).
- The live run and its report (needs the key, and a sandbox decision for `--auto` runs).
- Daytona sandboxing and `bigpowersRef` pinning (later stories).

## Acceptance

```bash
python3 tests/test_ab_eval.py && bash scripts/run-ab-eval.sh --dry-run --adapter opencode && echo OK
```
