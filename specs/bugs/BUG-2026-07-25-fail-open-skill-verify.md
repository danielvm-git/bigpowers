---
bug_id: BUG-2026-07-25-fail-open-skill-verify
status: fixed
severity: high
scope: ci
github_issue: 96
title: "67% of skill verify: directives are fail-open — runner treats exit 0 as PASS"
related:
  - BUG-2026-07-03-trace-engine-vacuous-gate
  - BUG-2026-07-03-validate-specs-no-real-parser
  - BUG-2026-07-02-skill-verify-false-fails
---

# BUG-2026-07-25: Fail-open skill verify directives (#96)

## Problem

`scripts/run-skill-verify.sh` uses exit code as verdict. Directives written as
`<check> || echo "FAIL"` or piped through `awk '{print "FAIL"}'` always exit 0.
Same bug class as BUG-2026-07-03 vacuous gates.

## Reproduce

```bash
bash -c 'test -f /nonexistent && echo OK || echo FAIL'; echo $?
bash scripts/run-skill-verify.sh audit-code   # PASS before fix
```

## Isolate

- `run-skill-verify.sh` used `head -1` — only first verify line per skill.
- `publish.yml` had `continue-on-error: true` on skill-health.
- Corpus: 37 fail-open `→ verify:` directives; 11 self-grep verifies.

## Hypothesize

Verify lines authored as human-readable status (`|| echo FAIL`, `| awk`) instead of strict exit-code gates.

## Verify

Post-fix: `bash scripts/run-skill-verify.sh` → **56 PASS, 0 FAIL, 38 SKIP**, exit 0.

| Pattern | Pre-fix | Post-fix |
|---------|---------|----------|
| `\|\|\s*echo` in `→ verify:` | 37 | 0 |
| `\|\s*awk` in `→ verify:` | (included above) | 0 |
| Self-grep own SKILL.md in `→ verify:` | 11 | 0 |

## Acceptance Criteria

- [x] Runner rejects fail-open patterns
- [x] Runner runs all verify lines per skill
- [x] Negative-path fixture self-test passes when runner is healthy
- [x] skill-health blocking on main (no continue-on-error)
- [x] `bash scripts/run-skill-verify.sh` → 0 FAIL on repo HEAD

## Resolution

**Fixed:** 2026-07-25 — runner harden + corpus rewrite in one PR (issue #96).

- `scripts/run-skill-verify.sh`: reject `|| echo` / `| awk`; run every `→ verify:`; negative fixture self-test (no `|| true` swallow).
- Rewrote fail-open + self-grep verifies across `skills/*/SKILL.md` to exit-code artifact checks.
- Dropped `continue-on-error: true` on `skill-health` in `.github/workflows/publish.yml`.
- Fixture: `specs/verifications/fixtures/skill-verify-fail-open/SKILL.md`.
