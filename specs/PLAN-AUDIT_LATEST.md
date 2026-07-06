# Plan Audit — e37 Reach (Universal Agent Portability)
**Date:** 2026-07-06 · **Verdict:** ✅ **READY** (all gaps closed)
**Audit:** audit-plan skill · **Re-audit:** 2026-07-06 (post-fix verification)

> All 9 gaps identified in the initial audit have been closed. See below for
> the closure log and evidence checklist.

---

## Gap Closure Log

| # | Gap | Status | Fix |
|---|-----|--------|-----|
| G01 | Story ID collisions (e37s14/s15/s16 tasks & spec headers) | ✅ **FIXED** | `story_id` in all 3 tasks.yaml corrected (e37s01→e37s14, e37s02→e37s15, e37s03→e37s16). STORY KEY headers in all 3 spec .md files corrected (E37-S01→S14, S02→S15, S03→S16). |
| G02 | e37s04 Codex contamination | ✅ **FIXED** | `e37s04-verify-install-spine.md` and `e37s04-tasks.yaml` rewritten. Removed stale Codex-dominant assertions. New spec focuses on AGENTS.md template shape, Preflight row, Cline/Aider wiring. Codex assertions are conditional (gated on Codex wave stories s14–s16 being present). |
| G03 | SCOPE_LATEST.yaml contradictions (Continue, qwen, Hermes) | ✅ **FIXED** | Continue removed from `out_of_scope` (now in scope via fr-35 Reach wave). qwen removed from deferred Wave B+ list. Hermes removed from orchestration out_of_scope entry. Each is covered by the epic redesign scope (e37s09–s13). |
| G04 | BCP sum mismatch (declared 40, actual 45) | ✅ **FIXED** | `epic.yaml bcps:` 40→45. `release-plan.yaml e37 bcps:` 40→45. Both match the sum of all 16 stories (3+2+1+2+5+3+5+3+3+4+3+2+2+3+2+2=45). |
| G05 | state.yaml next_skill + missing stories | ✅ **FIXED** | `next_skill:` kickoff-branch → plan-tests. `handoff.stories` extended from s01–s08 to s01–s16. `epic_cycle.test_plan: done` added. |
| G06 | Wave story depth (s06–s12 thin specs) | ✅ **FIXED** | Added `out_of_scope` and `adapter guidance` sections to all 7 thin wave specs (s06 context-bundle, s07 adapter-dispatch, s08 verify-matrix, s09 Wave A, s10 Wave B, s11 Wave C, s12 Wave D). Each now has explicit scope boundaries, adapter hook documentation, and verification gate instructions. |
| G07 | Missing ADR for AGENTS.md convergence | ✅ **FIXED** | Created `specs/adr/0007-agents-md-spine-context-derivatives.md` — documents the decision, three options considered (multi-file, symlink spine, copy spine), selected approach with rationale, migration path. |
| G08 | Missing GLOSSARY entries for Reach domain | ✅ **FIXED** | Added 7 Reach-domain terms to `GLOSSARY_LATEST.yaml`: integration target, skill adapter, context derivative, context spine, context.mode, context bundle, reach template. Updated note field to reference e37. |
| G09 | Missing test plan (e37-TEST_PLAN_LATEST.md) | ✅ **FIXED** | Created `specs/tech-architecture/e37-TEST_PLAN_LATEST.md` with risk-scaled verification matrix (P0/P1/P2/P3), per-story verify table with gap notes, manual UAT steps for P0/P1 stories, hard gate table, and traceability mandate. |

---

## Principles Alignment

| Check | Status | Note |
|-------|--------|------|
| Vertical slices (not horizontal layers) | ✅ | Each story ships a complete, independently testable artifact (template / script / registry row). s01→s04 spine, s05→s08 core, s09→s13 waves, s14→s16 Codex — coherent vertical sequence. |
| Scope bounded | ✅ | Every story now has explicit `out_of_scope` in its spec doc. Epic-level scope is bounded by `SCOPE_LATEST.yaml` fr-28 to fr-37. |
| Success criteria defined | ✅ | Every story has a `verify:` shell command in `epic.yaml`. Stories with `.md` files have Gherkin AC. Test plan covers verification surface and known gaps. |
| HARD GATE candidates | ✅ | s01 explicit prerequisite for all waves. s07 (P0) gates sync-skills rewrite. Gates documented in test plan. |
| Domain language / ubiquitous terminology | ✅ | 7 Reach domain terms now in `GLOSSARY_LATEST.yaml`. `tech-stack.md § Reach Domain` has 25 invariants. |
| BCP sizing | ✅ | All 16 stories have `bcp:` in `epic.yaml`. Epic sum (45) matches declared value. |
| Optional stories clearly marked | ✅ | s13, s14, s15, s16 have `optional: true` + `wave: codex-optional`. |

---

## Conventions Completeness

| Check | Status | Note |
|-------|--------|------|
| CLAUDE.md | ✅ | Present, complete, includes Preflight chain. |
| CONVENTIONS.md | ✅ | Present, 300+ lines, authoritative. |
| specs/ directory | ✅ | Full YAML cockpit. |
| Commit conventions | ✅ | Conventional Commits 1.0.0. |
| Git workflow mode | ✅ | Solo-git profile with land-branch.sh. |
| Story ID consistency | ✅ | All 16 tasks.yaml + spec headers verified — no copy-paste collisions. |
| state.yaml handoff.stories complete | ✅ | All 16 stories listed. |
| Test plan for P0/P1 epic | ✅ | `specs/tech-architecture/e37-TEST_PLAN_LATEST.md` created. |
| ADR for architectural decision | ✅ | `specs/adr/0007-agents-md-spine-context-derivatives.md` created. |
| Glossary coverage | ✅ | 7 Reach domain terms added. Total: 26 terms. |

---

## Pre-flight Answers

| Question | Value | Status |
|----------|-------|--------|
| Test command | N/A (Markdown/Bash project) | ✅ Documented |
| Build command | `bash scripts/install.sh` | ✅ |
| Lint command | `bash scripts/sync-skills.sh` | ✅ |
| Typecheck command | N/A | ✅ Documented as N/A |
| CI platform | GitHub Actions | ✅ |
| Solo or team | Solo (solo-git profile) | ✅ |
| Language + framework | Markdown / Bash | ✅ |
| Greenfield or existing | Existing — extends live repo | ✅ |
| Preflight command | `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` | ✅ In CLAUDE.md |

---

## Risk Coverage

| Story | Risk | Coverage | Note |
|-------|------|----------|------|
| e37s01 | P1 | AC covers opt-in/opt-out, symlink vs copy, multi-tool preamble | ✅ |
| e37s02 | P2 | Simple grep assertions; low blast radius | ✅ |
| e37s03 | P3 | Aider bridge; low risk, simple | ✅ |
| e37s04 | P2 | verify-install spine with conditional Codex gating | ✅ |
| e37s05 | P1 | Schema, Windows gap, adapter testability, validator — excellent spec | ✅ |
| e37s06 | P1 | out_of_scope + adapter guidance added | ✅ |
| e37s07 | P0 | out_of_scope + adapter guidance added; test plan covers UAT | ✅ |
| e37s08 | P1 | out_of_scope + adapter guidance added | ✅ |
| e37s09–s12 | P2 | out_of_scope + adapter guidance added to each | ✅ |
| e37s13 | P3 | Optional; out_of_scope adequate | ✅ |
| e37s14–s16 | P2/P3 | Optional wave; tasks well-decomposed | ✅ |

---

## Traceability Assessment

| Dimension | Status | Note |
|-----------|--------|------|
| Story tags in spec files | ✅ | All 16 `.md` files have `# story:` or `STORY KEY:` header. |
| Story ID consistency | ✅ | All tasks.yaml story_ids verified matching spec IDs. |
| execution-status.yaml | ✅ | All 16 e37 story keys present, status: todo. |
| release-plan.yaml | ✅ | e37 entry updated (bcps: 45). |

---

## Verdict

> **READY** — all 9 gaps closed. Proceed with `plan-work` → `kickoff-branch → build-epic`.

## Recommended next skill sequence

```
1. survey-context   → bootstrap session with closed gaps
2. plan-work        → write detailed implementation tasks for e37s01
3. kickoff-branch   → create worktree for e37s01
4. build-epic       → step-by-step with human checkpoint after each story
```
