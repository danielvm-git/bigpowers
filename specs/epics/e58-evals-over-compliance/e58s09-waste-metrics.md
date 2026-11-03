# e58s09: lean waste metrics per run

<!-- story: e58s09 -->

```
STORY KEY: e58s09
TITLE:     Measure the seven wastes, first-time-through, PCE and review load for every A/B run
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-03
MATURITY:  4
SIZE:      S (2)
```

Source: `specs/benchmarks/LEAN-VSM_LATEST.md` step 3. e58s08 shows *where* time goes per stage;
this story measures *what kind of waste* it is, from the transcript and the run's final patch.

## Requirements

### ADDED

- The runner saves each run's final patch (agent changes only, before hidden tests are copied) as
  `<out>/traces/<task>-<arm>-<run>.patch.gz` and adds a `waste` block to every run record.
- Patch metrics (any adapter). Files are classed with the e58s08 rules as an edit of that path:
  - `product_lines`, `test_lines`, `doc_lines`, `plan_lines`: changed lines per class.
  - `solution_lines`: changed lines of the task's reference solution (fixture → solution), or `null`.
  - `diff_ratio` = `product_lines / solution_lines` (extra features), or `null`.
  - `extra_files`: product files changed that the reference solution does not change.
  - `leftovers`: added files matching the `leftovers` regex in `vsm.yaml` (partially done work).
  - `review_load` = all changed lines + files changed + words added to Markdown files.
- Transcript metrics (pi transcripts; `null` otherwise):
  - `rereads`: extra reads of a file already read (relearning).
  - `repeated_commands`: identical non-test shell commands run again (relearning).
  - `test_runs`, and `rework_loops`: failing test runs after the first build edit (defects). A run
    fails when its result has a non-zero `exit_code` or a `fail N` / `not ok` summary.
  - `reedits`: edits of a file already edited (rework).
  - `ftt` (first-time-through): at least one test run after the first build edit and none failed.
  - `pce` = (build + test stage time) / lead time, from the VSM.

## Acceptance criteria

```gherkin
Scenario: Relearning and rework are counted from the transcript
  Given a file read twice, `ls` run twice, a build edit, a failing `npm test`, a second edit of
        the same file and a passing `npm test`
  Then rereads 1, repeated_commands 1, test_runs 2, rework_loops 1, reedits 1, ftt false

Scenario: A clean run is first-time-through
  Given a build edit followed by one passing test run
  Then rework_loops 0 and ftt true

Scenario: Patch metrics compare the run with the reference solution
  Given a reference solution that changes answer.txt
  And an agent that changes answer.txt, adds extra.js, notes.md and debug.tmp.js
  Then extra_files has extra.js, leftovers has debug.tmp.js, doc words are counted,
       diff_ratio is set and the patch is saved

Scenario: Non-pi adapters get patch metrics only
  Given parser none
  Then the transcript metrics are null and the patch metrics are present
```

## Acceptance

```bash
python3 tests/test_ab_waste.py && echo OK
```
