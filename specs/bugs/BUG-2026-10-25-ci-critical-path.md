---
bug_id: BUG-2026-10-25-ci-critical-path
status: fixed
severity: medium
scope: ci / golden suite
title: "CI critical path ~7.5 min — story-verify runs twice, repeated verify commands, quadratic G-13 scan"
ci_run: https://github.com/danielvm-git/bigpowers/actions/runs/40189090546
files_changed: "scripts/run-story-verify.sh, scripts/golden-g13-script-orphans.sh, scripts/lib/golden-suite-gates.sh, .github/workflows/golden-suite.yml, .github/workflows/publish.yml, .github/workflows/docs-site.yml, .github/workflows/sync-skills.yml, .github/workflows/publish-wiki.yml"
approach: "Remove duplicate work without dropping any check: memoize identical story verify commands, skip the in-suite story-verify gate only where its own CI job covers it, single-pass G-13 scan, print failing gate output; align timeouts and release/pages concurrency with the portfolio template"
risk_level: low
commit_message: "fix(ci): cut golden suite critical path by removing duplicate gate work"
---

# BUG-2026-10-25: CI critical path ~7.5 min

## Problem

- **Actual:** Golden Suite `verification-gates` takes 6–7.5 min ([run 40189090546](https://github.com/danielvm-git/bigpowers/actions/runs/40189090546)). Every other workflow finishes in under a minute.
- **Expected:** Same gates, same coverage, critical path ~2 min.
- **Reproduce:** `gh run view 40189090546 --json jobs` — per-gate timings in the `Run verification gates` step log.

**Security impact: NONE** — CI wiring and gate runners only.

## Root Cause Analysis

1. **Reproduce:** Per-gate timings from run 40189090546:

   | Gate | Time |
   |---|---|
   | `story-verify` | 220s |
   | `g13-script-orphans-selftest` | 58.6s |
   | `g13-script-orphans` | 56.3s |
   | `compliance` | 28.8s |
   | remaining 39 gates | ~70s |

2. **Isolate:**
   - `story-verify` runs inside `verification-gates` **and** as the separate `story-verify` job of the same workflow (~180s there).
   - Inside story-verify, 147 of 180s are repeated commands: 12 stories (e61s02 … e76s02) run the identical `bash scripts/test-install-hub.sh && bash scripts/verify-install.sh` (~11s each); ~10 more repeat `test-adapter-render.sh`.
   - G-13 `is_referenced` forks one `grep` per (script × reference file) pair — 98 scripts × every file under `specs/epics/**`, `docs/**`, … The self-test calls `find_orphans` on `scripts/` again, doubling the cost.
3. **Hypothesize:** Gates were added one at a time to close "gate exists but never runs" defects (#96, #106, #133, e95c86ae). Nothing ever removed overlap or measured run time.
4. **Verify:** Sum of the duplicate work (220s story-verify + ~140s repeated commands in the job + ~110s G-13 rescans) matches the observed critical path.

### Secondary findings (portfolio template `danielvm-git/.github`)

- `timeout-minutes`: golden jobs use 45/20/30; `sync-skills`, `skill-health`, `docs-site`, `publish-wiki` have none (6 h default). Standard: 10–15 for test jobs.
- `publish.yml` (release) and `docs-site.yml` (pages) use `cancel-in-progress: true`. Standard rule 4: release/deploy use `false` — a cancelled semantic-release can push a tag without the npm publish.
- Gate output goes to `/dev/null`, so a failing gate shows no reason in CI.

## Fix approach

Coverage must not drop (anti-vacuity). Every change removes repeated work only.

1. `run-story-verify.sh`: run each distinct verify command once per invocation; every story that declares it still gets its own PASS/FAIL line.
2. `golden-suite-gates.sh`: `GOLDEN_SKIP_GATES` (comma list) reports named gates as `SKIP` with a reason. `golden-suite.yml` sets `GOLDEN_SKIP_GATES=story-verify` because its `story-verify` job runs the same gate. Local Preflight is unchanged.
3. `golden-suite-gates.sh`: print the last 20 lines of a failing gate's output.
4. `golden-g13-script-orphans.sh`: build the referenced-name set in one `grep -ohF` pass; the self-test reuses the same function on fixtures only.
5. Workflows: 10–15 min timeouts; `cancel-in-progress: false` on release and pages.

## Verify

- `bash scripts/run-story-verify.sh --self-test` — includes a shared-command fixture that must execute once and report both stories.
- `bash scripts/test-golden-gate-runner.sh` — skip list reports SKIP with reason; failing gate prints its output.
- `bash scripts/golden-g13-script-orphans.sh --self-test && bash scripts/golden-g13-script-orphans.sh`
- `bash scripts/run-verification-gates.sh` — 0 new failures; record new timings below.

## Results

Local Preflight on `fix/ci-critical-path` rebased onto 2.88.12 (`5b0ebab3`): compliance exit 0 (96 PASS / 2 FAIL, same as main), golden 44/44 PASS, sync-skills exit 0, trace `--strict` exit 0.

| Measure | Before | After (local) |
|---|---|---|
| `run-story-verify.sh` | 2:39 | 0:52 — all 115 verdicts identical, 13 shared results |
| `golden-g13-script-orphans.sh` | 1:53 (hit macOS fork limit) | 3.3s |
| `golden-g13-script-orphans.sh --self-test` | ~1:53 | 3.4s |
| `run-story-verify.sh --self-test` | PASS | PASS on bash 5 and macOS `/bin/bash` 3.2 |
| `test-golden-gate-runner.sh` | — | PASS on bash 5 and 3.2 |

### CI measured — PR #161, [run 40192307998](https://github.com/danielvm-git/bigpowers/actions/runs/40192307998)

Baseline is the first green main run after #159 (7m 24s).

| Job / gate | main after #159 | PR #161 |
|---|---|---|
| **Golden Suite wall time** | **7m 24s** | **1m 25s** |
| `verification-gates` job | 7m 24s | 1m 22s |
| `story-verify` job | ~3m | 40s (13 shared results) |
| `skill-verify` job | ~17s | 15s |
| `story-verify` gate in verification-gates | 221.2s | SKIP — runs in the story-verify job of this workflow |
| `g13-script-orphans-selftest` | 57.7s | 0.89s |
| `g13-script-orphans` | 56.1s | 0.87s |
| slowest gate now | — | `compliance` 23.0s |

Verdict: 43/44 passed, 1 skipped (story-verify, with reason), PASS. The projection (~2 min) was conservative; the critical path is now `verification-gates` at 82s, ~5.2× faster.
