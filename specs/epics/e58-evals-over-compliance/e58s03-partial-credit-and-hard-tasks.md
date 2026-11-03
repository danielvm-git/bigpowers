# e58s03: partial-credit scoring + two hard tasks (ab-11, ab-13)

<!-- story: e58s03 -->

```
STORY KEY: e58s03
TITLE:     Score runs by share of hidden tests passed, and add two tasks the arms can differ on
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      M (3)
```

Source: the k=10 run on `opencode-go/deepseek-v4.1-flash` put six of eight tasks at 10/10 on both
arms (delta +0.01, CI [-0.05, +0.06]). The suite is at its ceiling and grading is binary.
`specs/benchmarks/HARDER-TASKS_LATEST.md` lists the candidates; this story builds the runner change
and the two tasks expected to separate the arms most.

## Requirements

### ADDED

- `task.yaml` MAY declare `score: <command>`. After grading, the runner runs it in the workdir and
  reads the `node --test` summary lines (`# pass N`, `# fail M`; summed when there are several).
  The run record gets `score = pass / (pass + fail)`, rounded to 4 places, or `null` when the task
  has no `score` or the output has no summary.
- The `score` command MUST run hidden tests only, so tests an agent adds to visible files cannot
  raise it.
- The report MUST add `mean_score` per arm, `score` per task and arm, and, when both arms have
  scores, `delta.score` with a seeded bootstrap 95% CI. The console summary shows a score column.
- Task `ab-11-ledger-rounding` (bug, multi-file): a 6-file double-entry ledger with a user bug report
  ("monthly report off by a cent"). Root cause: `reports.js` rounds each line instead of the total.
  Rounding in `currency.js` is the tempting wrong fix and breaks hidden regression tests.
- Task `ab-13-orders-split` (refactor, structure): a ~500-line `src/orders.js` that parses, prices,
  taxes, discounts and formats. Split it into single-responsibility modules with the same public
  API and behaviour. Graded by an oracle comparison (original copy in `hidden/`) on generated
  orders, plus structure checks.

### MODIFIED: bootstrap_delta_ci input

**Before:** `bootstrap_delta_ci(treatment: list[bool], control: list[bool])`.
**After:** accepts any numeric values (bools or scores in [0, 1]); results for bools are unchanged.

## Acceptance criteria

```gherkin
Scenario: Score is the share of hidden tests passing
  Given a task whose score command prints "# pass 3" and "# fail 1"
  When the runner grades a run
  Then the run record has score 0.75

Scenario: Several summaries are summed
  Given score output with "# pass 2 / # fail 0" and "# pass 1 / # fail 1"
  Then score is 0.75

Scenario: No score command means no score
  Given a task without a score key
  Then score is null and the report has no score delta

Scenario: The report carries per-arm and delta scores
  Given runs with scores on both arms
  Then arms_summary has mean_score, per_task_score is filled, and delta.score has a ci95

Scenario: The new tasks are calibrated
  Given ab-11 and ab-13
  When graded on the fixture alone and with the reference solution
  Then the fixture fails, the solution passes, and the fixture score is below 1
```

## Out of scope

- The other six candidates in HARDER-TASKS_LATEST.md (later stories).
- Score commands for ab-01..ab-08 (they stay binary).
- A live run of the new tasks (a separate maintainer decision; costs quota).

## Acceptance

```bash
python3 tests/test_ab_score.py && python3 tests/test_ab_eval.py && echo OK
```
