---
bug_id: BUG-2026-07-25-anti-vacuity-ci
status: open
severity: high
scope: ci
title: "Anti-vacuity golden suite (G-08/G-10) not wired into CI; Preflight ends on always-exit-0 step"
github_issue: 99
security_impact: NONE
risk_level: high
---

# BUG-2026-07-25: Anti-vacuity suite missing from CI

## Problem

**Actual:** `scripts/golden-g08-anti-vacuity.sh` and `scripts/golden-g10-trace-anti-vacuity.sh`
exist and pass locally via `bash scripts/run-verification-gates.sh`, but **zero**
`.github/workflows/*.yml` files invoke that runner. Preflight's documented chain ends
with `check-catalog-drift.sh`, which always exits 0.

**Expected:** Required CI on PRs touching `skills/` or `scripts/` runs the golden suite;
Preflight has no always-exit-0 trailing step; a scheduled job runs the suite fleet-wide.

**Reproduce:**

```bash
rg -n 'run-verification-gates|golden-g08|golden-g10' .github/workflows || echo NONE
# → NONE
rg -n 'advisory only|always exits 0' CLAUDE.md
# → Preflight row documents the escape hatch
```

**Security impact:** NONE — process/quality gate gap, not an exploit path.

Related: [#99](https://github.com/danielvm-git/bigpowers/issues/99). Same *class* as
[[BUG-2026-07-03-trace-engine-vacuous-gate]] and [[BUG-2026-07-04-tautological-verify]].

## Root Cause Analysis (diagnose-root)

### Phase 1 — Reproduce
Confirmed on `origin/main` (23e81729): `rg` over `.github/workflows` finds no
`run-verification-gates`, `golden-g08`, or `golden-g10`. Local
`bash scripts/run-verification-gates.sh` → 12/12 PASS (includes g08 + g10).

### Phase 2 — Isolate
- Golden scripts + runner are healthy (local Preflight gates green).
- `sync-skills.yml` paths/jobs cover artifact sync + trace + OKF — not the golden suite.
- `publish.yml` runs compliance + advisory `skill-health` (`run-skill-verify.sh` with
  `continue-on-error: true`) — not G-08/G-10.
- No workflow uses `schedule:` for golden/anti-vacuity (other crons exist for locks,
  references, agentics).
- `scripts/check-catalog-drift.sh` header + final `exit 0` make it a Confirm gate;
  CLAUDE.md Preflight chains it last with `&&`.

### Phase 3 — Hypothesize
Wave that built G-08/G-10 wired them into the local runner only; CI ownership stayed
on sync/publish. e54s02 made catalog-drift advisory and left it as Preflight's closer,
creating a documented fail-open tail.

### Phase 4 — Verify
Hypothesis confirmed: defect is **missing wiring**, not broken gates. Fix is add
required CI + schedule for `run-verification-gates.sh`, and remove the always-0 step
from the Preflight `&&` chain (keep script as manual Confirm).

## Fix Approach

1. Add `.github/workflows/golden-suite.yml` (dedicated — keep sync-skills focused):
   - **Required** `verification-gates` on PRs touching `skills/**` or `scripts/**`
   - **Scheduled** daily cron + `workflow_dispatch`
   - **Advisory** `skill-verify` with `continue-on-error: true` until #96 merges
2. Update `CLAUDE.md` Preflight: drop trailing `check-catalog-drift.sh`; list it as a
   separate advisory command.
3. Do **not** touch `run-skill-verify.sh`, skill verify rewrites, or `publish.yml`
   (Track B / #96).

## TDD plan

| Cycle | RED | GREEN |
|-------|-----|-------|
| 1 | Assert no workflow references `run-verification-gates` | Add `golden-suite.yml` with required job |
| 2 | Assert Preflight ends with always-0 drift check | Remove from Preflight chain |
| 3 | Assert no golden schedule | Add `schedule.cron` |

## Verify Steps

- [x] `grep -q run-verification-gates .github/workflows/golden-suite.yml && echo OK`
- [x] `grep -q 'continue-on-error: true' .github/workflows/golden-suite.yml && echo OK`
- [x] `grep -q 'schedule:' .github/workflows/golden-suite.yml && echo OK`
- [x] `grep -q "0 3 \* \* \*" .github/workflows/golden-suite.yml && echo OK`
- [x] Preflight chain in CLAUDE.md ends on `trace-stories.sh --strict` (no trailing always-0)
- [x] Preflight row does not reference `check-catalog-drift`
- [x] `bash scripts/run-verification-gates.sh` → 12/12 PASS (2026-07-25, worktree)
- [x] `actionlint .github/workflows/golden-suite.yml` exit 0
- [x] Preflight evidence: `npm run compliance` GATE PASS (94%); golden suite GATES_EXIT:0; sync + `trace-stories.sh --strict` exit 0

## Resolution

**Fixed:** 2026-07-25 (pending merge)
**Root cause confirmed:** Golden G-08/G-10 runner never referenced from workflows; Preflight closed with always-exit-0 Confirm gate.
**Fix applied:** `.github/workflows/golden-suite.yml` (required verification-gates + daily cron + advisory skill-verify); CLAUDE.md Preflight drops trailing `check-catalog-drift.sh`.
**Hardening:** Dedicated workflow (does not dilute sync-skills); skill-verify `continue-on-error: true` until #96 / PR #100 merges — follow-up flips to required.
**Evidence:** Local golden 12/12; actionlint clean; verify greps green.
**Commit:** (see PR)
