# Plan: v1.13.0 — Harness Falsification + npm integration

## Context

The compliance harness (audit-compliance.sh) has no self-tests — there is no proof that a broken
step actually triggers FAIL. v1.13.0 adds falsification suites (intentionally bad fixtures that
MUST fail), wires `npm run compliance` for one-command invocation, and bumps package.json version
to 1.13.0.

## Steps

1. Add `npm run compliance` script to package.json that runs all feature files through the harness
   → verify: `node -e "const p=require('./package.json'); console.log(p.scripts.compliance)" | grep audit-compliance`

2. Bump package.json version to 1.13.0
   → verify: `node -e "console.log(require('./package.json').version)" | grep 1.13.0`

3. Create `specs/audit/falsification/` directory with `harness-falsification.feature` — one scenario
   whose step intentionally exits non-zero, proving the harness honours FAIL
   → verify: `[ -f specs/audit/falsification/harness-falsification.feature ] && echo ok`

4. Create `specs/audit/steps/then-this-step-always-fails.sh` that exits 1 with a clear message
   → verify: `bash specs/audit/steps/then-this-step-always-fails.sh; [ $? -eq 1 ] && echo "exits 1 correctly"`

5. Run the falsification feature through the harness and confirm it reports FAIL
   → verify: `bash scripts/audit-compliance.sh specs/audit/falsification/harness-falsification.feature 2>&1 | grep "FAIL: 1"`

6. Run `npm run compliance` in dry-run mode against all real features to confirm end-to-end
   → verify: `npm run compliance -- --dry-run 2>&1 | grep -c "FEATURE:"`

## Out of scope

- LLM caching (deferred: risk of stale verdicts outweighs benefit at current volume)
- New real feature files or step scripts beyond the falsification fixture

## Risks

- npm run compliance runs all 8 features sequentially; missing step scripts already report FAIL gracefully, so no blocking risk.
