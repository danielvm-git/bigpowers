# Release Plan: v1.2.0 (map-codebase)

This plan implements the `map-codebase` skill, as identified in `specs/RELEASE_PLAN.md` and `specs/COMPARISON.md`. This release also hardens the synchronization infrastructure by automating version propagation.

## Objectives
- Introduce `map-codebase` skill for high-fidelity discovery.
- Automate version propagation in `sync-skills.sh` from `package.json`.
- Update project-level documentation to reflect new discovery capabilities.

## Phase 1: Infrastructure Hardening
1. Fix `scripts/sync-skills.sh` to extract version from `package.json` → verify: `bash scripts/sync-skills.sh && grep '"version": "1.0.0"' .gemini/extensions/bigpowers/gemini-extension.json` (should now match package.json)
2. Update `package.json` to `1.1.0` (reflecting the current Compliance release) → verify: `grep '"version": "1.1.0"' package.json`

## Phase 2: map-codebase Skill Implementation
1. Create `map-codebase/` directory → verify: `ls -d map-codebase`
2. Create `map-codebase/SKILL.md` with high-fidelity discovery process → verify: `grep "map-codebase" map-codebase/SKILL.md`
3. Process details for `map-codebase`:
   - High-fidelity survey: Stack, Architecture, Gray Areas (Error handling, API shapes).
   - Persistence: Write results to `specs/CONTEXT.md`.
   - Signal identification for planning.

## Phase 3: Integration & Sync
1. Update `README.md` "Skills Reference" table to include `map-codebase` in the Discover phase → verify: `grep "map-codebase" README.md`
2. Update `GEMINI.md` commands table → verify: `grep "map-codebase" GEMINI.md`
3. Run `bash scripts/sync-skills.sh` → verify: `ls .cursor/rules/map-codebase.mdc` and `ls .gemini/extensions/bigpowers/skills/map-codebase/SKILL.md`

## Phase 4: Finalization
1. Update `package.json` to `1.2.0` → verify: `grep '"version": "1.2.0"' package.json`
2. Update `specs/RELEASE_PLAN.md` status for v1.2.0 → verify: `grep "v1.2.0" specs/RELEASE_PLAN.md` (check if it can be marked as complete)
