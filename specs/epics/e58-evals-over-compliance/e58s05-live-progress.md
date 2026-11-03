# e58s05: live progress, interleaved runs and saved transcripts

<!-- story: e58s05 -->

```
STORY KEY: e58s05
TITLE:     Watch an A/B run evolve while it runs, and keep transcripts for process analysis
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      S (2)
```

Source: the maintainer wants the orchestrating agent to show how a long (k=100, sharded) run
evolves. Today the runner writes nothing until the end and runs every vanilla repetition before
any bigpowers one, so a mid-run look is impossible and would be one-sided.

## Requirements

### ADDED

- The runner MUST append each run record (with `bigpowers_sha` and `model`) to
  `<out>/ab-live.jsonl` as soon as the run finishes.
- The runner MUST save each run's adapter stdout, gzipped, to
  `<out>/traces/<task>-<arm>-<run>.jsonl.gz` (agent transcript for later process analysis).
- `scripts/lib/ab_progress.py <dir>...` MUST read every `ab-live.jsonl` under the given folders and
  print: runs per task and arm with pass rate, mean score and mean cost; the delta of each arm
  against vanilla with its CI; and the evolution of those deltas at run-index checkpoints.
  `--watch N` repeats every N seconds. Exit 2 when no live file is found.

### MODIFIED: run order

**Before:** task → arm → run index (all vanilla runs of a task before any bigpowers run).
**After:** run index → task → arm (round-robin), so any prefix of the run has every arm equally
and slow periods of the provider hit both arms alike. Results per run are unchanged.

## Acceptance criteria

```gherkin
Scenario: Records appear while the run is going
  Given a run with k=2 and two arms
  Then ab-live.jsonl has 4 lines, each with bigpowers_sha and model

Scenario: Runs are interleaved
  Then the record order is run 1 (vanilla, bigpowers), run 2 (vanilla, bigpowers)

Scenario: Transcripts are saved
  Then traces/ has one gzipped transcript per run holding the adapter stdout

Scenario: Progress reads several shards
  Given two shard folders with live files
  When ab_progress runs on both
  Then it prints every task and arm, the deltas, and an evolution section
```

## Acceptance

```bash
python3 tests/test_ab_progress.py && echo OK
```
