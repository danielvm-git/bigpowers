# e58s10: value stream and waste views in progress and reports

<!-- story: e58s10 -->

```
STORY KEY: e58s10
TITLE:     Show each arm's value stream map and waste table, with deltas against vanilla
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-03
MATURITY:  4
SIZE:      S (2)
```

Source: `specs/benchmarks/LEAN-VSM_LATEST.md` step 4. e58s08/e58s09 put `vsm` and `waste` on every
run record; nothing aggregates or shows them yet. e58s09 also showed PCE counts all test time as
value, so heavy re-testing looks efficient.

## Requirements

### ADDED

- `scripts/lib/ab_lean.py`:
  - `lean_summary(records, arms)`: per arm, over the runs that have them, the mean lead time, time
    to first build, stage switches, seconds and share per stage, mean waste metrics, first-time-
    through rate, leftover rate and `cost_per_pass` (arm cost ÷ passed runs). `None` when no run
    has a `vsm` or `waste` block.
  - Deltas against vanilla, each with a seeded bootstrap 95% CI, for: lead time, time to first build,
    switches, build share, test share, test runs, redundant test runs, rework loops, re-edits,
    review load, diff ratio, first-time-through and PCE.
  - `lean_lines(summary)`: a VSM bar per arm whose length is the mean lead time and whose segments
    are the stages (P D B T R M), then a waste table with the deltas.
- The report gets `lean`, and `print_summary` and `ab_progress.py` print `lean_lines`.
- `ab_waste.py` adds `redundant_test_runs`: passing test runs with no file edited since the
  previous passing run (overprocessing). PCE is unchanged; the views show both.

## Acceptance criteria

```gherkin
Scenario: Per-arm lean summary and deltas
  Given vanilla and bigpowers runs with vsm and waste blocks
  Then each arm has stage shares, waste means, ftt rate and cost per pass,
       and bigpowers has deltas with 95% CIs

Scenario: Old records without lean blocks
  Given runs with no vsm or waste
  Then the lean summary is None and the views print nothing extra

Scenario: VSM bars scale with lead time
  Given bigpowers with twice vanilla's lead time
  Then its bar is about twice as long and shows its stages

Scenario: A repeated green test run is redundant
  Given a passing test run, no edit, and another passing test run
  Then redundant_test_runs is 1
```

## Acceptance

```bash
python3 tests/test_ab_lean.py && echo OK
```
