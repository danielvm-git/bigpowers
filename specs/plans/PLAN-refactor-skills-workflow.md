# Plan: Refactor bigpowers skills to v2 workflow

**Created:** 2026-06-10  
**Status:** ready  
**Target version:** 2.0.0  
**Scope baseline:** 24 BCPs across 4 epics  
**Entry skill:** `orchestrate-project` → `build-epic` × each story below

---

## Context

The factory simulation (2026-06-10 session) revealed four categories of debt in the current 61-skill corpus:

1. **Lifecycle fragmentation** — 3 conflicting phase maps (using-bigpowers / orchestrate-project / survey-context) cause the recurring "what comes next?" friction.
2. **Silent handoffs** — only 3/61 skills write `handoff.next_skill` to state.yaml; the other 58 go dark after completion.
3. **Missing plumbing** — no BCP accounting per task, no timestamp stamping per story, no cycle-time ledger.
4. **Skill bloat** — 18 skills violate the Section-8 Definition of Ready (sub-steps promoted to first-class, near-duplicates, etc.).

This plan refactors bigpowers in four sequential epics to match the v2 workflow exactly as simulated.

---

## Success criteria

- `survey-context` always exits with `Gate: [status] → next: [skill]` in its output.
- `plan-work` labels every task `[BCP N]` and writes a `bcps` count to the epic shard.
- `build-epic` writes `story_start` on step 1 and `story_end` + cycle-time metrics on step 8.
- A single canonical lifecycle map (orchestrate-project 6-phase) is referenced from all entry-point docs.
- `SKILL-INDEX.md` lists exactly 43 user-facing skills after consolidation.
- `npm run sync` exits 0 with no warnings.
- `npm run compliance` ≥ 94% on all modified skills.

---

## Release plan

| epic | title | BCPs | target |
|------|-------|------|--------|
| e01 | Bug fixes + lifecycle unification | 5 | v1.4.0 |
| e02 | Workflow plumbing (next_skill + timestamps + BCPs) | 7 | v1.5.0 |
| e03 | Skill consolidation 61 → 43 | 8 | v1.6.0 |
| e04 | Docs, index, sync validation | 4 | v2.0.0 |

---

## Epic e01 — Bug fixes + lifecycle unification (5 BCPs)

### e01s01 · Fix orchestrate-project/REFERENCE.md Phase 2 bug (1 BCP)

**Problem:** Phase 2 "Elaborate" lists `challenge-design` — a skill that does not exist.  
**Fix:** Replace with the real skills: `grill-me`, `model-domain`, `define-language`, `deepen-architecture`, `design-interface`.

Tasks:
- [BCP 1] Edit `orchestrate-project/REFERENCE.md` Phase 2 skill list
  - verify: `grep -c 'challenge-design' orchestrate-project/REFERENCE.md` returns 0

### e01s02 · Unify 3 lifecycle maps to 1 canonical (2 BCPs)

**Problem:** `docs/using-bigpowers.md` (15 BMAD phases), `survey-context/SKILL.md` (10 phases), `orchestrate-project/SKILL.md` (6 phases) all describe "the lifecycle" differently.  
**Fix:** orchestrate-project's 6-phase map is the canonical one. All others become references to it.

Tasks:
- [BCP 2] Edit `docs/using-bigpowers.md`: collapse its 15-phase BMAD table to a pointer → "See orchestrate-project for the canonical 6-phase lifecycle."
  - verify: `grep -c 'orchestrate-project' docs/using-bigpowers.md` ≥ 1
- [BCP 3] Edit `survey-context/SKILL.md`: replace its 10-phase table with the 6-phase table from orchestrate-project. Keep the "next_skill recommendation" logic intact.
  - verify: `grep -c 'Phase.*Discover\|Phase.*Elaborate\|Phase.*Plan\|Phase.*Build\|Phase.*Verify\|Phase.*Release' survey-context/SKILL.md` = 6

### e01s03 · Fix build-epic / orchestrate-project scope confusion (2 BCPs)

**Problem:** Users conflate the two conductors. orchestrate-project Phase 4 (Build) does not mention build-epic.  
**Fix:** Add one explicit line to orchestrate-project Phase 4 and add a disambiguation note to build-epic.

Tasks:
- [BCP 4] Edit `orchestrate-project/SKILL.md` Phase 4 body: add "Runs `build-epic` once per story in WSJF order."
  - verify: `grep -c 'build-epic' orchestrate-project/SKILL.md` ≥ 1
- [BCP 5] Edit `build-epic/SKILL.md` header: add "Scope: one story. Called by orchestrate-project Phase 4. Not a replacement for orchestrate-project."
  - verify: `grep -c 'orchestrate-project' build-epic/SKILL.md` ≥ 1

---

## Epic e02 — Workflow plumbing (7 BCPs)

### e02s01 · Add mandatory next_skill footer to 8 critical-path skills (3 BCPs)

**Problem:** Skills go silent after completion. The agent must ask "what's next?" because `handoff.next_skill` is only written by 3/61 skills.

Target skills and their required footer format:
```
Gate: [READY|BLOCKED] → next: <skill-name>
Writes: state.yaml handoff.next_skill = <skill-name>
```

Tasks:
- [BCP 6] Add footer to `survey-context/SKILL.md` (next: plan-work)
  - verify: `grep -c 'handoff.next_skill' survey-context/SKILL.md` ≥ 1
- [BCP 7] Add footer to `plan-work/SKILL.md` (next: kickoff-branch)
  - verify: `grep -c 'handoff.next_skill' plan-work/SKILL.md` ≥ 1
- [BCP 8] Add footer to `kickoff-branch/SKILL.md` (next: develop-tdd)
  - verify: `grep -c 'handoff.next_skill' kickoff-branch/SKILL.md` ≥ 1
- Add footer to `develop-tdd/SKILL.md` (next: verify-work)
- Add footer to `verify-work/SKILL.md` (next: audit-code)
- Add footer to `audit-code/SKILL.md` (next: commit-message)
- Add footer to `commit-message/SKILL.md` (next: release-branch)
- Add footer to `release-branch/SKILL.md` (next: survey-context OR release)
  - verify (all): `for s in develop-tdd verify-work audit-code commit-message release-branch; do grep -c 'handoff.next_skill' $s/SKILL.md; done` — all return ≥ 1

### e02s02 · Add BCP accounting to plan-work (2 BCPs)

**Problem:** Tasks in epic shards have no size unit. Scope is invisible until delivery.

Tasks:
- [BCP 9] Edit `plan-work/SKILL.md`: mandate that each task line is prefixed `[BCP N]` and that the skill writes a `bcps: N` total to the epic shard YAML.
  - verify: `grep -c '\[BCP' specs/epics/e01-security.yaml` ≥ 1 (after running plan-work on a test story)
- [BCP 10] Edit `build-epic/SKILL.md` Step 2 description: reference the BCP count and carry it into state.yaml as `epic_cycle.story_bcps`.
  - verify: `grep -c 'story_bcps' build-epic/SKILL.md` ≥ 1

### e02s03 · Add timestamp stamping and cycle-time ledger (2 BCPs)

**Problem:** No per-story start/end timestamps exist. Cycle time and BCP/hr are unmeasurable.

Tasks:
- [BCP 11] Edit `survey-context/SKILL.md` Step 7 (output block): add instruction to write `metrics.story_start: <ISO timestamp>` to state.yaml.
  - verify: `grep -c 'story_start' survey-context/SKILL.md` ≥ 1
- [BCP 12] Edit `release-branch/SKILL.md` post-land block: add instruction to write `metrics.story_end`, compute `cycle_minutes`, compute `bcp_per_hour`, and append a row to `specs/metrics/cycle-times.yaml`.
  - verify: `grep -c 'story_end\|cycle_minutes\|bcp_per_hour' release-branch/SKILL.md` ≥ 3
- Create `specs/metrics/README.md` documenting the `cycle-times.yaml` schema:
  ```yaml
  # cycle-times.yaml schema
  stories:
    - id: e01s01
      bcps: 3
      start: "2026-06-10T09:45:00"
      end: "2026-06-10T11:15:00"
      cycle_minutes: 90
      bcp_per_hour: 2.0
  ```
  - verify: `test -f specs/metrics/README.md`

---

## Epic e03 — Skill consolidation 61 → 43 (8 BCPs)

**Governing rule:** PRINCIPLES.md Section 8 — a skill is first-class only if it is invocable as a standalone entry point by the agent without a parent skill calling it first.

### e03s01 · Demote 8 sub-step skills (3 BCPs)

These skills are internal steps of their parent and should not appear in SKILL-INDEX.md as standalone entries:

| skill to demote | absorbed into |
|-----------------|---------------|
| define-success | plan-work |
| zoom-out | plan-work |
| slopcheck | plan-work |
| red-phase | develop-tdd |
| green-phase | develop-tdd |
| refactor-phase | develop-tdd |
| cold-start-smoke | verify-work |
| gaps-loop | verify-work |

Tasks:
- [BCP 13] Move content of `define-success`, `zoom-out`, `slopcheck` into `plan-work/SKILL.md` as named sub-sections. Archive source directories with `# ARCHIVED: absorbed into plan-work` header.
  - verify: `grep -c 'define-success\|zoom-out\|slopcheck' plan-work/SKILL.md` ≥ 3
- [BCP 14] Move content of `red-phase`, `green-phase`, `refactor-phase` into `develop-tdd/SKILL.md`.
  - verify: `grep -c 'red-phase\|green-phase\|refactor-phase' develop-tdd/SKILL.md` ≥ 3
- [BCP 15] Move content of `cold-start-smoke`, `gaps-loop` into `verify-work/SKILL.md`.
  - verify: `grep -c 'cold-start-smoke\|gaps-loop' verify-work/SKILL.md` ≥ 2

### e03s02 · Merge 5 variant skills into parents (3 BCPs)

| variant | merge target | reason |
|---------|-------------|--------|
| plan-work-fast | plan-work | mode flag, not a new skill |
| commit-message-fix | commit-message | fix: type variant |
| release-branch-hotfix | release-branch | hotfix mode flag |
| audit-code-quick | audit-code | threshold flag only |
| verify-work-smoke | verify-work | already a sub-step |

Tasks:
- [BCP 16] Merge `plan-work-fast` → `plan-work/SKILL.md` as `--fast` mode flag. Update cross-references.
  - verify: `grep -c '\-\-fast' plan-work/SKILL.md` ≥ 1
- [BCP 17] Merge `commit-message-fix` and `release-branch-hotfix` → parent SKILL.md files as mode sections.
  - verify: `grep -c 'hotfix\|fix-type' release-branch/SKILL.md commit-message/SKILL.md` ≥ 2
- [BCP 18] Merge `audit-code-quick` and `verify-work-smoke` → parent SKILL.md files.
  - verify: `grep -c '\-\-quick\|\-\-smoke' audit-code/SKILL.md verify-work/SKILL.md` ≥ 2

### e03s03 · Absorb 5 near-duplicate utility skills (2 BCPs)

| near-duplicate | absorbed into |
|----------------|--------------|
| show-state | session-state |
| reset-state | session-state |
| compact-state | session-state |
| list-epics | survey-context |
| check-gates | survey-context |

Tasks:
- [BCP 19] Merge `show-state`, `reset-state`, `compact-state` → `session-state/SKILL.md` as named operations.
  - verify: `grep -c 'show-state\|reset-state\|compact-state' session-state/SKILL.md` ≥ 3
- [BCP 20] Merge `list-epics`, `check-gates` → `survey-context/SKILL.md` as utility outputs.
  - verify: `grep -c 'list-epics\|check-gates' survey-context/SKILL.md` ≥ 2

---

## Epic e04 — Docs, index, sync, validation (4 BCPs)

### e04s01 · Update SKILL-INDEX.md (2 BCPs)

Tasks:
- [BCP 21] Rewrite `SKILL-INDEX.md`: remove all archived/demoted skills, update skill count from 61 to 43, add BCP column to each entry ("standalone invocable: yes/no").
  - verify: `grep -c '^\| ' SKILL-INDEX.md` = 43 (one row per skill)
- [BCP 22] Update `docs/using-bigpowers.md` quick-start to reference the seed-conventions → orchestrate-project entry point explicitly.
  - verify: `grep -c 'seed-conventions' docs/using-bigpowers.md` ≥ 1

### e04s02 · Run sync + full compliance validation (2 BCPs)

Tasks:
- [BCP 23] Run `bash scripts/sync-skills.sh` — must exit 0 with 0 warnings.
  - verify: `bash scripts/sync-skills.sh 2>&1 | grep -c 'warning\|error'` returns 0
- [BCP 24] Run `npm run compliance` — must be ≥ 94% across all modified SKILL.md files.
  - verify: `npm run compliance | tail -5` shows score ≥ 94%

---

## Execution order (WSJF priority)

1. e01s01 — fix REFERENCE.md bug (highest CoD: blocks correctness of all Phase 2 docs)
2. e02s01 — next_skill plumbing (highest user-value: eliminates "what's next?" friction)
3. e02s03 — timestamps + cycle ledger (enables metrics from day 1)
4. e01s02 — lifecycle unification (medium CoD: documentation confusion)
5. e01s03 — build-epic / orchestrate-project disambiguation
6. e02s02 — BCP accounting in plan-work
7. e03s01 → e03s02 → e03s03 — consolidation in order (each smaller)
8. e04s01 → e04s02 — index + sync last (depends on all previous)

---

## Never

- Never delete a SKILL.md file — archive it with a `# ARCHIVED` header.
- Never edit `.cursor/rules/` or `.gemini/extensions/` directly — run sync-skills.sh.
- Never mark a story done without a passing `verify:` command for each BCP.
- Never push to main without `npm run compliance` ≥ 94%.
