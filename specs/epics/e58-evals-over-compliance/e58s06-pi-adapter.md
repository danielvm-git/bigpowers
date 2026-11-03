# e58s06: pi adapter (default), OpenCode Go deepseek-v4.1-flash

<!-- story: e58s06 -->

```
STORY KEY: e58s06
TITLE:     Run the A/B eval through pi by default, isolated from the user's pi setup
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      S (2)
```

Source: the maintainer runs agents through pi (`@earendil-works/pi-coding-agent` 1.5.0) with the
OpenCode Go provider. The user's pi settings load bigpowers as a package, so pi must be isolated
or the vanilla arm is not vanilla.

## Requirements

### ADDED

- A `pi` adapter in `config.yaml`: `pi -p --mode json --approve --no-session --no-mcp --offline
  --model "$AB_MODEL"`, default model `opencode-go/deepseek-v4.1-flash`.
- Isolation: `HOME` and `PI_CODING_AGENT_DIR` point inside the per-run `$AB_HOME`, which holds only
  a copy of the user's pi `auth.json` (removed with `$AB_HOME`). User settings, packages (incl. a
  global bigpowers), user skills, `~/.agents` and `~/.claude` never load. `--approve` lets the
  project's `.agents/skills` load in the bigpowers arms.
- Parser `pi-json`: sums assistant `message_end` usage — `cost_usd` (Σ `usage.cost.total`),
  `input_tokens` (Σ input + cacheRead + cacheWrite), `output_tokens` (Σ output), `turns` (assistant
  messages); `agent_reported_error` when an assistant message stops with `error` or `aborted`, or
  `agent_settled.aborted` is true.
- `config.yaml` MAY set `default_adapter`; `--adapter` falls back to it, then to `claude`.
  This config sets `default_adapter: pi`.

## Acceptance criteria

```gherkin
Scenario: pi JSON metrics are summed
  Given two assistant message_end events with usage
  Then cost, tokens and turns are the sums and there is no error

Scenario: A pi provider error is an agent error
  Given an assistant message with stopReason "error"
  Then agent_reported_error is true

Scenario: The config's default adapter is used
  Given default_adapter in config and no --adapter
  Then the run uses that adapter
```

## Acceptance

```bash
python3 tests/test_ab_pi.py && bash scripts/run-ab-eval.sh --dry-run --k 1 --tasks ab-01 && echo OK
```
