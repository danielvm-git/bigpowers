---
bug_id: BUG-2026-09-13-docs-base-path-gate-ci
status: fixed
severity: medium
scope: ci / website
title: "Golden suite docs-base-path gate fails in CI — website deps not installed (#128 run 34765026555)"
ci_run: https://github.com/danielvm-git/bigpowers/actions/runs/34765026555
files_changed: "scripts/validate-docs-base-path.sh, scripts/lib/golden-suite-gates.sh"
approach: "Install website/node_modules in gate when absent; wire docs-base-path golden gate on main"
risk_level: low
commit_message: "fix(ci): install website deps before docs-base-path gate"
---

# BUG-2026-09-13: docs-base-path gate CI failure

## Problem

- **Actual:** [Golden suite run 34765026555](https://github.com/danielvm-git/bigpowers/actions/runs/34765026555) on PR #128 failed `docs-base-path` (41/42 gates, exit 1).
- **Expected:** Gate passes when `prebuild.mjs` emits base-prefixed links (fixed on main via #126).
- **Reproduce:** On a clean checkout with only root `npm ci` (as golden-suite.yml does), run `bash scripts/validate-docs-base-path.sh`.

**Security impact: NONE** — CI wiring only.

## Root Cause Analysis

1. **Reproduce:** Remove `website/node_modules`, run validate script → `website build failed` on dist check.
2. **Isolate:** Static checks (index.mdx, llms.txt) pass; failure is only in the `npm run build` step.
3. **Hypothesize:** `golden-suite.yml` runs `npm ci` at repo root only. The docs gate runs `cd website && npm run build`, which requires `website/node_modules` (Astro, Starlight, etc.).
4. **Verify:** CI log shows `[docs-base-path] FAIL (.36s)` — consistent with immediate build failure, not content regression.

## TDD Fix Plan

1. **RED:** Gate fails without `website/node_modules` after root-only `npm ci`.
   **GREEN:** `ensure_website_deps()` runs `npm ci` in `website/` when Astro is missing.
   **verify:** `bash scripts/validate-docs-base-path.sh` (with empty `website/node_modules`)

2. **RED:** Gate not on main after #128 closed.
   **GREEN:** Register `docs-base-path` in `golden-suite-gates.sh`.
   **verify:** `bash scripts/run-verification-gates.sh` (or gate subset)

## Acceptance Criteria

- [x] Validate script installs website deps when missing.
- [x] Gate passes on main with community #127 prebuild fix.
- [x] Golden suite includes `docs-base-path` gate.
