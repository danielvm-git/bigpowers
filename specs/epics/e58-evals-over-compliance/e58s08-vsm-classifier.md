# e58s08: value stream map per run (stage classifier)

<!-- story: e58s08 -->

```
STORY KEY: e58s08
TITLE:     Map every A/B run onto Plan, Design, Build, Test, Deploy, Maintain
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-03
MATURITY:  4
SIZE:      S (2)
```

Source: `specs/benchmarks/LEAN-VSM_LATEST.md` step 2. Pass rate cannot say where bigpowers' extra
cost goes (+26% to +67% per run in the ablation). A probe on saved pi transcripts showed tools are
only 1–3% of lead time, so time must be credited per model turn, by the action the turn takes.

## Requirements

### ADDED

- `specs/benchmarks/ab/vsm.yaml` holds ordered rules (`stage`, `tools` regex, `target` regex;
  first match wins) and a `turn_priority` list for turns with several tool calls. Stages:
  `plan`, `design`, `build`, `test`, `deploy`, `maintain`, plus `wrap-up` for a turn with no tool.
- `scripts/lib/ab_vsm.py`:
  - `classify_call(tool, args, rules)` returns a stage. The target is `args.command`, else
    `args.path` / `file_path`.
  - `vsm_from(parser, stdout)` returns a `vsm` block for `pi-json` transcripts and `None` for any
    other parser or an unreadable stream:
    `lead_time_s`, `time_to_first_build_s`, `switches` (stage changes between turns),
    `sequence` (stage per turn) and `stages.<stage>` = `{s, cost_usd, output_tokens, turns}`.
  - A turn lasts from its assistant message's timestamp to the next message's timestamp (pi
    stamps a message when it starts).
  - CLI: `python3 scripts/lib/ab_vsm.py <trace.jsonl.gz>...` prints one VSM line per transcript,
    so existing saved runs can be mapped too.
- The runner adds `vsm` to every run record (so to `ab-live.jsonl` and the jsonl report).

## Acceptance criteria

```gherkin
Scenario: Tool calls are classified by the rules
  Given a read of ISSUE.md, an edit of src/a.js, an edit of test/a.test.js, `npm test`, `git commit`
  Then they are plan, build, test, test and deploy

Scenario: Turn time is credited to the stage of its action
  Given six assistant turns 0, 10, 25, 40, 50 and 55 s after the start
  Then plan 10 s, design 15 s, build 15 s, test 10 s, deploy 5 s, lead time 55 s,
       time to first build 25 s and 5 stage switches

Scenario: Unsupported parsers give no VSM
  Given parser none or a stream with no assistant messages
  Then vsm is null

Scenario: Run records carry the VSM
  Given an adapter that prints a pi JSON transcript
  Then the run record has vsm.stages.build
```

## Acceptance

```bash
python3 tests/test_ab_vsm.py && echo OK
```
