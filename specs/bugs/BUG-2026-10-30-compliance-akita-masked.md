---
bug_id: BUG-2026-10-30-compliance-akita-masked
status: fixed
severity: medium
scope: ci / compliance
title: "akita.feature at PASS 17 / FAIL 2 on main — duplicate function names and two files over 300 lines, masked by the 94% global gate"
files_changed: "scripts/lib/test-assertions.sh, scripts/validate-docs-base-path.sh, scripts/validate-mcp-package.sh, scripts/validate-omp-extension.sh, scripts/test-project-runtime.sh, scripts/test-golden-gate-runner.sh, scripts/run-story-verify.sh, scripts/lib/story-verify-memo.sh (new), scripts/lib/srp-engine.py, scripts/lib/srp_engine_okf.py (new)"
approach: "Fix the code, not the checks: shared ta_* helpers replace copy-pasted pass/fail, rename name-only duplicates, extract cohesive helpers to get both files under 300 lines"
risk_level: low
commit_message: "fix(compliance): restore akita.feature to 0 FAIL — dedupe helpers, split oversized files"
---

# BUG-2026-10-30: akita.feature regressed to 2 FAIL, hidden by the global gate

## Problem

- **Actual:** `bash scripts/audit-compliance.sh specs/verifications/features/akita.feature` on main (2.88.16, `b814ed1a`) reports `PASS: 17, FAIL: 2` and `SCORE: 89%`. The full run (`npm run compliance`) reports `PASS 96 / FAIL 2 / 97%` and exits 0.
- **Expected:** every akita step passes (it was 0 FAIL after `e95c86ae`, BUG-2026-07-07-compliance-duplicate-symbols).
- **First triage was wrong:** the report from Preflight named the two "error messages" steps (BUG-2026-07-07-compliance-error-messages). Both pass when run alone and in the audit. The two red steps are:
  1. `then-public-symbols-should-be-unique-enough-to-be-searched-with-grep-5-results.sh` — duplicate bash function names `fail`, `pass`, `run_fixture`, `run_verify_cmd`.
  2. `and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh` — `scripts/lib/srp-engine.py` (333 lines) and `scripts/run-story-verify.sh` (314 lines).

## Root Cause Analysis

1. **Reproduce:** run each step script from the repo root — both exit 1 with the lists above.
2. **Isolate (which commits):**
   - `274894fe` (#118), `4a94f720`, `1194dc15` (#123/#125) — `validate-omp-extension.sh`, `validate-docs-base-path.sh`, `validate-mcp-package.sh` and `test-project-runtime.sh` each define their own `pass()`/`fail()` instead of `lib/test-assertions.sh`.
   - `1b564639` (#155) — `srp-engine.py` grows 290 → 333 lines.
   - `2db0bb98` (#161) — `run-story-verify.sh` grows 208 → 314 lines (memoized execution) and adds `run_verify_cmd` (same name as `run-skill-verify.sh`'s, different job); `test-golden-gate-runner.sh` adds `pass`/`fail`/`run_fixture`.
3. **Why nobody saw it:** the compliance gate is a global score against the 94% doctrine threshold (`docs/PRINCIPLES.md` §6, README, constitution B6). Two FAILs out of 98 is 97%, so `GATE: PASS` and exit 0. The per-file summary is the only signal, and it scrolls by. Each PR above stayed green.
4. **Script vs check:** both checks are correct — the defects are real (copy-pasted helper implementations; files past the cap). Fixed in the code, no check loosened.

## Fix

- `lib/test-assertions.sh` gains `ta_err`/`ta_ok` (validator style: `FAIL:`/`ok  :` with an `ERRORS` counter); the three `validate-*.sh` gates use them. `test-project-runtime.sh` and `test-golden-gate-runner.sh` use `ta_pass`/`ta_fail`.
- `test-golden-gate-runner.sh`: `run_fixture` → `ggr_run_fixture`.
- `run-story-verify.sh`: memoization helpers move to `lib/story-verify-memo.sh`; `run_verify_cmd` → `run_memoized_chain`. 314 → 267 lines.
- `srp-engine.py`: `render_okf_concept` moves to `lib/srp_engine_okf.py` (sibling of `srp_engine_links.py`). 333 → 274 lines.

## Exit code (not changed)

The gate exits 0 with failing steps by design: the threshold is project doctrine, with `pass-warn` below 97%. Making any unwaived FAIL block is a doctrine change, so it is left for a decision, not done here. Note that this run was at 97% — the warn band would not have fired either.

## Verify

```bash
bash scripts/audit-compliance.sh specs/verifications/features/akita.feature | grep 'File Summary'   # PASS: 19, FAIL: 0
bash scripts/test-golden-gate-runner.sh && bash scripts/test-project-runtime.sh
bash scripts/run-story-verify.sh --self-test && bash scripts/sync-skills.sh
```
