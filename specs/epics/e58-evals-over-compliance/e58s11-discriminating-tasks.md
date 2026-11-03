# e58s11: three tasks with changing, spread and implied requirements

<!-- story: e58s11 -->

```
STORY KEY: e58s11
TITLE:     Add A/B tasks where requirements change, are spread across documents, or are only implied
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-03
MATURITY:  4
SIZE:      M (3)
```

Source: `specs/benchmarks/TASK-REVIEW_LATEST.md`. Vanilla passes 0 of 14 tasks in the 20–80% band
on deepseek-v4.1-flash, so no task can show a difference between arms. The new tasks follow the
review's rules: behavioural specs (no formulas or helper calls), one hidden test per stated or
implied requirement plus boundaries, protected visible tests, a reference solution and a `score`.

## Requirements

### ADDED

- `ab-12-todo-due-dates`: a todo CLI. The requirements are an issue thread of three comments. The
  second changes the first's date format and adds `--json`; the third requires v1 data files to
  keep working. The thread also implies that a task due today is not overdue, and that the old date
  format must now be rejected.
- `ab-15-config-precedence`: a config loader used by five modules. Precedence is `--set` > env >
  file (`--config` or `config.json`) > defaults, with type coercion and unknown-key errors. Two
  rules appear only in the doc's examples: an empty env value counts as unset, and
  `APP_DB__MAX_CONNECTIONS` maps to `db.maxConnections`.
- `ab-16-site-tags-rss`: a static site generator gains tag pages, a tag index and an RSS 2.0 feed.
  Existing pages must stay byte-identical. Tag slugs fold case and accents, the feed escapes XML,
  uses RFC-822 dates and holds the newest 20 posts, and drafts are excluded everywhere.
- Each task has `score` (hidden tests only), its fixture fails, and its solution scores 1.0.
- After building, calibrate: vanilla k=10 per task through `pi-docker`, and record the pass rate.

## Acceptance criteria

```gherkin
Scenario: Each new task is calibrated
  Given ab-12, ab-15 and ab-16
  When graded on the fixture alone and with the reference solution
  Then the fixture fails with a score below 1 and the solution passes with score 1.0

Scenario: Hidden tests run only the hidden suite
  Then each new task's score command names test-hidden and no visible test folder
```

## Acceptance

```bash
python3 tests/test_ab_score.py && python3 tests/test_ab_tasks.py && echo OK
```
