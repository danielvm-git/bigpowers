# Release Plan — v3.0.0: Architecture Deepening

> Generated: 2026-07-02
> Source: specs/DEEPEN-ARCHITECTURE-REVIEW.md, specs/MISSING-REFERENCES-AND-DELIVERY-PLAN.md, specs/QUALITY-GUARANTEE-STRATEGY.md
> Status: Proposed
> Codename: "Deepening"

---

## Release Summary

| Dimension | Before (v2.44.1) | After (v3.0.0) |
|-----------|-------------------|-----------------|
| Skills | 72 | 72 (no count change) |
| Reference docs | 27 (restated principles) | 36 (9 new + existing slimmed to provenance) |
| Sync pipeline | Copy-paste targets | parse→IR→render with shared library |
| Quality gates | Per-skill benchmarks (3/72) | Golden story suite (5 stories) + compliance + token budget |
| Metrics | BCP/hr only | BCP/hr + DORA four keys |
| Context engineering | Scattered, unnamed | Named discipline, effort: frontmatter |
| Historical coverage | Uncle Bob, Ousterhout, Akita, Karpathy, Wasowski | + Beck, Fowler, Feathers, Metz, Hickey, Hunt & Thomas, Evans, Forsgren, Larson |
| Bugs | 4 known (index, refs, bak, tautological verify) | 0 |
| Phase table accuracy | 69/72 (3 missing) | 72/72 |

**Versioning**: Major bump (v3.0.0) — breaking changes to sync-skills.sh internals, CONVENTIONS.md additions, new mandatory quality gate. semantic-release decides the actual number at merge.

---

## Epic Queue — WSJF Ordered

| Epic | Title | WSJF | BCP | Stories | Priority |
|------|-------|------|-----|---------|----------|
| e30 | Quality Guarantee Infrastructure | 8.0 | 22 | 8 | 1st — must ship first, makes all other epics safe |
| e31 | Quick Fixes | 6.5 | 10 | 5 | 2nd — mechanical, zero design |
| e32 | Missing Historical References | 3.0 | 20 | 10 | 3rd — high value, low effort |
| e33 | Sync Pipeline Refactor | 2.5 | 13 | 4 | 4th — structural, needs design |
| e34 | Context Engineering Layer | 2.75 | 10 | 4 | 5th — borrows GSD's best idea |
| e35 | DORA Metrics Extension | 2.67 | 7 | 3 | 6th — extends BCP innovation |
| e36 | Documentation Deduplication | 1.4 | 10 | 4 | 7th — lowest urgency, highest churn |
| **Total** | | | **92** | **38** | |

---

## Epic 30: Quality Guarantee Infrastructure

> WSJF: 8.0 (BV 8 + TC 4 + RR-OE 4) / JS 2 = 8.0
> BCP: 22 · Stories: 8 · Capsule: specs/epics/e30-quality-guarantee
> Why first: Every subsequent epic needs the golden suite to prove it didn't regress. Without this, we're shipping improvements on faith.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e30s01 | 3 | Create specs/benchmarks/fixtures/minimal-api/ (fixture repo with createUser + test file) | `test -d specs/benchmarks/fixtures/minimal-api && test -f specs/benchmarks/fixtures/minimal-api/src/users.js && test -f specs/benchmarks/fixtures/minimal-api/src/users.test.js && echo OK` |
| e30s02 | 3 | Create 5 golden story YAMLs in specs/benchmarks/golden/ (g-01 through g-05 per QUALITY-GUARANTEE-STRATEGY.md §7) | `ls specs/benchmarks/golden/g-0*.yaml \| wc -l \| awk '{if($1>=5) print "OK"; else print "FAIL: "$1}'` |
| e30s03 | 5 | Create scripts/run-golden-suite.sh — iterates golden stories, copies fixture, runs grader, writes GOLDEN-<date>.yaml report, compares baseline | `bash scripts/run-golden-suite.sh --dry-run && echo OK` |
| e30s04 | 2 | Wire `npm run compliance` as first step of run-golden-suite.sh (compliance < 94% → suite fails before stories run) | `grep -q 'compliance\|audit-compliance' scripts/run-golden-suite.sh && echo OK` |
| e30s05 | 3 | Add token estimation to run-golden-suite.sh — sum SKILL.md sizes loaded + state.yaml size + tool call count. Report token_delta_vs_baseline in golden report | `grep -q 'token\|estim' scripts/run-golden-suite.sh && echo OK` |
| e30s06 | 2 | Create specs/benchmarks/reports/BASELINE-GOLDEN.yaml — pin current state as baseline by running the suite once | `test -f specs/benchmarks/reports/BASELINE-GOLDEN.yaml && echo OK` |
| e30s07 | 2 | Add "Run golden suite" to CLAUDE.md and CONVENTIONS.md as mandatory pre-merge step (between audit-code and release-branch) | `grep -q 'golden.*suite\|run-golden' CLAUDE.md CONVENTIONS.md && echo OK` |
| e30s08 | 2 | Extend evolve-skill SKILL.md to call run-golden-suite.sh instead of per-skill run-benchmark for regression checks | `grep -q 'golden-suite\|run-golden' skills/evolve-skill/SKILL.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 31: Quick Fixes

> WSJF: 6.5 (BV 6 + TC 3 + RR-OE 4) / JS 2 = 6.5
> BCP: 10 · Stories: 5 · Capsule: specs/epics/e31-quick-fixes
> Prerequisite: e30 (golden suite must exist to verify these fixes don't regress)

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e31s01 | 2 | Add extract-design, security-review, visual-dashboard to get_phase() case statement in generate-skill-index.sh. extract-design → Verify, security-review → Verify, visual-dashboard → Sustain | `bash scripts/sync-skills.sh && grep -A5 'Sustain' SKILL-INDEX.md \| grep -q 'visual-dashboard' && grep 'TOTAL' SKILL-INDEX.md \| grep -q '72' && echo OK` |
| e31s02 | 2 | Fix 4 broken specs/tech-architecture/ references in orchestrate-project/SKILL.md (test.md) and seed-conventions/SKILL.md (design.md, security.md, test.md) — update to correct paths (TECH_STACK_LATEST.md or docs/references/) | `grep -rn 'tech-architecture/test.md\|tech-architecture/design.md\|tech-architecture/security.md' skills/ && echo "FAIL: still broken" \|\| echo OK` |
| e31s03 | 1 | Delete specs/verifications/features/karpathy.feature.bak | `test ! -f specs/verifications/features/karpathy.feature.bak && echo OK` |
| e31s04 | 3 | Replace 50+ tautological verify commands (`test -f <name>/SKILL.md && grep -q '^name:'`) with either removal (sync-skills.sh already validates) or behavior-relevant checks. Priority: critical-path skills (build-epic, verify-work, audit-code, release-branch) get behavior checks; others get removal | `grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md \| grep -v ':0$' \| wc -l \| awk '{if($1==0) print "OK"; else print "REMAINING: "$1}'` |
| e31s05 | 2 | Add plan-checker as mandatory gate in build-epic SKILL.md — insert assess-impact step between plan-work (step 2) and kickoff-branch (step 3) in the 8-step cycle | `grep -q 'assess-impact\|audit-plan' skills/build-epic/SKILL.md && grep -q 'gate\|mandatory' skills/build-epic/SKILL.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 32: Missing Historical References

> WSJF: 3.0 (BV 6 + TC 2 + RR-OE 4) / JS 4 = 3.0
> BCP: 20 · Stories: 10 · Capsule: specs/epics/e32-historical-references
> Prerequisite: e30 (golden suite verifies reference docs don't break anything)

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e32s01 | 2 | Create docs/references/kent-beck.md — XP origins, TDD (RED-GREEN-REFACTOR), "Tidy First?" tidy vs refactor vs behavior change distinction | `test -f docs/references/kent-beck.md && grep -q 'Tidy First' docs/references/kent-beck.md && echo OK` |
| e32s02 | 2 | Create docs/references/fowler.md — Refactoring catalog, code smells taxonomy (Long Method, God Class, Feature Envy), named refactorings (Extract Method, Inline Class), smells→refactorings mapping | `test -f docs/references/fowler.md && grep -q 'Extract Method\|code smell' docs/references/fowler.md && echo OK` |
| e32s03 | 2 | Create docs/references/feathers.md — Working Effectively with Legacy Code: seams (already borrowed by deepen-architecture), characterization tests, legacy = code without tests, dependency-breaking techniques | `test -f docs/references/feathers.md && grep -q 'characterization\|seam' docs/references/feathers.md && echo OK` |
| e32s04 | 2 | Create docs/references/pragmatic-programmer.md — Hunt & Thomas: DRY, broken windows (source of Boy Scout Rule), tracer bullets (maps to spike-prototype), orthogonality, programming by coincidence | `test -f docs/references/pragmatic-programmer.md && grep -q 'broken window\|tracer bullet\|coincidence' docs/references/pragmatic-programmer.md && echo OK` |
| e32s05 | 2 | Create docs/references/rich-hickey.md — "Simple Made Easy": simple (one fold, unmixed) vs easy (near to hand, familiar), complecting as complexity source | `test -f docs/references/rich-hickey.md && grep -q 'simple.*easy\|complect' docs/references/rich-hickey.md && echo OK` |
| e32s06 | 2 | Create docs/references/sandi-metz.md — POODR: SOLID in practice at class level, message-level testing (test messages between objects not internal state), single responsibility applied to classes | `test -f docs/references/sandi-metz.md && grep -q 'SOLID\|message' docs/references/sandi-metz.md && echo OK` |
| e32s07 | 2 | Create docs/references/ddd.md — Domain-Driven Design: bounded contexts (strategic design), context mapping, ubiquitous language (already in model-domain), aggregates/repositories (tactical) | `test -f docs/references/ddd.md && grep -q 'bounded context\|context map' docs/references/ddd.md && echo OK` |
| e32s08 | 2 | Create docs/references/accelerate.md — DORA four keys: deployment frequency, lead time for changes, time to restore, change failure rate. Evidence-based metrics correlating with delivery performance | `test -f docs/references/accelerate.md && grep -q 'DORA\|four key' docs/references/accelerate.md && echo OK` |
| e32s09 | 2 | Update PRINCIPLES.md — credit Beck, Fowler, Feathers, Hunt & Thomas in layer 1 (Classical Craftsmanship); add Hickey to layer 2; add Accelerate/DORA to synthesis layer | `grep -q 'Beck\|Fowler\|Feathers\|Hunt' docs/PRINCIPLES.md && echo OK` |
| e32s10 | 2 | Cross-reference new docs from SKILL.md bodies: plan-refactor → fowler, audit-code → fowler smells, investigate-bug → feathers characterization, grill-me → hickey simple-vs-easy, spike-prototype → pragmatic-programmer tracer bullets | `grep -q 'fowler' skills/plan-refactor/SKILL.md && grep -q 'feathers\|characterization' skills/investigate-bug/SKILL.md && grep -q 'hickey\|simple.*easy' skills/grill-me/SKILL.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 33: Sync Pipeline Refactor

> WSJF: 2.5 (BV 5 + TC 3 + RR-OE 2) / JS 4 = 2.5
> BCP: 13 · Stories: 4 · Capsule: specs/epics/e33-sync-pipeline
> Prerequisite: e30 (golden suite G-04 verifies sync pipeline), e31 (fixes must be in first)
> Note: This is the highest structural-impact change. The sync pipeline G-04 golden story is the regression gate.

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e33s01 | 3 | Create scripts/lib/skill-common.sh — exports: resolve_repo_root, resolve_skills_root, parse_frontmatter (returns name/model/description), iterate_skills (yields skill_dir paths). Sourceable by all scripts. | `source scripts/lib/skill-common.sh && parse_frontmatter skills/audit-code/SKILL.md && echo OK` |
| e33s02 | 2 | Refactor 13 scripts to source skill-common.sh instead of duplicating REPO_ROOT/SKILLS_ROOT boilerplate (add-model-frontmatter, bp-yaml-set, bp-yaml-snapshot, build-skill-index, convert-legado, enrich-epics-from-archive, generate-skill-index, install, regenerate-lockfile, sync-bugs-registry, sync-skills, sync-status-from-epics, validate-specs-yaml) | `grep -c 'REPO_ROOT=.*dirname.*BASH_SOURCE' scripts/*.sh \| grep -v ':0$' \| wc -l \| awk '{if($1<=1) print "OK"; else print "REMAINING: "$1}'` |
| e33s03 | 5 | Refactor sync-skills.sh to use render-target functions: extract render_cursor(), render_gemini_skill(), render_gemini_command(), render_pi_skill(), render_pi_prompt(). Each takes (name, model, description, body, output_dir). The loop body becomes: parse_frontmatter → for each render function → call it. Adding a target = adding a function. | `bash scripts/sync-skills.sh && test -f .cursor/rules/audit-code.mdc && test -f .gemini/extensions/bigpowers/skills/audit-code/SKILL.md && test -f .pi/skills/audit-code/SKILL.md && echo OK` |
| e33s04 | 3 | Refactor regenerate-lockfile.sh, generate-skill-index.sh, build-skill-index.sh to source skill-common.sh and use shared parse_frontmatter (eliminates 3 copies of awk description extraction with different escaping) | `bash scripts/sync-skills.sh && jq '.skills \| length' skills-lock.json \| awk '{if($1==72) print "OK"; else print "FAIL: "$1}'` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 34: Context Engineering Layer

> WSJF: 2.75 (BV 5 + TC 3 + RR-OE 3) / JS 4 = 2.75
> BCP: 10 · Stories: 4 · Capsule: specs/epics/e34-context-engineering
> Prerequisite: e30 (golden suite verifies context engineering additions don't regress)

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e34s01 | 2 | Create docs/references/context-engineering.md — LangChain's write/select/compress/isolate framework mapped to bigpowers mechanisms (state.yaml=write, survey-context=select, terse-mode=compress, delegate-task=isolate). Karpathy's definition. | `test -f docs/references/context-engineering.md && grep -q 'write.*select.*compress.*isolate' docs/references/context-engineering.md && echo OK` |
| e34s02 | 3 | Add optional `effort:` frontmatter to all 72 skills. Heavy (orchestrators that spawn subagents): build-epic, execute-plan, orchestrate-project, delegate-task, dispatch-agents, verify-work, run-planning. Light (quick lookups): terse-mode, session-state, search-skills, reset-baseline, bp-timing-related. Default: medium (omit frontmatter). | `grep -rl 'effort:' skills/*/SKILL.md \| wc -l \| awk '{if($1>=10) print "OK"; else print "FAIL: "$1}'` |
| e34s03 | 2 | Update CLAUDE.md Token Management section — replace vague "20 turns" heuristic with context-engineering vocabulary (write/select/compress/isolate) and reference effort: frontmatter. Add rule: "When context feels heavy, switch to terse-mode and delegate heavy-effort skills to fresh subagents." | `grep -q 'write.*select.*compress.*isolate\|effort:' CLAUDE.md && echo OK` |
| e34s04 | 3 | Update session-state SKILL.md — name the four context-engineering strategies explicitly, map each to its bigpowers mechanism, add effort: heavy to session-state frontmatter | `grep -q 'write\|select\|compress\|isolate' skills/session-state/SKILL.md && grep -q 'effort:' skills/session-state/SKILL.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 35: DORA Metrics Extension

> WSJF: 2.67 (BV 4 + TC 3 + RR-OE 4) / JS 4 = 2.67
> BCP: 7 · Stories: 3 · Capsule: specs/epics/e35-dora-metrics
> Prerequisite: e32s08 (accelerate.md reference must exist first)

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e35s01 | 2 | Extend specs/metrics/cycle-times.yaml schema to include change_failure_rate and restore_time_minutes fields per story. Document the schema in CONVENTIONS.md BCP accounting section. | `grep -q 'change_failure_rate\|restore_time' CONVENTIONS.md && echo OK` |
| e35s02 | 3 | Update release-branch SKILL.md — compute change_failure_rate (count fix-bug cycles triggered within 7 days of release) and restore_time_minutes (bug_cycle start to validate-fix end). Write to cycle-times.yaml. | `grep -q 'change_failure_rate\|restore_time' skills/release-branch/SKILL.md && echo OK` |
| e35s03 | 2 | Update CONVENTIONS.md BCP accounting section — reference DORA four keys alongside BCP/hr. Add table mapping each DORA key to its bigpowers mechanism. | `grep -q 'DORA\|deployment.frequency\|change.failure' CONVENTIONS.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Epic 36: Documentation Deduplication

> WSJF: 1.4 (BV 4 + TC 2 + RR-OE 2) / JS 5 = 1.4
> BCP: 10 · Stories: 4 · Capsule: specs/epics/e36-doc-dedup
> Prerequisite: e32 (new reference docs must exist first so we don't create then immediately slim them)

| Story | BCP | Description | Verify |
|-------|-----|-------------|--------|
| e36s01 | 3 | Convert docs/references/uncle-bob.md from restating principles to provenance pointer: "See CONVENTIONS.md §Code Style and §Tests. Source: Clean Code, Robert C. Martin, 2008." Keep only the source citation + section pointer. | `wc -l docs/references/uncle-bob.md \| awk '{if($1<20) print "OK: slimmed"; else print "FAIL: "$1" lines"}'` |
| e36s02 | 3 | Convert docs/references/akita.md, ousterhout.md, karpathy.md, wasowski.md to provenance pointers — keep only source citation + CONVENTIONS.md/PRINCIPLES.md section references | `for f in akita ousterhout karpathy wasowski; do wc -l docs/references/$f.md \| awk '{if($1>30) print "FAIL: '$f' still long"}'; done && echo OK` |
| e36s03 | 2 | Remove F.I.R.S.T rubric restatement from enforce-first/SKILL.md and audit-code/SKILL.md — replace with "See CONVENTIONS.md §Tests (F.I.R.S.T)" | `grep -c 'Fast.*Independent.*Repeatable' skills/enforce-first/SKILL.md skills/audit-code/SKILL.md \| awk -F: '{sum+=$2} END{if(sum<=1) print "OK"; else print "FAIL: "sum}'` |
| e36s04 | 2 | Update docs/references/spec-kit.md to cover full SDD tool landscape (Kiro, spec-kit, Tessl, BMAD, GSD, bigpowers) with Fowler's framing from e32 | `grep -q 'Kiro\|Tessl' docs/references/spec-kit.md && echo OK` |

**next_skill**: survey-context → plan-work → kickoff-branch → develop-tdd → verify-work → audit-code → release-branch

---

## Execution Order

```
e30 (Quality Guarantee)  ← MUST ship first
  ↓ golden suite exists, baseline pinned
e31 (Quick Fixes)        ← mechanical, zero design risk
  ↓ bugs fixed, golden suite passes
e32 (Historical References) ← additive, low risk
  ↓ 9 new reference docs
e33 (Sync Pipeline)       ← structural, needs design
  ↓ parse→IR→render, golden suite G-04 verifies
e34 (Context Engineering)  ← additive metadata
  ↓ effort: frontmatter, named discipline
e35 (DORA Metrics)         ← extends metrics
  ↓ four keys tracked
e36 (Doc Dedup)            ← cleanup
  ↓ provenance pointers, drift eliminated
  ↓
RELEASE v3.0.0 — tag via semantic-release
```

### Pre-existing backlog (not part of this release)

| Epic | Title | Status | Action |
|------|-------|--------|--------|
| e26 | Security-Review Lifecycle Integration | active | Continue in parallel — does not conflict |
| e28 | Docs Website — Fourth Generated Artifact Target | backlog | Defer to v3.1.0 — depends on e33 (sync pipeline refactor) for clean artifact target addition |
| e29 | Repository Layout — Skills Under skills/ | active | Continue in parallel — does not conflict |

### What's NOT in this release (and why)

- **Near-cousin skill merging** (delegate-task/dispatch-agents, grill-me/grill-with-docs): Controversial — 72-skill count is a feature. Defer until user feedback shows navigation friction.
- **Flat script directory reorganization**: Changes path references everywhere. Defer to v3.1.0 after sync pipeline is refactored (e33 makes reorg easier).
- **context7.mdc promotion**: Minor. Defer.
- **Lifecycle hooks** (PreCompact etc): Requires runtime-specific implementation per IDE. Defer until bigpowers has more runtime support.
- **New skills**: No new skills added in this release. The value is in deepening existing skills, not adding count.

---

## Quality Gates Per Epic

Every epic in this release must pass these gates before merging:

1. **Golden Suite** (e30 output): `bash scripts/run-golden-suite.sh` — all 5 stories pass, no regression from baseline
2. **Compliance**: `npm run compliance` — ≥ 94%
3. **Token Budget**: Token delta vs baseline ≤ +20% (or ADR justifying tradeoff)
4. **Sync Pipeline**: `bash scripts/sync-skills.sh` — exits 0, all artifacts generated
5. **Validate YAML**: `bash scripts/validate-specs-yaml.sh` — exits 0
6. **Doctrine**: `bash scripts/validate-doctrine.sh` — exits 0

The golden suite is the new gate. Everything else already exists.

---

## WSJF Calculation Detail

WSJF = (Business Value + Time Criticality + Risk Reduction / Opportunity Enablement) / Job Size

| Epic | BV | TC | RR/OE | JS | WSJF |
|------|----|----|-------|----|------|
| e30 Quality Guarantee | 8 | 4 | 4 | 2 | 8.0 |
| e31 Quick Fixes | 6 | 3 | 4 | 2 | 6.5 |
| e32 Historical References | 6 | 2 | 4 | 4 | 3.0 |
| e33 Sync Pipeline | 5 | 3 | 2 | 4 | 2.5 |
| e34 Context Engineering | 5 | 3 | 3 | 4 | 2.75 |
| e35 DORA Metrics | 4 | 3 | 4 | 4 | 2.67 |
| e36 Doc Dedup | 4 | 2 | 2 | 5 | 1.4 |

**e30 ranks highest** because it enables safe shipping of every other epic. Without the golden suite, we can't prove any improvement is actually an improvement — we're shipping on faith. The RR/OE score of 4 reflects that the golden suite reduces risk for all subsequent work.

**e31 ranks second** because the bugs are concrete and the fixes are mechanical. The RR/OE of 4 reflects that fixing the phase table (3 missing skills) and broken references improves navigability for all agents.

---

## State Tracking

After this release plan is approved:

```yaml
# specs/state.yaml additions
active_flow: build_epic
epic_cycle:
  epic_id: e30
  epic_slug: quality-guarantee
  capsule_dir: specs/epics/e30-quality-guarantee
  current_story: e30s01
  total_bcps: 22
  story_bcps: 3
  current_step: 1
  completed_steps: []
handoff:
  next_skill: survey-context
  last_step_completed: release plan v3.0.0 approved
release:
  target_version: "3.0.0"
  codename: "Deepening"
  bump_hint: major
```

```yaml
# specs/execution-status.yaml additions
  e30: backlog
  e30s01: backlog
  e30s02: backlog
  e30s03: backlog
  e30s04: backlog
  e30s05: backlog
  e30s06: backlog
  e30s07: backlog
  e30s08: backlog
  e31: backlog
  e31s01: backlog
  e31s02: backlog
  e31s03: backlog
  e31s04: backlog
  e31s05: backlog
  e32: backlog
  e32s01: backlog
  # ... through e36s04
```

---

*End of release plan*
