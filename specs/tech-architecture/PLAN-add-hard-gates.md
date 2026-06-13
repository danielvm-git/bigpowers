# Plan: Add HARD GATE Callouts to 35 Skills

**Status:** Planning  
**Priority:** High (compliance with CONVENTIONS.md)  
**Scope:** Add HARD GATE enforcement callouts to 35 skills missing them  
**Date:** 2026-06-10  
**Trigger:** stocktake-skills audit identified 61 → 35 missing HARD GATEs

## Context

Stocktake audit (2026-06-10) identified that 35 of 61 skills lack HARD GATE enforcement callouts. HARD GATEs are critical decision points and constraints that must be respected during skill execution.

**Format:** Blockquote markdown `> **HARD GATE** — [constraint description]`

**Reference Example:** `plan-work/SKILL.md` lines 11-13

## Skills Requiring HARD GATE Addition (35 total)

### Batch 1: Discovery & Planning Phase (4 skills)
- `survey-context`
- `map-codebase`
- `research-first` (already has "Use when...")
- `elaborate-spec` (not in missing list but verify)

### Batch 2: Elaborate Phase (6 skills)
- `define-language`
- `deepen-architecture`
- `design-interface`
- `grill-me`
- `model-domain`
- `research-first`

### Batch 3: Plan Phase (4 skills)
- `assess-impact`
- `plan-refactor`
- `scope-work`
- `change-request`

### Batch 4: Initiate Phase (3 skills)
- `guard-git`
- `hook-commits`
- `seed-conventions`

### Batch 5: Build Phase (4 skills)
- `delegate-task`
- `dispatch-agents`
- `enforce-first`
- `run-planning`

### Batch 6: Sustain Phase (4 skills)
- `inspect-quality`
- `organize-workspace`
- `stocktake-skills`
- `evolve-skill`

### Batch 7: Utility Phase (10 skills)
- `terse-mode`
- `compose-workflow`
- `edit-document`
- `session-state`
- `search-skills`
- `setup-environment`
- `simulate-agents`
- `validate-fix`
- `visual-dashboard`
- `wire-observability`

### Batch 8: Core/Special (4 skills)
- `using-bigpowers` (Bootstrap)
- `orchestrate-project` (Orchestrate)
- `spike-prototype` (Spike)
- `commit-message` (Integrate)
- `audit-code` (Review)
- `respond-review` (Review)

**Total:** 35 skills

## Implementation Steps

### Step 1: Define HARD GATE Patterns for Each Phase
Create a reference document listing canonical HARD GATEs for each phase (Discovery, Plan, Build, etc.)

**Rationale:** Ensures consistency; skills in the same phase will have thematically related gates  
**Verify:** `test -f specs/tech-architecture/HARD-GATES-REFERENCE.md && grep -c "^##" specs/tech-architecture/HARD-GATES-REFERENCE.md`

### Step 2: Update Batch 1 (Discovery & Planning — 4 skills)
Add HARD GATE callouts to: `survey-context`, `map-codebase`, `research-first`, `elaborate-spec`

**Focus:** Gates around scope clarity, stakeholder alignment, prior art validation

**Verify:** 
```bash
for skill in survey-context map-codebase research-first elaborate-spec; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 3: Update Batch 2 (Elaborate Phase — 6 skills)
Add HARD GATEs to: `define-language`, `deepen-architecture`, `design-interface`, `grill-me`, `model-domain`

**Focus:** Gates around domain understanding, interface completeness, architectural trade-offs

**Verify:**
```bash
for skill in define-language deepen-architecture design-interface grill-me model-domain; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 4: Update Batch 3 (Plan Phase — 4 skills)
Add HARD GATEs to: `assess-impact`, `plan-refactor`, `scope-work`, `change-request`

**Focus:** Gates around scope boundaries, impact assessment, success criteria clarity

**Verify:**
```bash
for skill in assess-impact plan-refactor scope-work change-request; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 5: Update Batch 4 (Initiate Phase — 3 skills)
Add HARD GATEs to: `guard-git`, `hook-commits`, `seed-conventions`

**Focus:** Gates around git hygiene, hook correctness, convention enforcement

**Verify:**
```bash
for skill in guard-git hook-commits seed-conventions; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 6: Update Batch 5 (Build Phase — 4 skills)
Add HARD GATEs to: `delegate-task`, `dispatch-agents`, `enforce-first`, `run-planning`

**Focus:** Gates around task clarity, agent coordination, enforcement priorities

**Verify:**
```bash
for skill in delegate-task dispatch-agents enforce-first run-planning; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 7: Update Batch 6 (Sustain Phase — 4 skills)
Add HARD GATEs to: `inspect-quality`, `organize-workspace`, `stocktake-skills`, `evolve-skill`

**Focus:** Gates around quality metrics, workspace hygiene, skill evolution mandates

**Verify:**
```bash
for skill in inspect-quality organize-workspace stocktake-skills evolve-skill; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 8: Update Batch 7 (Utility Phase — 10 skills)
Add HARD GATEs to: `terse-mode`, `compose-workflow`, `edit-document`, `session-state`, `search-skills`, `setup-environment`, `simulate-agents`, `validate-fix`, `visual-dashboard`, `wire-observability`

**Focus:** Gates around mode switches, workflow composition, environment setup, verification rigor

**Verify:**
```bash
for skill in terse-mode compose-workflow edit-document session-state search-skills setup-environment simulate-agents validate-fix visual-dashboard wire-observability; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 9: Update Batch 8 (Core/Special — 6 skills)
Add HARD GATEs to: `using-bigpowers`, `orchestrate-project`, `spike-prototype`, `commit-message`, `audit-code`, `respond-review`

**Focus:** Gates around lifecycle entry, meta-skill mandates, code review rigor

**Verify:**
```bash
for skill in using-bigpowers orchestrate-project spike-prototype commit-message audit-code respond-review; do
  grep -q "> \*\*HARD GATE\*\*" $skill/SKILL.md || echo "MISSING: $skill"
done | wc -l
```

### Step 10: Regenerate Artifacts
Run sync-skills.sh to regenerate .cursor/rules and .gemini/ artifacts with updated skills

**Verify:** `bash scripts/sync-skills.sh && echo "Artifacts regenerated successfully"`

### Step 11: Final Verification
Run stocktake-skills again to confirm 100% HARD GATE compliance

**Verify:** `bash scripts/sync-skills.sh && grep -c "> \*\*HARD GATE\*\*" */SKILL.md`

## Success Criteria

- [ ] All 35 skills have HARD GATE callouts
- [ ] HARD GATEs are contextually relevant to each skill's purpose
- [ ] Artifacts (.cursor/rules, .gemini/) regenerated
- [ ] stocktake-skills audit returns 0 missing HARD GATEs
- [ ] No SKILL.md files exceed 300 lines
- [ ] All changes committed with conventional message: `refactor(skills): add HARD GATE enforcement to 35 skills`

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| HARD GATEs are generic or irrelevant | Write phase-specific reference first (Step 1); validate against actual skill flow |
| Artifacts not regenerated | Automate with sync-skills.sh after each batch |
| Inconsistent formatting | Use existing examples (plan-work, develop-tdd) as templates |

## Out of Scope

- Updating "Use when..." descriptions (separate compliance task, 21 skills)
- Refactoring skill structure or renaming
- Adding new skills during this effort
- Modifying CONVENTIONS.md or SKILL-INDEX.md (beyond artifact regeneration)

## Estimated Effort

- Step 1 (reference): 30 min
- Steps 2-9 (8 batches): 3-4 hours (20 min per batch × 8 + review)
- Step 10 (artifacts): 5 min
- Step 11 (verification): 5 min

**Total: ~4 hours**
