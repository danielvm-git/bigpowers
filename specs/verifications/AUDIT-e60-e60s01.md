# Audit Report — e60s01: Interactive Installer (Wave 0 closeout)

**Date:** 2026-07-24
**Mode:** `--gate`
**Epic:** e60 — Interactive Installer — BMAD-Polished Setup for bigpowers
**Story:** e60s01 — Interactive installer with ASCII banner, global/local, tool selection
**Files:** `bin/setup.js`, `scripts/lib/install-helpers.js`, `package.json` (bin/scripts/@clack), `scripts/test-install-helpers.js`, `scripts/test-install-helpers.sh`
**Churn rank (90d, repo top):** specs/state.yaml, package.json (hub), CONVENTIONS.md — e60 surface itself is low-churn relative to SoT; reviewed install hub files first.

**Verify:**
```bash
node --check bin/setup.js && node --check scripts/lib/install-helpers.js
bash scripts/test-install-helpers.sh
```
**Verify result:** PASS

---

## Gate summary (stderr-style)

```
PASS Supply Chain & Security
PASS Provenance & Metadata
PASS Law of Demeter
PASS CONVENTIONS.md Compliance
PASS Scope
PASS Boy Scout Rule
PASS Types and Safety
PASS Test Coverage
PASS SOLID and Heuristics
PASS Code Style
PASS Agent Readability
```

---

## Supply Chain & Security

- [x] slopcheck N/A for Wave 0 re-audit (existing `@clack/prompts` only; no new deps this closeout)
- [x] No `[SLOP]` packages
- [x] No secrets in diff
- [x] OWASP spot-check: installer only creates local symlinks; no auth/network; command via fixed `bash scripts/sync-skills.sh`
- [x] Security: no HIGH findings; Claude hook source path corrected (was pointing at missing `guard-git/` — silent no-op install)

## Provenance & Metadata

- [x] Capsule `specs/epics/e60-interactive-installer/epic.yaml` has status/stories/files
- [x] Story tags `# story: e60s01` on implementation + regression selftest

## Law of Demeter

- [x] No unrelated method chains
- [x] setup.js → install-helpers neighbors only

## CONVENTIONS.md Compliance

- [x] Audit output in `specs/verifications/`
- [x] No `gh issue create` / direct GitHub REST in installer

## Scope

- [x] Wave 0 closeout fixes only: broken Claude hook path, `pi` missing from TOOLS, dead `ALL_ID`, bogus `handleUninstall(clack)` arg, regression selftest
- [x] No speculative features
- [x] Discovered defect (missing hook path) fixed via Always Green — not dismissed

## Boy Scout Rule

- [x] Removed unused `ALL_ID`
- [x] Fixed misleading `handleUninstall(clack)` call
- [x] No dead/commented-out blocks left

## Types and Safety

- [x] Plain JS; no `any` / `@ts-ignore` / unsafe casts

## Test Coverage

- [x] Regression selftest covers Claude hook symlink target + pi installGlobal + TOOLS/pi invariant
- [x] Interactive TTY flow remains manual-verify via capsule `verify:` (acceptable for CLI UI)
- [x] F.I.R.S.T: headless, independent temp HOME, self-validating

## SOLID and Heuristics

- [x] SRP: UI in setup.js, FS/symlinks in install-helpers.js
- [x] Tool extension via switch + TOOLS table
- [x] No Chapter 17 smell blockers for closeout scope

## Code Style (CONVENTIONS.md)

- [x] Files under 300 lines
- [x] Shared link helpers extracted
- [x] Early returns / cancel paths present
- [x] `main()` / `handleUninstall()` are longer than 20 lines (CLI orchestration) — noted, not a Wave 0 rebuild

## Agent Readability

- [x] Unique names (`installGlobal`, `linkSkills`, `detectExistingInstall`)
- [x] Max nesting acceptable; early cancel returns

## Red Flags / rationalizations caught

- Prior audit marked Test Coverage unchecked but overall PASS — **not acceptable under `--gate`**. Closeout adds regression selftest for the hook-path bug fix.
- `linkHook` silently returns when src missing — that hid the wrong path. Path fixed; selftest asserts existence + symlink target.

---

## Fixes applied before PASS

1. `install-helpers.js`: Claude `block-dangerous-git.sh` source → `skills/guard-git/scripts/...`
2. `bin/setup.js`: add `pi` to `TOOLS`; remove dead `ALL_ID`; drop bogus arg to `handleUninstall`
3. Added `scripts/test-install-helpers.{js,sh}`

**Overall: PASS** (`exit 0`)

**Next:** `request-review` (Santa Method dual-blind AND-gate)
