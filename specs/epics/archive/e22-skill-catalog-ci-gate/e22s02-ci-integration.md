---
story_id: e22s02
title: "Wire skill-verify to CI and stocktake-skills --verify mode"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e22s02: CI integration + stocktake-skills --verify

Wire `run-skill-verify.sh` into two places: the GitHub Actions CI workflow
as a non-blocking warning step, and `stocktake-skills` as a `--verify` mode
that runs the script and surfaces failures in the audit report.

## Acceptance Criteria

- [ ] `.github/workflows/ci.yml` has a `skill-health` step that runs `run-skill-verify.sh`
- [ ] CI step is `continue-on-error: true` (warning, not blocking gate)
- [ ] `stocktake-skills/SKILL.md` documents `--verify` mode
- [ ] `--verify` mode runs `run-skill-verify.sh` and appends results to the audit

## Gherkin Scenarios

```gherkin
Given a push to main triggers CI
When the skill-health step runs
Then scripts/run-skill-verify.sh executes
And FAIL skills are listed in CI output
And the workflow continues even if some skills FAIL (warning, not gate)

Given stocktake-skills --verify is invoked
When it runs
Then it calls scripts/run-skill-verify.sh internally
And appends "Verify Health: N/68 PASS, M FAIL, K SKIP" to the stocktake report
```

## Verification

```bash
grep -q "run-skill-verify" .github/workflows/ci.yml && echo "OK: CI wired" || echo "FAIL: not in CI"
grep -q "\-\-verify\|verify.*mode" stocktake-skills/SKILL.md && echo "OK: stocktake --verify" || echo "FAIL"
```

## Implementation Notes

- Add as a separate job `skill-health` in CI, not a step inside the main job
- `continue-on-error: true` prevents blocking releases on verify-command drift
- stocktake-skills --verify is additive — it doesn't change the existing Quick Scan / Full audit modes
