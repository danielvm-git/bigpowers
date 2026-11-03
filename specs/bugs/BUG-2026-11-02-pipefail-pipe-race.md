---
bug_id: BUG-2026-11-02-pipefail-pipe-race
status: fixed
severity: medium
scope: scripts / gates
title: "Pipelines with an early-exit reader (grep -q, head) fail at random under set -o pipefail"
files_changed: "scripts/land-branch.sh, scripts/lib/parallel-review-worktrees.sh, scripts/check-spec-version-gap.sh, scripts/bp-churn-rank.sh, scripts/run-smoke.sh, scripts/validate-doctrine.sh, scripts/test-pipefail-pipe-race.sh (new), scripts/lib/golden-suite-gates.sh"
approach: "Do not let the reader close the pipe early: capture producer output first, test the captured string, or use a reader that reads to the end (awk NR<=n, sed -n '1,Np')"
risk_level: low
commit_message: "fix(scripts): remove pipefail SIGPIPE races from git and long-output pipelines"
---

# BUG-2026-11-02: SIGPIPE races under pipefail

## Problem

- **Actual:** under `set -o pipefail`, `producer | grep -q pattern` (also `| head`, `| grep -m`, `| awk '... exit'`) can return non-zero when the pattern is found. `grep -q` exits on the first match and closes the pipe. If the producer is still writing, it gets SIGPIPE (141) — or exit 120 for Python ("Exception ignored on flushing sys.stdout"). pipefail reports that as the pipeline status. Inside `if`, "found" reads as "not found"; as a plain statement under `set -e`, the script exits.
- **Expected:** the result depends only on the data.
- **Found in:** `scripts/lib/plan-consistency-check.sh` (flaky exit 120 while building the e58 A/B eval). Fixed in `4af8526f` on `danielvm-git/bigpowers-evaluation-roadmap-4d0758` — not in this change, to avoid a conflict with that branch.

## Root Cause Analysis

1. **Reproduce:** `set -o pipefail; seq 1 300000 | grep -q '^1$'; echo $?` → `141`, 20/20 runs (`scripts/test-pipefail-pipe-race.sh` (a)).
2. **Isolate:** the race needs the producer to write past the pipe buffer (16–64 KiB on macOS) after the reader exits. A producer whose whole output fits in one buffer (`echo "$short_var"`, `head -1 file`, a small fixture) finishes its write before the reader can close the pipe — no race.
3. **Audit:** `grep -rlE pipefail scripts hooks --include='*.sh'` (117 files) piped into `grep -nE '\| *(head|awk .*exit|grep -m|grep -q)'` gives 72 hits in 36 files. Each was classified by producer size.

## At-risk sites (fixed)

| Site | Producer | Failure mode | Fix |
|------|----------|--------------|-----|
| `scripts/land-branch.sh:90` | `git log main..branch --format=%B` | Co-authored-by footer missed → branch lands with attribution | Capture to `FEATURE_BODIES`, `grep -qiE <<<` |
| `scripts/land-branch.sh:197` | `git worktree list --porcelain` | Worktree not removed after land | Capture to `WORKTREES`, `grep -q <<<` |
| `scripts/lib/parallel-review-worktrees.sh:14` | `git worktree list` | Stale review worktree kept → `git worktree add` fails | Capture, `grep -q <<<` |
| `scripts/check-spec-version-gap.sh:84` | `git status --porcelain -- specs/` | Dirty specs read as clean → gap gate under-reports `ACTIVE_WORK` | `[[ -n "$(git status ...)" ]]` |
| `scripts/bp-churn-rank.sh:48` | `sort -rn` over every changed path | Script exits 141 after printing the list | `awk -v limit=N 'NR <= limit {printf ...}'` |
| `scripts/run-smoke.sh:49,168` | `echo "$body"` (HTTP response body) | Large page reads as "body does not match" | `grep -qiE ... <<<"$body"` |
| `scripts/validate-doctrine.sh:58,97,110` | `grep -r` over `docs/` or the whole repo | Under `set -e` the script exits in the diagnostic branch, skipping later checks | `sed -n '1,Np'` (reads to the end) |
| `scripts/lib/plan-consistency-check.sh:95` | Python `extract-story-verify.py` | Exit 120 | Fixed on another branch (`4af8526f`) |

## Safe sites (not changed)

Producer output is far below one pipe buffer, or the status is masked by `|| true` with the output still correct.

- **Short variable / single line:** `land-branch.sh:54`, `hooks/pre-tool-use.sh:55,102,112`, `hooks/pre/bash.sh:25`, `scripts/hooks/token-mgmt-pre-tool-use.sh:41,44`, `validate-skill-catalog.sh:44`, `validate-agentic-ste.sh:98,100`, `validate-skill-description.sh:37,40,48`, `wire-ci.sh:105,119,131`, `verify-install.sh:179`, `lib/land-branch-push.sh:13`, `lib/plan-consistency-check.sh:69`, `run-skill-verify.sh:59`.
- **Small file or bounded producer:** `bp-yaml-snapshot.sh:9`, `generate-adr-wiki.sh:34`, `golden-g13-script-orphans.sh:52`, `golden-g15-compliance-runner-selftest.sh:114`, `validate-contracts.sh:43,44`, `validate-skill-description.sh:20`, `verify-cwe-fixture-sync.sh:54,55`, `generate-skill-index.sh:109`, `test-install-hub.sh:59,81`, `lib/plan-consistency-check.sh:72`, `check-spec-version-gap.sh:158` (one line per epic), `verify-install.sh:46` (one contract result).
- **Masked by `|| true`, value still correct:** `bp-read-agents.sh:39`, `bp-opensrc-check.sh:54`, `golden-g04-selftest.sh:123,125`, `validate-skill-catalog.sh:71`.
- **Test scripts, captured output measured small** (validate-tombstones 99 B, test-adapters 3.4 KB, `sync-skills --distribute-only` 107 B, fixture runs): `test-adapter-render.sh:107`, `test-completeness-critic-scope.sh:*`, `test-golden-gate-runner.sh:*`, `test-install-distribute-only.sh:*`, `test-golden-g11-worktree-venv.sh:44`, `test-tombstone-mechanism.sh:*`, `run-story-verify.sh:150,153`.
- **Not a command:** `run-skill-verify.sh:125,126` are fixture strings of fail-open verify directives.

## Regression guard

`scripts/test-pipefail-pipe-race.sh` (golden gate `pipefail-pipe-race`):

- (a) the racy shape fails on this host (anti-vacuity);
- (b) each fix shape passes 20/20 with a 2 MB producer;
- (c) static: no pipefail script pipes `git ...` into `grep -q`/`-m` or `head`. Restoring the old `land-branch.sh` makes (c) fail on lines 90 and 197.

## Verify

```bash
bash scripts/test-pipefail-pipe-race.sh
bash scripts/validate-doctrine.sh && bash scripts/bp-churn-rank.sh --limit 3
```
