---
bug_id: BUG-2026-11-03-story-verify-e58-eval-flake
status: open
severity: high
scope: ci / story-verify
title: "story-verify goes red on main for e58s01/e58s02/e58s03 on an intermittent failure inside test_ab_eval.py that does not reproduce locally"
files_changed: "scripts/run-story-verify.sh"
approach: "Gate now prints a 'detail:' line naming the failing test so the next occurrence is diagnosable; root cause unknown after ~280 reproduction attempts, so it is logged rather than papered over"
risk_level: low
commit_message: "fix(scripts): name the failing test when story verify goes red"
---

# BUG-2026-11-03: intermittent story-verify red on the e58 eval suite

## Problem

- **Actual:** pushing `9377f164` (squash of PR #187) to `main` turned the `story-verify` gate red.
  Three stories failed, all running the same command `python3 tests/test_ab_eval.py`:
  ```
  FAIL: e58s01 — python3 tests/test_ab_eval.py && bash scripts/run-ab-eval.sh --dry-run
  FAIL: e58s02 (shared result) — ... --dry-run --adapter opencode
  FAIL: e58s03 — python3 tests/test_ab_score.py && python3 tests/test_ab_eval.py
        output: Ran 29 tests in 3.213s  FAILED (failures=1)
  Results: 47 PASS, 3 FAIL, 162 SKIP
  ```
  Run: https://github.com/danielvm-git/bigpowers/actions/runs/41625241562
- **Expected:** the same tree, same workflow, same command gives the same verdict.
- **Contradiction:** the identical tree passed minutes earlier. PR #187's `story-verify`
  (run 41624820254, commit `1325d77b`) reported `50 PASS, 0 FAIL, 162 SKIP` with `PASS: e58s01`,
  `PASS: e58s02`, `PASS: e58s03`. PR #188 (run 41627078945) passed the same three again.
  Only the push-to-main run failed.

## Root Cause Analysis

1. **Reproduce — not achieved.** The failing test is not named anywhere in the log: the gate printed
   only `output: <last 3 lines>`, which for unittest is the `FAILED (failures=1)` footer.
2. **Isolate — attempted, negative.** All of the following were clean:
   - `ubuntu:22.04` + python 3.10 + node 22 (the CI stack), 15 sequential runs of the full file: 15 × OK.
   - The same image pinned to `--cpus=2`, 4 parallel suites × 6 runs (24 runs): 0 failures.
   - Every shipped A/B task graded 12 times in both modes (9 tasks × 2 × 12 = 240 runs): no
     unexpected result — fixtures fail and solutions pass 240/240, so `TestStarterTasks` is not
     the flaky class.
   - `python3 tests/test_ab_eval.py </dev/null` and with `CI=true GITHUB_ACTIONS=true TZ=UTC`:
     both OK (the gate closes stdin for every verify command).
3. **Remaining suspects.** The three verify commands agree only on `python3 tests/test_ab_eval.py`,
   whose non-`TestStarterTasks` classes spawn in-process runs (`ab.main`), temp `$AB_HOME` dirs and
   subprocess adapters. One assertion in that group is environment-sensitive on the runner in a way
   280 local runs did not reproduce.

## Why it is logged, not fixed

`fix-or-log` step 3: reproduction is blocked after a good-faith attempt, so the fix would be a guess.
A speculative patch to `tests/test_ab_eval.py` would hide the failure instead of removing it.

## Instrument (shipped here)

`scripts/run-story-verify.sh` now prints, on failure:
```
      output: <last 3 lines>
      detail: FAIL: test_x (__main__.Class) Traceback (most recent call last): AssertionError: ...
```
Same command, same exit code, same verdict — only the diagnostic is new. The next occurrence names
the test, which converts this bug from "unknown flake" into a one-line fix.

## Follow-up

- On the next red: read `detail:` in the log, then reproduce that single test under contention.
- If it recurs before then, add the resolved test name here and move `status: open` → `fixed` with
  the fixing commit.
