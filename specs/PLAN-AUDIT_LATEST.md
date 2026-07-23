# Plan Audit — bigpowers-to-bigspec migration (release-plan.yaml + e53-e59)

**Date:** 2026-07-22 · **Verdict:** READY (plan + e53/e54 build-ready) — WITH TRACKED, EXPECTED GAPS (e55-e59 scoped-not-sliced)

**Scope of this audit:** `specs/release-plan.yaml` in full, plus the 7 "to be done" epics —
`e53` (in_progress), `e54` (todo, plan-worked), `e55`-`e59` (scoped via elaborate-spec). The 4
`done` epics (`e51`, `e37`, `e45`, `e48`) are out of scope — already shipped, not part of "to be
done." This audit supersedes the prior `e48`-only snapshot below it in git history. Every finding
is a direct re-check against the repo, not a recall of prior session claims.

---

## Release-Plan Structural Integrity

| Check | Status | Evidence |
|---|---|---|
| `release-plan.yaml` parses as valid YAML | ✅ | `python3 -c "yaml.safe_load(...)"` — 11 epics loaded clean |
| Epics list is WSJF-sorted, highest first | ✅ | e53(8.0) → e51(7.0) → e37(7.0) → e54(6.7) → e55(6.0) → e58(5.3) → e45(5.0) → e57(5.0) → e56(3.8) → e59(3.7) → e48(2.5) — every step ≤ previous |
| Every `capsule_dir` resolves to a real directory | ✅ | All 11 confirmed via `os.path.isdir` |
| Dependency chain is a coherent DAG, no cycles, no dangling targets | ✅ | e53→(root); e54→e53; e55→e54; e56→e53,e54,e55; e57→e54; e58→e53; e59→e55,e57 — every target is a known epic id, no cycles |
| BCP arithmetic: epic `bcps` = sum(story `bcp`) for sliced epics | ✅ | e53: 9=9. e54: 6=6. (e55-e59: `bcps: 0`, correctly zero — no real stories sliced yet, `bcps_projected` is a labeled estimate, not counted) |

---

## Principles Alignment

### Repo-wide

| Check | Status | Note |
|---|---|---|
| Domain language / ubiquitous terminology | ✅ | WSJF and BCP appear in all 7 epic.yaml files; `tombstone` appears only in the 2 epics that actually rename/merge skills (e53, e56) — vocabulary is consistent and not force-fit where it doesn't belong |
| HARD GATE candidates identifiable | ✅ | Not as literal "HARD GATE" strings (0 matches), but substantively present and load-bearing: e58's gate-flip is explicitly deferred until calibration data exists (not a blind flip); e56 mandates the tombstone mechanism for every single rename with no exceptions; e53s03 explicitly scopes itself out of flipping `golden-suite-gates.sh:9`, leaving that decision to e58 |

### Per-epic

| Epic | Vertical slices | Scope bounded (in/out) | Success criteria (Gherkin) | Note |
|---|---|---|---|---|
| e53 | ✅ 4 independently-shippable stories | ✅ §18 present in all 4 specs | ✅ §17 present in all 4 specs | Fully sliced, repaired this session |
| e54 | ✅ 3 independently-shippable stories | ✅ §18 present in all 3 specs | ✅ §17 present in all 3 specs | Fully sliced + plan-worked (risk/allure/delta tags) |
| e55 | ⚠️ 3 `planned_stories`, not yet real `eNNsYY` stories | ✅ `out_of_scope` in planning-context.yaml | ⚠️ prose description + `backward_compat` per story; **no `ac:`/Gherkin field yet** | By design — elaborate-spec output, not plan-work output |
| e56 | ⚠️ 4 `planned_stories` (largest — 4th is flagged in its own context as needing further splitting) | ✅ `out_of_scope` present | ⚠️ same as e55 — no Gherkin yet | By design |
| e57 | ⚠️ 3 `planned_stories` | ✅ `out_of_scope` present, including an explicit deferred-scope call (`_LATEST` abolition) | ⚠️ same as e55 | By design |
| e58 | ⚠️ 3 `planned_stories`, sequenced (calibrate → wait → flip) | ✅ `out_of_scope` present | ⚠️ same as e55 | By design |
| e59 | ⚠️ 3 `planned_stories` | ✅ `out_of_scope` present | ⚠️ same as e55 | By design; intent user-confirmed 2026-07-22 |

The ⚠️ pattern on e55-e59 is identical across all five and **already documented as intentional**
in each epic's own `note:` / `planning-context.yaml` (`status: scoped`, not `todo`) — this audit
confirms the gap is real and tracked, not that it was newly discovered.

---

## Conventions Completeness

| Check | Status | Evidence |
|---|---|---|
| `CLAUDE.md` exists | ✅ | 18,765 bytes |
| `CONVENTIONS.md` exists | ✅ | 25,332 bytes |
| `specs/` directory layout in place | ✅ | Confirmed throughout this audit |
| Commit conventions documented | ✅ | `CONVENTIONS.md:16-18` — Conventional Commits 1.0.0 + SemVer 2.0.0, mandatory |
| Git workflow mode identified | ✅ | **solo-git** — `profiles/solo-git.md` and `specs/WORKFLOW-solo-git.md` both present and active; `CONVENTIONS.md:34` documents the solo-profile integrate path (`land-branch.sh`, PR optional) |

---

## Pre-flight Answers

| Command | Value | Source |
|---|---|---|
| Test | N/A (documentation project) | `CLAUDE.md` § Commands |
| Build | `bash scripts/install.sh` | `CLAUDE.md` § Commands |
| Lint | `bash scripts/sync-skills.sh` | `CLAUDE.md` § Commands |
| Typecheck | N/A (Markdown / Bash project) | `CLAUDE.md` § Commands |
| Validate specs YAML | `bash scripts/validate-specs-yaml.sh` | `CLAUDE.md` § Commands |
| Compliance | `npm run compliance` | `CLAUDE.md` § Commands |
| CI platform | GitHub Actions (`publish.yml`, `sync-skills.yml`) | `CLAUDE.md` § Commands |
| Solo or team | **Solo** (`solo-git` profile active) | Verified above |
| Primary language + framework | Markdown / Bash (documentation-based) | `CLAUDE.md` header |
| Greenfield or existing | **Existing** — mature repo, 4 completed epics in this release alone (`e37`,`e45`,`e48`,`e51`) | `release-plan.yaml` |

---

## Mechanical Gate Results (re-run live, this audit)

`bash scripts/lib/plan-consistency-check.sh specs/epics/<capsule>/` against every to-be-done epic:

| Epic | Result | Detail |
|---|---|---|
| e53 | ✅ PASS | CRITICAL=0 HIGH=0 MED=0 |
| e54 | ✅ PASS | CRITICAL=0 HIGH=0 MED=0 |
| e55 | ⛔ BLOCKED | CRITICAL=2 (no story spec `.md`, no `tasks.yaml`) |
| e56 | ⛔ BLOCKED | CRITICAL=2 (same) |
| e57 | ⛔ BLOCKED | CRITICAL=2 (same) |
| e58 | ⛔ BLOCKED | CRITICAL=2 (same) |
| e59 | ⛔ BLOCKED | CRITICAL=2 (same) |

**This is the gate working as designed, not a defect.** These five epics are deliberately
`status: scoped` (elaborate-spec output), not `status: todo`/sliced (plan-work output) — the gate
correctly refuses to consider them buildable. Confirmed by cross-checking: this is the exact same
mechanism this session hardened for bash-3.2 portability and used to catch — and fix — `e53`'s
real missing-spec-files defect earlier in this arc.

---

## Open Gaps

- [ ] e55-e59 need a `plan-work` pass each (in dependency order: e55 → e56/e57 → e58/e59) before
      they can build — **expected, already tracked in each epic's own status field, not new.**
- [ ] e56's 4th planned story (merge/rename toward the ~28-29 target) is flagged in its own
      `planning-context.yaml` as needing further splitting once plan-worked — largest single risk
      surface in the whole migration; worth extra scrutiny when that epic's turn comes.
- [ ] No formal Gherkin (`ac:`) on any e55-e59 planned story yet — will be produced by each epic's
      own `plan-work` pass, per the dependency order above.

None of these block `e53`/`e54` from building now — they only affect epics further down the
dependency chain, which structurally cannot start before `e53`/`e54` complete anyway.

---

## Verdict

**READY** to proceed with `kickoff-branch` on `e53`, then `e54` in sequence. The release plan
itself is structurally sound (valid YAML, correct WSJF order, coherent dependency DAG, exact BCP
arithmetic). `e53` and `e54` are fully sliced, plan-worked, and pass the mechanical consistency
gate clean.

`e55`-`e59` are **not** build-ready — but this is the plan's own, already-documented, correct
state (`status: scoped`), confirmed rather than newly discovered by this audit. They require a
`plan-work` pass each, which structurally cannot happen before their dependencies (`e53`, `e54`,
and each other in sequence) land — so this is not a blocker on today's next action.

## Next skill

`kickoff-branch` — per `state.yaml`'s own handoff (`next_skill: kickoff-branch`, `epic: e53`),
which this audit confirms is the correct next action.
