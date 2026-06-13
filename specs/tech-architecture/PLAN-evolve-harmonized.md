# PLAN: Evolve bigpowers (Harmonized — Structure + HARD GATES)

**Status:** Draft
**Author:** dvm
**Date:** 2026-06-11
**Target Release:** 2.0.0 (breaking)
**Merges:**
- `specs/tech-architecture/PLAN-evolve-structure.md` (output paths, capsule dirs, verification ledger, state lock)
- `specs/tech-architecture/PLAN-add-hard-gates.md` (HARD GATE enforcement callouts for 35+ skills)

**Source Documents:**
- `docs/file-structure/projected-structure-bigpowers-evolved.md` (target layout)
- `specs/sdd-adequacy-ranking.md` (methodology comparison)
- `countable-story-format.md` (story spec contract)

---

## 1. Integration Rationale

Running the two plans sequentially would touch **15 skills twice** — once for structural changes, once for HARD GATE callouts. This plan integrates both concerns: when a SKILL.md is opened for a structural edit, HARD GATE callouts are added in the same pass.

```
Sequential approach:  55 files touched (30 evolve + 40 HARD GATES = 70 touches, 15 redundant)
Integrated approach:  55 files touched once each (30 evolve+HARD GATES + 25 HARD GATES-only)
```

**15 overlap skills** (structure change + HARD GATE needed):
`assess-impact`, `change-request`, `deepen-architecture`, `elaborate-spec`, `inspect-quality`, `map-codebase`, `model-domain`, `plan-refactor`, `run-planning`, `scope-work`, `seed-conventions`, `session-state`, `survey-context`, `validate-fix`, `visual-dashboard`

**15 evolve-only skills** (structure change, HARD GATE already present or not applicable):
`build-epic`, `define-success`, `develop-tdd`, `diagnose-root`, `execute-plan`, `fix-bug`, `investigate-bug`, `kickoff-branch`, `plan-release`, `plan-work`, `release-branch`, `run-evals`, `slice-tasks`, `trace-requirement`, `verify-work`

**25 HARD-GATES-only skills** (no structure change, just add callout):
`audit-code`, `commit-message`, `compose-workflow`, `define-language`, `delegate-task`, `design-interface`, `dispatch-agents`, `edit-document`, `enforce-first`, `evolve-skill`, `grill-me`, `guard-git`, `hook-commits`, `orchestrate-project`, `organize-workspace`, `research-first`, `respond-review`, `search-skills`, `setup-environment`, `simulate-agents`, `spike-prototype`, `stocktake-skills`, `terse-mode`, `using-bigpowers`, `wire-observability`

**55 total unique skills modified.**

---

## 2. Harmonized Implementation Phases

```
Phase 0: HARD GATES Reference (pre-requisite for all skill edits)
  ├── Create specs/tech-architecture/HARD-GATES-REFERENCE.md
  └── Define canonical HARD GATEs per phase

Phase 1: Foundation (structure + integrated HARD GATES)
  ├── H: seed-conventions scaffold rewrite (adds HARD GATEs inline)
  ├── E: session-state lock protocol (adds HARD GATEs inline)
  ├── B1: map-codebase tech-architecture/ path (adds HARD GATEs inline)
  └── HARD GATES for non-overlap Batch 4: guard-git, hook-commits

Phase 2: Directory Renames (structure + integrated HARD GATES)
  ├── A: All requirements/ → product/ updates (10 skills)
  │     Overlap: scope-work, plan-release, plan-work, slice-tasks,
  │              define-success, elaborate-spec, session-state,
  │              survey-context, visual-dashboard [all get HARD GATEs]
  │     Non-overlap: seed-conventions (already done in Phase 1)
  ├── B: All plans/ → tech-architecture/ updates (10 skills)
  │     Overlap: map-codebase (done), assess-impact, plan-refactor,
  │              deepen-architecture, model-domain [all get HARD GATEs]
  └── HARD GATES for non-overlap Batch 1-2: research-first, define-language,
        design-interface, grill-me

Phase 3: Epic Capsules + Verification (structure + integrated HARD GATES)
  ├── C: Epic capsule dirs (17 skills)
  │     Overlap: plan-release, plan-work, slice-tasks, elaborate-spec,
  │              define-success, session-state, survey-context, kickoff-branch,
  │              assess-impact, change-request, run-planning [all get HARD GATEs]
  │     Non-overlap: build-epic, execute-plan, develop-tdd, verify-work,
  │                  trace-requirement, release-branch
  ├── D: Verification ledger (3 skills)
  │     Non-overlap: verify-work, run-evals; Overlap: seed-conventions (done)
  └── HARD GATES for non-overlap Batch 5: delegate-task, dispatch-agents,
        enforce-first

Phase 4: Supporting Mechanisms (structure + integrated HARD GATES)
  ├── F: Bug registry (5 skills)
  │     Overlap: investigate-bug (gets HARD GATE), validate-fix, inspect-quality
  │     Non-overlap: fix-bug, diagnose-root
  ├── G: ADR split (3 skills)
  │     Overlap: deepen-architecture, model-domain, session-state [done]
  └── HARD GATES for non-overlap Batch 6-7-8:
        organize-workspace, stocktake-skills, evolve-skill,
        terse-mode, compose-workflow, edit-document, search-skills,
        setup-environment, simulate-agents, wire-observability,
        using-bigpowers, orchestrate-project, spike-prototype,
        commit-message, audit-code, respond-review

Phase 5: Scripts & Validation
  ├── sync-skills.sh (recognize evolved paths + HARD GATE format)
  ├── validate-specs-yaml.sh (epic.yaml, -tasks.yaml, -verify.yaml, registry.yaml)
  ├── bp-yaml-set.sh (state.yaml.lock support)
  ├── sync-status-from-epics.sh (capsule-aware)
  ├── land-branch.sh (epic capsule archive)
  └── convert-legacy.sh (migration from original → evolved)

Phase 6: Final Verification
  ├── sync-skills.sh regeneration
  ├── stocktake-skills (100% HARD GATE compliance + 100% path correctness)
  ├── validate-specs-yaml.sh (all schemas)
  └── Documentation: SKILL-INDEX.md, RELEASE.md, README.md
```

---

## 3. Per-Skill Edit Checklist

When editing a SKILL.md for the evolve plan, the build agent must apply this checklist:

### For Overlap Skills (15 skills: both structure + HARD GATEs)

```
□ 1. Update output paths (specs/product/ → specs/product/, specs/tech-architecture/ → specs/tech-architecture/)
□ 2. Update epic format references (flat YAML → capsule dirs)
□ 3. Update verification output (→ specs/verifications/)
□ 4. Update lock protocol (state.yaml.lock acquire/release)
□ 5. Add > **HARD GATE** — ... callout(s) using phase-appropriate pattern from HARD-GATES-REFERENCE.md
□ 6. Verify: grep "> \*\*HARD GATE\*\*" <skill>/SKILL.md returns at least one match
□ 7. Verify: grep "specs/product/\|specs/tech-architecture/" <skill>/SKILL.md returns 0 matches
```

### For Evolve-Only Skills (15 skills: structure changes only)

```
□ 1. Update output paths as needed per change theme
□ 2. Verify: grep "specs/product/\|specs/tech-architecture/" <skill>/SKILL.md returns 0 matches
```

### For HARD-GATES-Only Skills (25 skills: add callout only)

```
□ 1. Add > **HARD GATE** — ... callout(s) using phase-appropriate pattern
□ 2. Verify: grep "> \*\*HARD GATE\*\*" <skill>/SKILL.md returns at least one match
```

---

## 4. HARD GATE Patterns by Phase (from reference document)

Each skill gets 1–3 HARD GATE callouts relevant to its phase. The reference document (`specs/tech-architecture/HARD-GATES-REFERENCE.md`) defines canonical patterns:

| Phase | Canonical HARD GATEs |
|-------|---------------------|
| **Discover** | "Do not proceed without a concrete problem statement", "Prior art search must complete before design begins" |
| **Elaborate** | "Domain glossary must be approved before architecture decisions", "Trades must be documented in ADRs before code" |
| **Plan** | "Every task must have a runnable `verify:` command", "Impact blast radius must be mapped before any code change" |
| **Build** | "Red phase must fail before green phase begins", "No code without a story in execution-status.yaml" |
| **Verify** | "All verify commands must pass before audit-code", "UAT evidence must be persisted to specs/verifications/" |
| **Release** | "Branch must pass CI before merge", "Completed epic capsule must be archived" |
| **Sustain** | "Skill stocktake must pass before release", "Dead code must be deleted, not commented out" |
| **Utility** | "Session state must be synced with git before writes", "Environment must be validated before development begins" |

---

## 5. Combined Verification Strategy

### Per-Skill

```bash
# Structure: no legacy paths
grep -c "specs/product/\|specs/tech-architecture/" skills/<name>/SKILL.md
# Expected: 0

# HARD GATES: at least one callout present
grep -c "> \*\*HARD GATE\*\*" skills/<name>/SKILL.md
# Expected: ≥ 1 (for ALL 61 skills)
```

### Integration

```bash
# 1. Regenerate artifacts
bash scripts/sync-skills.sh

# 2. No legacy paths anywhere
grep -rn "specs/product/\|specs/tech-architecture/" skills/*/SKILL.md | wc -l
# Expected: 0

# 3. 100% HARD GATE coverage
grep -c "> \*\*HARD GATE\*\*" */SKILL.md | awk -F: '{s+=$2} END {print s}'
# Expected: ≥ 61 (at least one per skill)

# 4. YAML validation
bash scripts/validate-specs-yaml.sh

# 5. Stocktake audit (full)
# Expected: 0 missing HARD GATEs, 0 legacy path references
```

### Gherkin Acceptance

```gherkin
Scenario: Every skill has HARD GATE enforcement
  Given the bigpowers skill catalog (61 skills)
  When stocktake-skills runs a full audit
  Then every SKILL.md contains at least one "> **HARD GATE** — " callout
  And every callout matches its skill's phase pattern from HARD-GATES-REFERENCE.md

Scenario: No legacy paths remain
  Given all SKILL.md files have been updated
  When grep runs for "specs/product/" or "specs/tech-architecture/" across all skills
  Then zero matches are returned

Scenario: Evolved structure is the default scaffold
  Given a new project initialized with seed-conventions
  Then specs/product/ exists (not specs/product/)
  And specs/tech-architecture/ exists (not specs/tech-architecture/)
  And specs/verifications/ exists
  And specs/epics/archive/ exists
  And specs/state.yaml.lock is NOT pre-created (only during writes)
```

---

## 6. Risk Assessment (Harmonized)

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| HARD GATE patterns are too generic | Medium | Low | Reference document defines phase-specific patterns; per-skill review catches mismatches |
| Overlap skill edits miss one concern | Low | Medium | Checklist (Section 3) enforced per skill; automated grep verification |
| Phase 0 reference document slows start | Low | Low | Reference document is lightweight (~50 lines); creates consistency value |
| Non-overlap HARD GATE skills touched after evolve phases | Medium | Low | Phase 4 handles them in a single batch; no dependency on structure changes |
| Merge conflicts if sequential work is tried | Low | High | This plan eliminates sequential double-touches entirely |

---

## 7. Execution Order Summary

| Order | Phase | Duration | Skills | Key Output |
|-------|-------|----------|--------|------------|
| **0** | HARD-GATES-REFERENCE.md | 30 min | — | Canonical HARD GATE patterns |
| **1** | Foundation | 1 hr | 5 | seed-conventions scaffold, session-state lock, map-codebase path, guard-git + hook-commits HARD GATEs |
| **2** | Directory Renames | 2 hr | 18 | 10 skills → product/, 10 skills → tech-architecture/, + 3 HARD GATEs-only |
| **3** | Epic Capsules + Verification | 3 hr | 23 | 17 capsule-aware skills, 3 verification skills, + 3 HARD GATEs-only |
| **4** | Supporting Mechanisms | 2 hr | 24 | 5 bug registry, 3 ADR split, + 16 HARD GATEs-only |
| **5** | Scripts & Validation | 1.5 hr | 7 scripts | sync-skills, validate-specs-yaml, bp-yaml-set, etc. |
| **6** | Final Verification | 30 min | all 61 | stocktake, artifact regeneration, docs |
| | **TOTAL** | **~10.5 hr** | **61 skills + 7 scripts** | |

---

## 8. What This Plan Replaces

This harmonized plan **supersedes** both `PLAN-evolve-structure.md` and `PLAN-add-hard-gates.md` for execution purposes. Those documents remain as reference/design rationale.

---

## 9. Next Steps

1. **Approve this harmonized plan** (user review)
2. **Phase 0**: Create `specs/tech-architecture/HARD-GATES-REFERENCE.md`
3. **Switch to build agent** for Phase 1–6 execution
4. **Phase 6 verification**: `stocktake-skills` confirms 100% compliance on both structure and HARD GATES
5. **Release**: `v2.0.0` with `BREAKING CHANGE:` commit message

---

*Plan harmonized 2026-06-11. Sources: `PLAN-evolve-structure.md`, `PLAN-add-hard-gates.md`, `projected-structure-bigpowers-evolved.md`, `sdd-adequacy-ranking.md`.*
