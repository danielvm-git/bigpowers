# Release Plan: v2.45.0 — Architecture Deepening & Quality Guarantee

> Generated: 2026-07-02
> Codename: "Deepening"
> Bump: minor (feat: new benchmark infrastructure + 9 reference docs + sync pipeline refactor)
> Source documents: specs/DEEPEN-ARCHITECTURE-REVIEW.md, specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md, specs/QUALITY-GUARANTEE-STRATEGY.md

---

## ⚠️ Amendment 2026-07-02 — e31 split (supersedes the e31 section below)

Per `specs/PLAN-AUDIT_LATEST.md`: the original 22-BCP e31 bundled deterministic
gates with agent-driven golden stories whose execution mechanism (headless
`claude -p` vs mock), per-run cost, and flake rate were undecided. It is split:

| Epic | Title | BCP | WSJF | Status |
|------|-------|-----|------|--------|
| e31 | Quality Guarantee — Deterministic Gates | 11 | 9.5 | next up — G-04 self-test, compliance→CI, size budget, baseline, docs, evolve-skill |
| e37 | Golden Story Suite — Agent-Driven | 13 | 1.8 | spike-gated — e37s01 (headless-harness spike, go/no-go ADR) is a HARD GATE before fixture/YAML/harness work |

Canonical story lists: `specs/epics/e31-quality-guarantee/epic.yaml` and
`specs/epics/e37-golden-stories/epic.yaml`. Build order becomes
e31 → e32 → e34 → e35 → e33 → e36 → e37 (e37s01 spike may run in parallel
any time; e37s02–s04 only on a documented "go"). Golden-story flake policy:
pass@k 2-of-3; cadence per-epic, not per-story. The e31 section below is
kept for provenance and is no longer authoritative.

---

## Release Context

Current state: v2.44.1, 72 skills, e26 (security-review) and e29 (skills-directory) in progress, e28 (docs website) in backlog.

This release delivers the architecture deepening from the deepen-architecture review, the missing historical references, the context-engineering layer, and the quality-guarantee infrastructure that makes all future improvements safe to ship.

Three specs documents drive this release:
1. DEEPEN-ARCHITECTURE-REVIEW.md — 8 deepening candidates + 4 concrete bugs
2. MISSING-REFERENCES-AND-DELIVERY-PLAN.md — 9 missing references + target end state + 6-epic plan
3. QUALITY-GUARANTEE-STRATEGY.md — 3-gate quality strategy + golden stories

---

## Epic Queue (WSJF ordered)

| ID | Title | WSJF | BCP | Status | Capsule |
|----|-------|------|-----|--------|---------|
| e30 | Architecture Quick Fixes | 6.5 | 10 | proposed | epics/e30-arch-quick-fixes |
| e31 | Quality Guarantee Infrastructure | 5.5 | 22 | proposed | epics/e31-quality-guarantee |
| e32 | Missing Historical References | 3.0 | 20 | proposed | epics/e32-historical-refs |
| e33 | Sync Pipeline Refactor | 2.0 | 13 | proposed | epics/e33-sync-pipeline |
| e34 | Context Engineering Layer | 2.75 | 10 | proposed | epics/e34-context-engineering |
| e35 | DORA Metrics Extension | 2.67 | 7 | proposed | epics/e35-dora-metrics |
| e36 | Documentation Deduplication | 1.4 | 10 | proposed | epics/e36-doc-dedup |

---

## Epic Details

### e30 — Architecture Quick Fixes (WSJF: 10/1.5 = 6.5)

Fix the 4 concrete bugs from the architecture review + add plan-checker gate. Mechanical, no design decisions.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e30s01 | 2 | Add extract-design, security-review, visual-dashboard to get_phase() in generate-skill-index.sh | `bash scripts/sync-skills.sh && grep 'Total:.*72' SKILL-INDEX.md` |
| e30s02 | 2 | Fix 4 broken specs/tech-architecture/ references in orchestrate-project and seed-conventions | `grep -rn 'tech-architecture/test.md\|tech-architecture/design.md\|tech-architecture/security.md' skills/ && echo FAIL || echo OK` |
| e30s03 | 1 | Delete specs/verifications/features/karpathy.feature.bak | `test ! -f specs/verifications/features/karpathy.feature.bak && echo OK` |
| e30s04 | 3 | Replace 50+ tautological verify commands with behavior-relevant checks or remove | `grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md | grep -v ':0$' | wc -l | awk '{if($1==0) print "OK"; else print "REMAINING: "$1}'` |
| e30s05 | 2 | Add plan-checker as mandatory gate in build-epic SKILL.md (insert assess-impact between plan-work and kickoff-branch) | `grep -q 'assess-impact\|audit-plan' skills/build-epic/SKILL.md && grep -q 'gate\|mandatory' skills/build-epic/SKILL.md && echo OK` |

**Total**: 5 stories, 10 BCP
**next_skill chain**: e30s01 → e30s02 → e30s03 → e30s04 → e30s05 → release-branch

---

### e31 — Quality Guarantee Infrastructure (WSJF: 11/2 = 5.5)

Build the 3-gate quality system (golden stories + compliance + token budget) that makes all future epics safe to ship. Ship second because every subsequent epic depends on it.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e31s01 | 3 | Create specs/benchmarks/fixtures/minimal-api/ (fixture repo with createUser + test for golden stories) | `test -d specs/benchmarks/fixtures/minimal-api && test -f specs/benchmarks/fixtures/minimal-api/package.json && echo OK` |
| e31s02 | 3 | Create 5 golden story YAMLs in specs/benchmarks/golden/ (g-01 through g-05, each with code grader) | `ls specs/benchmarks/golden/g-0*.yaml | wc -l | awk '{if($1==5) print "OK"; else print "FAIL: "$1}'` |
| e31s03 | 5 | Create scripts/run-golden-suite.sh — iterates golden stories, runs grader, writes report, compares baseline | `bash scripts/run-golden-suite.sh --dry-run && echo OK` |
| e31s04 | 2 | Wire `npm run compliance` as first step of run-golden-suite.sh (Gate 2 integration) | `grep -q 'compliance\|audit-compliance' scripts/run-golden-suite.sh && echo OK` |
| e31s05 | 3 | Add token estimation to run-golden-suite.sh (sum SKILL.md sizes + state.yaml size + tool call count) | `grep -q 'token\|estimated_tokens' scripts/run-golden-suite.sh && echo OK` |
| e31s06 | 2 | Pin current state as baseline: specs/benchmarks/reports/BASELINE-GOLDEN.yaml | `test -f specs/benchmarks/reports/BASELINE-GOLDEN.yaml && grep -q 'pass_rate' specs/benchmarks/reports/BASELINE-GOLDEN.yaml && echo OK` |
| e31s07 | 2 | Add "Run golden suite" to CLAUDE.md and CONVENTIONS.md as mandatory pre-merge step | `grep -q 'golden.*suite\|run-golden-suite' CLAUDE.md CONVENTIONS.md && echo OK` |
| e31s08 | 2 | Extend evolve-skill SKILL.md to call run-golden-suite.sh instead of per-skill run-benchmark | `grep -q 'run-golden-suite' skills/evolve-skill/SKILL.md && echo OK` |

**Total**: 8 stories, 22 BCP
**next_skill chain**: e31s01 → e31s02 → e31s03 → e31s04 → e31s05 → e31s06 → e31s07 → e31s08 → release-branch

---

### e32 — Missing Historical References (WSJF: 12/4 = 3.0)

Add the 9 missing historical reference docs and cross-reference them from the skills that use their concepts.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e32s01 | 2 | Create docs/references/kent-beck.md (XP, TDD origins, Tidy First? — tidy vs refactor vs behavior) | `test -f docs/references/kent-beck.md && grep -q 'Tidy First' docs/references/kent-beck.md && echo OK` |
| e32s02 | 2 | Create docs/references/fowler.md (refactoring catalog, code smells, named refactorings) | `test -f docs/references/fowler.md && grep -q 'Extract Method\|code smell' docs/references/fowler.md && echo OK` |
| e32s03 | 2 | Create docs/references/feathers.md (seams, characterization tests, legacy code = code without tests) | `test -f docs/references/feathers.md && grep -q 'characterization\|seam' docs/references/feathers.md && echo OK` |
| e32s04 | 2 | Create docs/references/pragmatic-programmer.md (DRY, broken windows, tracer bullets, programming by coincidence) | `test -f docs/references/pragmatic-programmer.md && grep -q 'broken window\|tracer bullet\|coincidence' docs/references/pragmatic-programmer.md && echo OK` |
| e32s05 | 2 | Create docs/references/rich-hickey.md (simple vs easy, complecting) | `test -f docs/references/rich-hickey.md && grep -q 'simple.*easy\|complect' docs/references/rich-hickey.md && echo OK` |
| e32s06 | 2 | Create docs/references/sandi-metz.md (SOLID in practice, message-level testing) | `test -f docs/references/sandi-metz.md && grep -q 'SOLID\|message' docs/references/sandi-metz.md && echo OK` |
| e32s07 | 2 | Create docs/references/ddd.md (bounded contexts, context mapping, ubiquitous language) | `test -f docs/references/ddd.md && grep -q 'bounded context\|context map' docs/references/ddd.md && echo OK` |
| e32s08 | 2 | Create docs/references/accelerate.md (DORA four keys) | `test -f docs/references/accelerate.md && grep -q 'DORA\|four key' docs/references/accelerate.md && echo OK` |
| e32s09 | 2 | Update PRINCIPLES.md to credit Beck, Fowler, Feathers, Hunt & Thomas alongside Uncle Bob in layer 1 | `grep -q 'Beck\|Fowler\|Feathers\|Hunt' docs/PRINCIPLES.md && echo OK` |
| e32s10 | 2 | Cross-reference new docs from SKILL.md bodies (plan-refactor → fowler, audit-code → fowler, investigate-bug → feathers, grill-me → hickey) | `grep -q 'fowler' skills/plan-refactor/SKILL.md && grep -q 'feathers\|characterization' skills/investigate-bug/SKILL.md && echo OK` |

**Total**: 10 stories, 20 BCP
**next_skill chain**: e32s01 → e32s02 → ... → e32s10 → release-branch

---

### e33 — Sync Pipeline Refactor (WSJF: 10/5 = 2.0)

Refactor the build pipeline from copy-paste-variant to parse→IR→render.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e33s01 | 3 | Create scripts/lib/skill-common.sh with resolve_repo_root, resolve_skills_root, parse_frontmatter, iterate_skills | `source scripts/lib/skill-common.sh && parse_frontmatter skills/audit-code/SKILL.md && echo OK` |
| e33s02 | 2 | Refactor 13 scripts to source skill-common.sh instead of duplicating REPO_ROOT/SKILLS_ROOT | `grep -c 'REPO_ROOT=.*dirname.*BASH_SOURCE' scripts/*.sh | grep -v ':0$' | wc -l | awk '{if($1<=1) print "OK"; else print "REMAINING: "$1}'` |
| e33s03 | 5 | Refactor sync-skills.sh to use render-target functions (one function per target) | `bash scripts/sync-skills.sh && test -f .cursor/rules/audit-code.mdc && test -f .gemini/extensions/bigpowers/skills/audit-code/SKILL.md && test -f .pi/skills/audit-code/SKILL.md && echo OK` |
| e33s04 | 3 | Refactor regenerate-lockfile.sh, generate-skill-index.sh, build-skill-index.sh to source skill-common.sh | `bash scripts/sync-skills.sh && jq '.skills | length' skills-lock.json | awk '{if($1==72) print "OK"; else print "FAIL: "$1}'` |

**Total**: 4 stories, 13 BCP
**next_skill chain**: e33s01 → e33s02 → e33s03 → e33s04 → release-branch

---

### e34 — Context Engineering Layer (WSJF: 11/4 = 2.75)

Name the context-engineering strategies bigpowers already implements and add effort frontmatter.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e34s01 | 2 | Create docs/references/context-engineering.md (LangChain write/select/compress/isolate, Karpathy definition) | `test -f docs/references/context-engineering.md && grep -q 'write.*select.*compress.*isolate' docs/references/context-engineering.md && echo OK` |
| e34s02 | 3 | Add optional effort: heavy|light frontmatter to all 72 skills (heavy = orchestrators, light = utilities) | `grep -rl 'effort:' skills/*/SKILL.md | wc -l | awk '{if($1>=10) print "OK"; else print "FAIL: "$1}'` |
| e34s03 | 2 | Update CLAUDE.md Token Management section with context-engineering vocabulary | `grep -q 'write.*select.*compress.*isolate\|effort:' CLAUDE.md && echo OK` |
| e34s04 | 3 | Update session-state SKILL.md to name the four context-engineering strategies explicitly | `grep -q 'write\|select\|compress\|isolate' skills/session-state/SKILL.md && echo OK` |

**Total**: 4 stories, 10 BCP
**next_skill chain**: e34s01 → e34s02 → e34s03 → e34s04 → release-branch

---

### e35 — DORA Metrics Extension (WSJF: 8/3 = 2.67)

Extend from BCP/hr only to all four DORA keys.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e35s01 | 2 | Extend specs/metrics/cycle-times.yaml schema with change_failure_rate and restore_time_minutes | `grep -q 'change_failure_rate\|restore_time' docs/references/accelerate.md && echo OK` |
| e35s02 | 3 | Update release-branch to compute change_failure_rate and restore_time_minutes | `grep -q 'change_failure_rate\|restore_time' skills/release-branch/SKILL.md && echo OK` |
| e35s03 | 2 | Update CONVENTIONS.md BCP accounting section to reference DORA four keys | `grep -q 'DORA\|deployment.frequency\|change.failure' CONVENTIONS.md && echo OK` |

**Total**: 3 stories, 7 BCP
**next_skill chain**: e35s01 → e35s02 → e35s03 → release-branch

---

### e36 — Documentation Deduplication (WSJF: 7/5 = 1.4)

Replace hub-and-spoke duplication with provenance pointers.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e36s01 | 3 | Convert docs/references/uncle-bob.md to provenance pointer | `wc -l docs/references/uncle-bob.md | awk '{if($1<20) print "OK"; else print "FAIL: "$1}'` |
| e36s02 | 3 | Convert akita.md, ousterhout.md, karpathy.md, wasowski.md to provenance pointers | `for f in akita ousterhout karpathy wasowski; do wc -l docs/references/$f.md | awk '{if($1>30) print "FAIL: '$f'"}'; done && echo OK` |
| e36s03 | 2 | Remove F.I.R.S.T restatement from enforce-first/SKILL.md and audit-code/SKILL.md; cross-ref CONVENTIONS.md | `grep -c 'Fast.*Independent.*Repeatable' skills/enforce-first/SKILL.md skills/audit-code/SKILL.md | awk -F: '{sum+=$2} END{if(sum<=1) print "OK"; else print "FAIL: "sum}'` |
| e36s04 | 2 | Update docs/references/spec-kit.md to cover full SDD tool landscape (Kiro, Tessl, BMAD, GSD, bigpowers) | `grep -q 'Kiro\|Tessl' docs/references/spec-kit.md && echo OK` |

**Total**: 4 stories, 10 BCP
**next_skill chain**: e36s01 → e36s02 → e36s03 → e36s04 → release-branch

---

## Release Summary

| Epic | Title | Stories | BCP | WSJF | Priority |
|------|-------|---------|-----|------|----------|
| e30 | Architecture Quick Fixes | 5 | 10 | 6.5 | 1st — ship immediately |
| e31 | Quality Guarantee Infrastructure | 8 | 22 | 5.5 | 2nd — enables safe shipping of all others |
| e32 | Missing Historical References | 10 | 20 | 3.0 | 3rd — high value, low effort |
| e34 | Context Engineering Layer | 4 | 10 | 2.75 | 4th — borrows GSD's best idea |
| e35 | DORA Metrics Extension | 3 | 7 | 2.67 | 5th — extends BCP innovation |
| e33 | Sync Pipeline Refactor | 4 | 13 | 2.0 | 6th — structural, needs design |
| e36 | Documentation Deduplication | 4 | 10 | 1.4 | 7th — lowest urgency, highest churn |

**Totals**: 7 epics, 38 stories, 92 BCP

---

## Build Order

```
e30 (Quick Fixes)           ← fixes bugs, adds plan-checker gate
  ↓
e31 (Quality Guarantee)     ← golden suite, so all following epics are safe
  ↓
e32 (Historical References) ← 9 reference docs + PRINCIPLES.md update
  ↓
e34 (Context Engineering)   ← effort: frontmatter + LangChain vocabulary
  ↓
e35 (DORA Metrics)          ← extend cycle-times.yaml to four keys
  ↓
e33 (Sync Pipeline)         ← parse→IR→render refactor
  ↓
e36 (Doc Dedup)             ← provenance pointers, slim reference docs
```

After each epic: run golden suite (e31 deliverable). If any golden story regresses, fix before proceeding to the next epic.

---

## Relationship to Existing Backlog

| Existing epic | Status | Action |
|---------------|--------|--------|
| e26 (Security-Review) | active | Continues independently — not blocked by this release |
| e28 (Docs Website) | backlog | Continues independently — not blocked by this release |
| e29 (Skills-Directory) | active (step 8, release-branch) | Finish first, then start e30 |

This release does not touch e26, e28, or e29. It adds e30-e36 as a parallel track that can be built after e29 lands.

---

## What This Release Delivers

After all 7 epics ship:

1. **4 bugs fixed** — phase table accuracy, broken references, stale file, tautological verify commands
2. **Quality guarantee** — 5 golden stories + compliance gate + token budget, run before every merge
3. **9 historical references** — Beck, Fowler, Feathers, Metz, Hickey, Hunt & Thomas, Evans, Forsgren, Larson
4. **Context engineering** — named discipline, effort: frontmatter, LangChain four strategies
5. **DORA four keys** — deployment frequency, lead time, change failure rate, restore time (alongside BCP/hr)
6. **Sync pipeline** — parse→IR→render, shared library, render-target functions
7. **Documentation** — provenance pointers instead of restatements, single source of truth in CONVENTIONS.md

The skillset is measurably better after each epic because the golden suite (e31) proves no regression.

---

*End of release plan*
