# Traceability Matrix — Epics e01–e29

**Generated:** 2026-07-07 (updated)
**Source:** `specs/release-plan.yaml`, `specs/epics/e01-*.yaml` through `e29-*.yaml`, `specs/execution-status.yaml`
**Scope:** Epics e01 (Security) through e29 (Skills Directory)
**Script used:** `trace-requirement` skill (manual execution)

---

## Coverage Summary

| Metric | Value |
|--------|-------|
| Total stories | **32** |
| Covered (has `story:` tag in implementing code) | **32** |
| Dark (no `story:` tag in any file) | **0** |
| Orphan (tagged code with no matching story) | **0** |
| Data inconsistencies resolved | **1** (e03s03) |

---

## Story Coverage

### Epic e01 — Security (4 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e01s01 | slopcheck tags in `plan-work` ([OK]/[SUS]/[SLOP]) | 2 | `skills/plan-work/SKILL.md` | Covered |
| e01s02 | Supply-chain + OWASP in `audit-code` | 1 | `skills/audit-code/SKILL.md` | Covered |
| e01s03 | Secret patterns documented in `guard-git` | 1 | `skills/guard-git/SKILL.md` | Covered |
| e01s04 | `docs/references/security-threats.md` reconciled | 1 | `docs/references/security-threats.md` | Covered |

### Epic e02 — Verification & Evals (4 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e02s01 | `verify-work`, `run-evals` skills | 3 | `skills/verify-work/SKILL.md`, `skills/run-evals/SKILL.md` | Covered |
| e02s02 | Verification Script template in `plan-work` | 1 | `skills/plan-work/SKILL.md` | Covered |
| e02s03 | UAT checkpoint in `execute-plan` | 1 | `skills/execute-plan/SKILL.md` | Covered |
| e02s04 | RED/GREEN/REFACTOR commits in `develop-tdd` | 1 | `skills/develop-tdd/SKILL.md` | Covered |

### Epic e03 — Discovery & Planning (3 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e03s01 | `research-first`, `scope-work`, `slice-tasks`, `grill-with-docs` | 4 | `skills/research-first/SKILL.md`, `skills/scope-work/SKILL.md`, `skills/slice-tasks/SKILL.md`, `skills/grill-with-docs/SKILL.md` | Covered |
| e03s02 | `using-bigpowers` lifecycle updated | 1 | `skills/using-bigpowers/SKILL.md` | Covered |
| e03s03 | Absorb 5 near-duplicate utility skills into session-state and survey-context | 2 | `skills/session-state/SKILL.md`, `skills/survey-context/SKILL.md` | Covered |

### Epic e04 — Ergonomics (3 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e04s01 | Handoff + compaction in `session-state` | 1 | `skills/session-state/SKILL.md` | Covered |
| e04s02 | `terse-mode` caveman rules (existing) | 1 | `skills/terse-mode/SKILL.md` | Covered |
| e04s03 | `organize-workspace` gitignore section (existing) | 1 | `skills/organize-workspace/SKILL.md` | Covered |

### Epic e05 — Context Isolation + Routing (3 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e05s01 | `model:` on all SKILL.md | 2 | `scripts/sync-skills.sh`, `CONVENTIONS.md` | Covered |
| e05s02 | `execute-plan` isolation + STATE.md channel | 1 | `skills/execute-plan/SKILL.md` | Covered |
| e05s03 | `orchestrate-project` reads model + spawn list | 1 | `skills/orchestrate-project/SKILL.md` | Covered |

### Epic e06 — Taxonomy & Provenance (3 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e06s01 | `type:` / `context:` in plan-work template | 1 | `skills/plan-work/SKILL.md` | Covered |
| e06s02 | ADR/SHA refs on steps | 1 | `CONVENTIONS.md` | Covered |
| e06s03 | `audit-code` metadata checks | 1 | `skills/audit-code/SKILL.md` | Covered |

### Epic e07 — Architectural Complexity (3 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e07s01 | Demeter in CONVENTIONS.md + audit-code | 2 | `CONVENTIONS.md`, `skills/audit-code/SKILL.md` | Covered |
| e07s02 | Module Depth score in deepen-architecture | 1 | `skills/deepen-architecture/SKILL.md` | Covered |
| e07s03 | Concurrency audit in model-domain | 1 | `skills/model-domain/SKILL.md` | Covered |

### Epic e08 — Wave Execution (1 story)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e08s01 | Waves + `depends-on:` in execute-plan | 1 | `skills/execute-plan/SKILL.md` | Covered |

### Epic e09 — Self-Evolution (6 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e09s01 | stocktake-skills, evolve-skill, search-skills, compose-workflow, simulate-agents | 5 | `skills/stocktake-skills/SKILL.md`, `skills/evolve-skill/SKILL.md`, `skills/search-skills/SKILL.md`, `skills/compose-workflow/SKILL.md`, `skills/simulate-agents/SKILL.md` | Covered |
| e09s02 | `specs/METHODOLOGY.md` | 1 | `specs/epics/e09-self-evolution.yaml` | Covered |
| e09s03 | craft-skill README generator | 1 | `skills/craft-skill/SKILL.md` | Covered |
| e09s04 | Iterative retrieval in dispatch-agents / delegate-task | 2 | `skills/dispatch-agents/SKILL.md`, `skills/delegate-task/SKILL.md` | Covered |
| e09s05 | evolve-skill benchmark path documented | 1 | `skills/evolve-skill/SKILL.md` | Covered |
| e09s06 | Add HARD GATE enforcement callouts to 35 skills | 1 | `specs/tech-architecture/HARD-GATES-REFERENCE.md` | Covered |

### Epic e10 — Stack Profiles (2 stories)

| Story | Title | Files | Implementing files | Status |
|-------|-------|-------|-------------------|--------|
| e10s01 | profiles/swift.md, typescript-vue.md, node-service.md | 1 | `skills/seed-conventions/SKILL.md` | Covered |
| e10s02 | seed-conventions profile picker | 1 | `skills/seed-conventions/SKILL.md` | Covered |

---

## Coverage Summary (both passes)

| Metric | e01–e10 | e20–e29 | Total |
|--------|---------|---------|-------|
| Total stories | **32** | **39** | **71** |
| Covered (has `story:` tag in implementing code) | **32** | **39** | **71** |
| Dark (no `story:` tag in any file) | **0** | **0** | **0** |
| Orphan (tagged code with no matching story) | **0** | **0** | **0** |

---

### Epic e20 — Build-Epic Ergonomics & Flow Polish (6 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e20s01 | change-request conversational intake | `skills/change-request/SKILL.md` | Covered |
| e20s02 | Reduce state.yaml commit noise — squash-state | `skills/release-branch/SKILL.md` | Covered |
| e20s03 | kickoff-branch pre-commit for spec artifacts | `skills/kickoff-branch/SKILL.md` | Covered |
| e20s04 | verify-work verify-command validation | `skills/verify-work/SKILL.md` | Covered |
| e20s05 | build-epic --fast mode for token efficiency | `skills/build-epic/SKILL.md` | Covered |
| e20s06 | verify-work --cli mode for CLI tools | `skills/verify-work/SKILL.md` | Covered |

### Epic e21 — MCP-Native Discovery & Tool Integration (4 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e21s01 | MCP-native skill discovery | `skills/search-skills/SKILL.md` | Covered |
| e21s02 | Wire opensrc into research-first | `skills/research-first/SKILL.md` | Covered |
| e21s03 | CI-aware skills — preflight from AGENTS.md | `scripts/bp-read-agents.sh` | Covered |
| e21s04 | compose-workflow → agentic stack mapping | `skills/compose-workflow/SKILL.md` | Covered |

### Epic e22 — Skill Catalog CI Gate (2 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e22s01 | scripts/run-skill-verify.sh | `scripts/run-skill-verify.sh` | Covered |
| e22s02 | Wire skill-verify to CI and stocktake-skills --verify | `skills/stocktake-skills/SKILL.md` | Covered |

### Epic e23 — Benchmark Infrastructure (3 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e23s01 | specs/benchmarks/ schema and seed definitions | `specs/benchmarks/SCHEMA.md` | Covered |
| e23s02 | Create run-benchmark skill | `skills/run-benchmark/SKILL.md` | Covered |
| e23s03 | Wire evolve-skill to use benchmark output | `skills/evolve-skill/SKILL.md` | Covered |

### Epic e24 — Planning Context Capsule (3 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e24s01 | elaborate-spec writes planning-context.yaml | `skills/elaborate-spec/SKILL.md` | Covered |
| e24s02 | scope-work reads planning-context.yaml | `skills/scope-work/SKILL.md` | Covered |
| e24s03 | run-planning tracks context in planning-status.yaml | `skills/run-planning/SKILL.md` | Covered |

### Epic e25 — Migrate-Spec Methodology Enhancements (6 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e25s01 | Promote ID tracking to first-class fields | `skills/migrate-spec/SKILL.md` | Covered |
| e25s02 | Emit REQUIREMENTS_TRACE.yaml on migration | `skills/migrate-spec/SKILL.md` | Covered |
| e25s03 | Promote handoff block to mandatory Step 4 output | `skills/migrate-spec/SKILL.md` | Covered |
| e25s04 | Add adversarial review pass after migration | `skills/migrate-spec/SKILL.md` | Covered |
| e25s05 | Add two-pass spec writing gate | `skills/migrate-spec/SKILL.md` | Covered |
| e25s06 | Add methodology doc template | `skills/migrate-spec/SKILL.md` | Covered |

### Epic e26 — Security-Review Lifecycle Integration (7 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e26s01 | Core security-review skill + reference files | `skills/security-review/SKILL.md` | Covered |
| e26s02 | build-epic integration — threat model step | `skills/security-review/SKILL.md` | Covered |
| e26s03 | plan-work / plan-release integration | `skills/security-review/SKILL.md` | Covered |
| e26s04 | audit-code / request-review integration | `skills/security-review/SKILL.md` | Covered |
| e26s05 | verify-work integration — Phase 5 security scan | `skills/security-review/SKILL.md` | Covered |
| e26s06 | release-branch hard gate | `skills/security-review/SKILL.md` | Covered |
| e26s07 | fix-bug / validate-fix integration | `skills/security-review/SKILL.md` | Covered |

### Epic e27 — Specs Output Naming Convention (1 story)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e27s01 | Rename generated specs-root files to _LATEST.md | `CONVENTIONS.md` | Covered |

### Epic e28 — Sync Pipeline Refactor (4 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e28s01 | Create scripts/lib/skill-common.sh with shared functions | `scripts/lib/skill-common.sh` | Covered (pre-existing) |
| e28s02 | Refactor 13 scripts to source skill-common.sh | `scripts/sync-skills.sh` | Covered |
| e28s03 | Refactor sync-skills.sh render-target functions | `scripts/sync-skills.sh` | Covered (pre-existing) |
| e28s04 | Refactor index scripts to source skill-common.sh | `scripts/build-skill-index.sh` | Covered (pre-existing) |

### Epic e29 — Repository Layout — Skill Sources Under skills/ (3 stories)

| Story | Title | Implementing files | Status |
|-------|-------|-------------------|--------|
| e29s01 | Location-agnostic skill discovery in consumer scripts | `scripts/sync-skills.sh` | Covered |
| e29s02 | Relocate skill sources to skills/ and re-point CI | `scripts/sync-skills.sh` | Covered |
| e29s03 | Root cleanup and doctrine update | `CONVENTIONS.md` | Covered |

---

## Changes Made (e20–e29)

| File | Tags added |
|------|-----------|
| `skills/change-request/SKILL.md` | e20s01 |
| `skills/release-branch/SKILL.md` | e20s02 |
| `skills/kickoff-branch/SKILL.md` | e20s03 |
| `skills/verify-work/SKILL.md` | e20s04, e20s06 |
| `skills/build-epic/SKILL.md` | e20s05 |
| `skills/search-skills/SKILL.md` | e21s01 |
| `skills/research-first/SKILL.md` | e21s02 |
| `scripts/bp-read-agents.sh` | e21s03 |
| `skills/compose-workflow/SKILL.md` | e21s04 |
| `scripts/run-skill-verify.sh` | e22s01 |
| `skills/stocktake-skills/SKILL.md` | e22s02 |
| `specs/benchmarks/SCHEMA.md` | e23s01 |
| `skills/run-benchmark/SKILL.md` | e23s02 |
| `skills/evolve-skill/SKILL.md` | e23s03 |
| `skills/elaborate-spec/SKILL.md` | e24s01 |
| `skills/scope-work/SKILL.md` | e24s02 |
| `skills/run-planning/SKILL.md` | e24s03 |
| `skills/migrate-spec/SKILL.md` | e25s01, e25s02, e25s03, e25s04, e25s05, e25s06 |
| `skills/security-review/SKILL.md` | e26s01, e26s02, e26s03, e26s04, e26s05, e26s06, e26s07 |
| `CONVENTIONS.md` | e27s01, e29s03 |
| `scripts/sync-skills.sh` | Reformatted from space-separated to one-per-line; added e28s02, e29s01, e29s02 |
| `scripts/lib/skill-common.sh` | Already tagged (e28s01) |
| `scripts/build-skill-index.sh` | Already tagged (e28s04) |

---

## Orphan Code (no matching story)

**No orphan tags found.** All `# story:` tags in implementing files correspond to planned epics in the release plan.

---

## Gaps Closed

All 32 stories were originally **dark** — none had `story:` tags in implementing files because they predated the P0 traceability mandate (e38s08). All are now tagged.

### Changes made

| File | Tags added |
|------|-----------|
| `skills/plan-work/SKILL.md` | e01s01, e02s02, e06s01 |
| `skills/audit-code/SKILL.md` | e01s02, e06s03, e07s01 |
| `skills/guard-git/SKILL.md` | e01s03 |
| `docs/references/security-threats.md` | e01s04 |
| `skills/verify-work/SKILL.md` | e02s01 |
| `skills/run-evals/SKILL.md` | e02s01 |
| `skills/execute-plan/SKILL.md` | e02s03, e05s02, e08s01 |
| `skills/develop-tdd/SKILL.md` | e02s04 |
| `skills/research-first/SKILL.md` | e03s01 |
| `skills/scope-work/SKILL.md` | e03s01 |
| `skills/slice-tasks/SKILL.md` | e03s01 |
| `skills/grill-with-docs/SKILL.md` | e03s01 |
| `skills/using-bigpowers/SKILL.md` | e03s02 |
| `skills/session-state/SKILL.md` | e03s03, e04s01 |
| `skills/survey-context/SKILL.md` | e03s03 |
| `skills/terse-mode/SKILL.md` | e04s02 |
| `skills/organize-workspace/SKILL.md` | e04s03 |
| `scripts/sync-skills.sh` | e05s01 |
| `CONVENTIONS.md` | e05s01, e06s02, e07s01 |
| `skills/orchestrate-project/SKILL.md` | e05s03 |
| `skills/deepen-architecture/SKILL.md` | e07s02 |
| `skills/model-domain/SKILL.md` | e07s03 |
| `skills/stocktake-skills/SKILL.md` | e09s01 |
| `skills/evolve-skill/SKILL.md` | e09s01, e09s05 |
| `skills/search-skills/SKILL.md` | e09s01 |
| `skills/compose-workflow/SKILL.md` | e09s01 |
| `skills/simulate-agents/SKILL.md` | e09s01 |
| `skills/craft-skill/SKILL.md` | e09s03 |
| `skills/dispatch-agents/SKILL.md` | e09s04 |
| `skills/delegate-task/SKILL.md` | e09s04 |
| `specs/epics/e09-self-evolution.yaml` | e09s02 |
| `specs/tech-architecture/HARD-GATES-REFERENCE.md` | e09s06 |
| `skills/seed-conventions/SKILL.md` | e10s01, e10s02 |
| `specs/epics/e03-discovery-planning.yaml` | Added e03s03 definition |
| `specs/epics/e45-quality-core/epic.yaml` | Fixed indentation bug (pre-existing) |

---

## Verification

`bash scripts/trace-stories.sh --strict` — **PASS** (exit 0)
