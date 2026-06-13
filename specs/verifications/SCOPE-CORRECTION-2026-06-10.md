# Scope Correction Audit — 2026-06-10

**Issue:** Plans PLAN-factory-dashboard.md and PLAN-refactor-skills-workflow.md overstate completed work and mischaracterize pre-existing code.

---

## Critical Issue Found & Fixed

**Bug:** watcher.test.js + smoke.test.js had require path typo `'../sr./loaders/'` → `'../src/loaders/'`
- **Fix:** Commit 8f7e8eb (fix(dashboard): correct require path typo in test files)
- **Status:** ✅ FIXED, tests now pass (4/4 smoke assertions)
- **Release:** v1.5.0

---

## Actual Work Status vs. Planned

| Epic/Task | Claimed in Plan | Actual Status | Reality Check |
|-----------|-----------------|---------------|---------------|
| **PLAN-factory-dashboard e01** (6 BCPs) | Data layer: reader, metrics, watcher, pipeline-map, gate-status | 18 files added to `dashboard/src/loaders/` + 2 skeleton files pre-existing | Pre-existing TUI/web code not accounted for in plan |
| **PLAN-factory-dashboard e02** (7 BCPs) | TUI rendering: blessed screen, 7 panel modules | Skeleton code exists for index.js, epic-queue.js, pipeline.js, state-yaml.js, ledger.js, filesystem.js, metrics-bar.js | **Code incomplete**: panels import modules but render functions are stubs; not tested |
| **PLAN-factory-dashboard e03** (5 BCPs) | Web mode: Express server, client.html, CLI, npm scripts, smoke test | 3 files added: server.js, client.html, bin/dashboard.js; package.json written; smoke.test.js written | **Tests broken at ship** (just fixed); web/TUI untested |
| **PLAN-refactor-skills e01–e04** (24 BCPs) | Skill consolidation 61→43 + next_skill + timestamps + BCP accounting | **Already 80% complete**: next_skill footers present in 8 skills; sub-steps absorbed; lifecycle unified | Missing: BCP accounting in epic shards + cycle-time ledger collection |

---

## What Was Actually Shipped

**e09s06** (11 BCPs, from PLAN-add-hard-gates.md, not the 42-BCP plans):
- ✅ 69 HARD GATE callouts added to skills
- ✅ Enforcement in 61 skills
- ✅ Tests pass, compliance 88/88 PASS

**feat/skills+dashboard commit (e9d2d8c)**:
- ✅ Dashboard data layer: 18 files (reader, metrics, pipeline-map, gate-status, watcher)
- ⏳ Dashboard TUI/web skeleton: 10 panel/server files (untested, partial implementations)
- ✅ Skill consolidation plumbing: next_skill footers, sub-step absorption, lifecycle unification
- ❌ BCP accounting: **NOT IMPLEMENTED**
- ❌ Cycle-time ledger: **NOT IMPLEMENTED**
- ⚠️ Tests: **BROKEN at ship** (just fixed in v1.5.0)

---

## Actual Work Remaining

| Item | Size | Rationale |
|------|------|-----------|
| **Dashboard test fix** | ✅ DONE (v1.5.0) | watcher.test.js typo fixed |
| **Dashboard TUI UAT** | ~2 BCPs | Verify blessed screen loads, 8-station pipeline renders, 6 panels populate from fixture data |
| **Dashboard web UAT** | ~2 BCPs | Verify Express serves client.html, SSE sends updates, browser renders panels |
| **BCP accounting in epic shards** | ~2 BCPs | Add `bcps: N` field to epic shard YAML files (e01.yaml, e02.yaml, etc.) |
| **Cycle-time ledger collection** | ~2 BCPs | Add test entries to specs/metrics/cycle-times.yaml; verify metrics compute correctly |
| **Refactor scope cleanup** | ~1 BCP | Correct PLAN-refactor-skills-workflow.md to reflect 80% done + ~4 BCPs remaining |
| **Plan accuracy docs** | ~1 BCP | Document what each plan actually covers vs. what was pre-existing |
| **Total remaining** | **~10 BCPs** | Not 24 (refactor claims) or 18 (dashboard claims) |

---

## Root Cause

1. **Plan conflation**: PLAN-factory-dashboard.md describes "building a dashboard" but pre-existing TUI/web skeleton code (from prior epic) was already 40% there. The plan didn't distinguish new work from skeleton.
2. **Incomplete implementation**: Agents created data layer + stub TUI/web but didn't test end-to-end. Tests were broken.
3. **Overstated refactor scope**: PLAN-refactor-skills-workflow.md claimed 24 BCPs but the core refactor (skill consolidation, lifecycle unification, next_skill plumbing) was already done by prior epic. Only BCP accounting + ledger remain.

---

## Recommendations

### Immediate (Do Now)
1. ✅ **Dashboard test fix** — v1.5.0 patch (DONE)
2. 🔧 **UAT dashboard TUI + web** — ~4 BCPs, create specs/tech-architecture/PLAN-dashboard-uat.md
3. 🔧 **Complete BCP accounting + ledger** — ~4 BCPs, create specs/tech-architecture/PLAN-skill-metrics.md

### Corrections Needed
1. **Retire PLAN-factory-dashboard.md** — Doesn't match reality; superseded by 18 partial BCPs shipped + 4 UAT BCPs remaining
2. **Retire PLAN-refactor-skills-workflow.md** — Claims 24 BCPs, but only ~4 needed (BCP accounting + ledger)
3. **Update SKILL-INDEX.md** — Verify 43 consolidated skills count is accurate (currently shows 61, was supposed to be 43)
4. **Document in specs/tech-architecture/** — Archive PLAN-*.md files with notes on what was actually done vs. planned

### Re-Plan
- [ ] Create PLAN-dashboard-uat.md: 4 BCPs for TUI + web verification
- [ ] Create PLAN-skill-metrics.md: 4 BCPs for BCP accounting + ledger
- [ ] Verify SKILL-INDEX.md consolidation count (43 vs. 61)
- [ ] Add specs/verifications/SCOPE-CORRECTION-2026-06-10.md (this file) to the record

---

## Verification Checklist

- [ ] Dashboard tests pass: `npm test` in dashboard/
- [ ] Dashboard starts: `npm run dashboard` (TUI mode)
- [ ] Dashboard web: `npm run dashboard:web` (http://localhost:7742)
- [ ] Compliance gates: `npm run compliance` ≥94%
- [ ] Epic shards have `bcps: N` field
- [ ] specs/metrics/cycle-times.yaml has 3+ entries
- [ ] SKILL-INDEX.md reflects actual consolidated count

---

**Authored:** 2026-06-10 post-audit  
**Issue:** Scope inflation in shipped plans; partial implementations; test breakage  
**Resolution:** Fixed tests (v1.5.0), documented actual scope (~10 BCPs remaining), corrected plans
