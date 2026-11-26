---
bug_id: BUG-2026-11-03-epic-status-rollup-drift
status: fixed
severity: medium
scope: planning
title: "Epic-level status drifts from its stories and from shipped code; G-12 checks only story status"
files_changed: "scripts/golden-g12-status-consistency.sh, specs/execution-status.yaml, specs/release-plan.yaml, specs/epics/e58-evals-over-compliance/epic.yaml, specs/epics/e82-fork-innovations/epic.yaml"
approach: "Extend G-12 with an epic roll-up check and a shipped-code-vs-backlog check, then correct e58 and e82 in the three status files"
risk_level: low
commit_message: "fix(specs): gate epic status roll-up in G-12 and close e58 and e82"
---

# BUG-2026-11-03: epic status drifts from stories and shipped code

## Problem

- **Actual:**
  - **e58** — all 7 stories are `done` in `execution-status.yaml` and all 7 story verifies pass, but the epic is `backlog` in `execution-status.yaml` (`development_status` and `epics:`) and `scoped` in `release-plan.yaml` and `epic.yaml`.
  - **e82** — shipped in PR #118 (`274894fe feat(e82): upstream fork innovations`). Its code is tagged (`scripts/lib/project-runtime.sh`, `extensions/omp-hooks.ts`, `CONTRIBUTORS.md`, four lifecycle skills) and its tests pass, but every status file records it as `backlog` / `scoped` / `todo`. Its stories have no `verify:`, so the story-verify gate never ran them.
- **Expected:** an epic's status agrees across `release-plan.yaml`, `execution-status.yaml` and its capsule, and matches its stories; shipped stories are recorded as done.
- **Found by:** a three-way status comparison plus re-running every verify (`.claude/EPIC_DRIFT_REVIEW.md`, 2026-11-03). The same review fixed the single-file cases (e61, e64, e69, e74, e76, e79, e86) under quick-fix.

## Root Cause Analysis

1. **Reproduce** — `bash scripts/golden-g12-status-consistency.sh` reports PASS on the drifted tree.
2. **Isolate** — G-12 has three checks: live story status vs SoT, `capsule_dir` resolves, no live+archived duplicate. None reads an epic-level `status:`, and none looks at code.
3. **Hypothesize / verify:**
   - *e58:* `build-epic` step 8 marks each story done. Nothing writes the epic key: `sync-status-from-epics.sh` is a seeder (`setdefault`), so `e58: backlog` survives, and no gate compares the epic to its stories.
   - *e82:* the epic landed as one direct `feat` PR outside `build-epic`, so no step-8 status write ran. With no story `verify:`, `run-story-verify.sh` skipped it. Statuses stayed consistently `backlog` in all three files, so even an agreement check passes. Only code evidence shows the drift.
   - The older regression test `tests/test-epic-status-drift.sh` (BUG-001) is wired into no gate, and only fires when the SoT already says done.

## Fix

1. **RED** — extend G-12:
   - **Check 4 (epic roll-up):** for each live capsule, the epic status in `development_status`, `epics:`, `release-plan.yaml` and `epic.yaml` must agree after normalisation (`scoped`/`todo` → `backlog`, `released` → `done`). If every story is done in the SoT, the epic must be done. If the epic is done, every story must be done.
   - **Check 5 (shipped but unrecorded):** a `story: <id>` tag in tracked source (not `specs/`, not dot-directory adapter outputs, not `website/`) for a live story whose SoT status is `backlog` is drift.
   - The self-test injects one failure per new check.
   → verify: `bash scripts/golden-g12-status-consistency.sh` fails naming e58 and e82.
2. **GREEN** — correct the data:
   - e58 → `done` in all four places. `BUG-2026-11-03-story-verify-e58-eval-flake` stays open: it is a CI flake in `tests/test_ab_eval.py`, and all e58 story verifies pass.
   - e82 → add a runnable story `verify:` for s01–s04, then mark the stories and the epic `done` everywhere.
   → verify: `bash scripts/golden-g12-status-consistency.sh && bash scripts/golden-g12-status-consistency.sh --self-test`
3. **Validate** — `bash scripts/run-story-verify.sh e82s01` … `e82s04`, `bash scripts/validate-specs-yaml.sh`, Preflight.

## Out of scope

- `run-story-verify.sh` selecting stories by `epic.yaml` status instead of the SoT, and not failing done stories without a verify (drift review item C2).
- Linking the open OMP bugs (`BUG-2026-09-05-pi-omp-extension-load-crash`, `BUG-2026-11-03-omp-hooks-stderr-leak`) to e82s03 (drift review item A7).
