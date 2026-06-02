# Release Plan: bigpowers v3.0.0 Consolidation

**Status:** In progress · **Target:** v3.0.0 (semantic-release at merge)  
**Scope:** [specs/PLAN-NEXT-RELEASE.md](PLAN-NEXT-RELEASE.md)

Current audit score: **~94%** — must remain ≥ 94% after merge.

---

## Release at a Glance

| Dimension | Before | After |
|-----------|--------|-------|
| Active skills | 44 | **58** |
| Planned skills | 6 | **0** |
| Lifecycle | Build → Review | Build → **Verify** → Review |
| Stack profiles | ad hoc | `profiles/` + seed-conventions |
| Self-evolution | none | `evolve-skill` + benchmark |

---

## Workstreams (WSJF order)

### WS1 — Security · WSJF 4.5

- [x] slopcheck tags in `plan-work` ([OK]/[SUS]/[SLOP])
- [x] Supply-chain + OWASP in `audit-code`
- [x] Secret patterns documented in `guard-git`
- [x] `docs/references/security-threats.md` reconciled

→ verify: `grep -r slopcheck plan-work/SKILL.md audit-code/SKILL.md | wc -l | awk '{if($1>=2) print "OK"}'`

### WS2 — Verification & Evals · WSJF 4.3

- [x] `verify-work`, `run-evals` skills
- [x] Verification Script template in `plan-work`
- [x] UAT checkpoint in `execute-plan`
- [x] RED/GREEN/REFACTOR commits in `develop-tdd`

→ verify: `test -d verify-work && test -d run-evals && echo OK`

### WS3 — Discovery & Planning · WSJF 4.0

- [x] `research-first`, `scope-work`, `slice-tasks`, `grill-with-docs`
- [x] `using-bigpowers` lifecycle updated

→ verify: `ls scope-work/SKILL.md slice-tasks/SKILL.md grill-with-docs/SKILL.md research-first/SKILL.md`

### WS4 — Ergonomics · WSJF 3.8

- [x] Handoff + compaction in `session-state`
- [x] `terse-mode` caveman rules (existing)
- [x] `organize-workspace` gitignore section (existing)

→ verify: `grep -c Handoff session-state/SKILL.md | awk '{if($1>0) print "OK"}'`

### WS5 — Context Isolation + Routing · WSJF 3.3

- [x] `model:` on all SKILL.md
- [x] `execute-plan` isolation + STATE.md channel
- [x] `orchestrate-project` reads model + spawn list

→ verify: `grep -rl '^model:' */SKILL.md 2>/dev/null | wc -l | awk '{if($1==58) print "OK"; else print $1}'`

### WS6 — Taxonomy & Provenance · WSJF 3.0

- [x] `type:` / `context:` in plan-work template
- [x] ADR/SHA refs on steps
- [x] `audit-code` metadata checks

→ verify: `grep -c 'type:' plan-work/SKILL.md | awk '{if($1>0) print "OK"}'`

### WS7 — Architectural Complexity · WSJF 2.8

- [x] Demeter in CONVENTIONS.md + audit-code
- [x] Module Depth score in deepen-architecture
- [x] Concurrency audit in model-domain

→ verify: `grep -c Demeter CONVENTIONS.md audit-code/SKILL.md | awk -F: '{s+=$2} END {if(s>=2) print "OK"}'`

### WS8 — Wave Execution · WSJF 2.5

- [x] Waves + `depends-on:` in execute-plan

→ verify: `grep -c 'depends-on' execute-plan/SKILL.md | awk '{if($1>0) print "OK"}'`

### WS9 — Self-Evolution · WSJF 2.0

- [x] stocktake-skills, evolve-skill, search-skills, compose-workflow, simulate-agents
- [x] `specs/METHODOLOGY.md`
- [x] craft-skill README generator
- [x] Iterative retrieval in dispatch-agents / delegate-task
- [x] evolve-skill benchmark path documented; run `bash scripts/score_run.sh` in bigpowers-benchmark repo at release merge

→ verify: `ls evolve-skill/SKILL.md specs/METHODOLOGY.md`

### WS10 — Stack Profiles · WSJF 1.8

- [x] profiles/swift.md, typescript-vue.md, node-service.md
- [x] seed-conventions profile picker

→ verify: `ls profiles/*.md | wc -l | awk '{if($1==3) print "OK"}'`

---

## Merge Gates

| Gate | Command | Target |
|------|---------|--------|
| Skill count | `find . -maxdepth 2 -name SKILL.md \| grep -v .git\|.cursor\|.gemini \| wc -l` | 59 |
| Sync | `bash scripts/sync-skills.sh` | 59 skills synced |
| Compliance | `npm run compliance` | all suites ≥ 94% |
| Wiki sync | `maintain-wiki` sync mode | index + entities + synthesis present; 0 lint errors |
| Benchmark | bigpowers-benchmark repo | ≥ baseline |

---

## Audit Score Tracking

| Version | Score |
|---------|-------|
| v2.0.0 | ~94% |
| **v3.0.0 target** | ≥ 94% (no regression) |
