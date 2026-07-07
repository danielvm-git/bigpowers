---
bug_id: BUG-2026-07-07-e48-audit-gaps
status: fixed
severity: high
scope: ci
title: "e48 audit gaps — OKF CI non-blocking, stub wiki tools, missing generator tests"
security_impact: NONE
files_changed: ".github/workflows/sync-skills.yml, docs/references/okf.md, tests/test-okf-generators.sh, kernel/src/publish-to-wiki.sh, bin/bigspec, scripts/generate-epics-wiki.sh, scripts/generate-adr-wiki.sh"
approach: "Make OKF validation blocking in sync-skills.yml; add generator regression test; implement publish-to-wiki dry-run link rewrite; flesh out bigspec --with-wiki guidance"
commit_message: "fix(ci): enforce blocking OKF validation and close e48 audit gaps"
---

# BUG-2026-07-07-e48-audit-gaps: e48 audit findings

## Problem

`audit-code e48` (2026-07-07) reported **CONCERNS** with three failing checklist sections:

1. **e48s05 HARD GATE drift** — `sync-skills.yml` OKF step uses `continue-on-error: true` and `::warning::` only; epic labels e48s05 as HARD GATE.
2. **Stub implementations** — `kernel/src/publish-to-wiki.sh` echoes and exits 0; `bin/bigspec --with-wiki` is a one-line echo.
3. **Missing regression tests** — `generate-epics-wiki.sh`, `generate-adr-wiki.sh`, `sync-bugs-registry.sh` have no dedicated test script.

**Expected:** OKF validation fails CI on invalid bundles; publish-to-wiki `--dry-run` rewrites links and reports manifest; generator scripts covered by headless test.

**Reproduce:**

```bash
grep 'continue-on-error' .github/workflows/sync-skills.yml   # true on OKF step
bash kernel/src/publish-to-wiki.sh                            # stub message only
test -f tests/test-okf-generators.sh || echo MISSING
```

## Root Cause Analysis

- e48s05 verify command only checks `grep validate-okf.sh` in workflow — not blocking behavior.
- e48s07/e48s10 verify commands only check file existence / flag presence — not behavior.
- OKF generators rely on `validate-okf.sh` in preflight but lack behavioral regression tests.

**Risk:** Medium-high — invalid OKF bundles can merge silently; wiki publish tooling misleads operators.

## TDD Fix Plan

1. **RED:** No `tests/test-okf-generators.sh`; OKF CI step non-blocking.
   **GREEN:** Add test script; remove `continue-on-error`, fail on first `validate-okf.sh` error.
   **verify:** `bash tests/test-okf-generators.sh`

2. **RED:** `publish-to-wiki.sh --dry-run` exits without processing bundles.
   **GREEN:** Dry-run copies bundles to temp dir with header injection + link rewrite; prints manifest.
   **verify:** `bash kernel/src/publish-to-wiki.sh --dry-run | grep -q 'pages:'`

3. **RED:** `bigspec --with-wiki` prints only "wiki enabled".
   **GREEN:** Print setup instructions referencing publish-to-wiki and okf.md.
   **verify:** `bash bin/bigspec init --with-wiki | grep -q publish-to-wiki`

4. **REFACTOR:** Update `docs/references/okf.md` CI section to document blocking gate; add `# story: e48s01` tags to generator scripts.

## Acceptance Criteria

- [x] `sync-skills.yml` OKF step fails build on validation errors
- [x] `bash tests/test-okf-generators.sh` exits 0
- [x] `bash kernel/src/publish-to-wiki.sh --dry-run` reports page manifest
- [x] `docs/references/okf.md` describes blocking CI behavior
- [x] `bash scripts/run-verification-gates.sh` still PASS
