# Plan Audit — e39/e40/e41/e42 (post-Deepening backlog additions)

**Date:** 2026-07-03 · **Verdict:** READY — all 4 gaps closed same session (see Gap Closure below)

**Plan audited:** `specs/epics/e39-knowledge-graph/epic.yaml` (10 stories, 20 BCP), `specs/epics/e40-metrics-integrity/epic.yaml` (8 stories, 18 BCP), `specs/epics/e41-public-receipts/epic.yaml` (5 stories, 10 BCP), `specs/epics/e42-showcase-repo/epic.yaml` (4 stories, 10 BCP), cross-checked against `specs/release-plan.yaml` (release trains + WSJF), `specs/state.yaml`, `specs/product/SCOPE_LATEST.yaml`, `specs/CHANGE-REQUEST-e40-metrics-integrity.md`, and `specs/IMPACT-e38-okf-adoption.md`.

This is not a foreign/greenfield plan — bigpowers already has full CLAUDE.md/CONVENTIONS.md/specs/ scaffolding and 30+ shipped epics. The audit here is narrower: are these four *new* backlog epics internally consistent and registered correctly before build starts.

---

## Principles Alignment

| Check | Status | Note |
|---|---|---|
| Vertical slices | ✅ | All four epics use single-deliverable stories with a runnable `verify:` (e39/e40) or Given/When/Then `ac:` + task-level `verify:` (e41/e42) — not horizontal layers. |
| Scope bounded (per-epic) | ⚠️ | e41 and e42 declare `depends_on`/`soft_depends_on` explicitly. e39 and e40 don't, despite `release-plan.yaml`'s own rationale text saying e33 is "an explicit architectural prerequisite for e39's OKF Phase 2" — the dependency is documented in prose but not encoded in the epic capsule. |
| Scope bounded (project-level) | ❌ | `specs/product/SCOPE_LATEST.yaml` `in_scope` stops at `fr-17` (e36). e38, e39, e40, e41, e42 have no FR entries, so they inherit no `out_of_scope` boundary or `success_criteria` line from the scope doc — they exist only as epic capsules + release-plan rows. |
| Success criteria | ✅ | Every story has a mechanical `verify:`/`ac:` block; no rubric-only or "looks right" criteria found. |
| HARD GATE candidates identifiable | ✅ | e40's provenance gate (gate on pipeline-ran + commit_range resolves, never on value) and e41s04's honesty guardrail are both explicit and correctly scoped as gates-on-process, not gates-on-value. |
| Domain language | ⚠️ | OKF, BCP, WSJF are used constantly across all four epics. BCP has a canonical doc (`docs/references/bcp.md`); OKF's only definition lives in `specs/IMPACT-e38-okf-adoption.md` prose — `specs/product/GLOSSARY_LATEST.yaml` is still `terms: []`. Not blocking, but the term anchoring 40 of the 58 new BCP (e39+e40) has no glossary entry. |

## Conventions Completeness

| Check | Status | Note |
|---|---|---|
| CLAUDE.md / CONVENTIONS.md | ✅ | Both present, mature, already encode the YAML cockpit, BCP mandate, timestamp mandate, and skill-naming rules these epics must follow. |
| specs/ layout | ✅ | In place; `specs/templates/` (new, holds `story-metrics.okf.md`) fits the existing convention. |
| Commit conventions | ✅ | Documented (Conventional Commits + semantic-release table). |
| Git workflow mode | ✅ | `solo-git` confirmed active (`specs/WORKFLOW-solo-git.md` + `profiles/solo-git.md` both present) — `release-branch` should run in solo fallback mode for these epics. |

## Pre-flight Answers (already established at project level — no new gaps)

| Command | Value |
|---|---|
| test | N/A (documentation project) |
| build | `bash scripts/install.sh` |
| lint | `bash scripts/sync-skills.sh` |
| typecheck | N/A |
| CI platform | GitHub Actions |
| Solo or team | Solo (`solo-git` profile active) |
| Language + framework | Markdown / Bash |
| Greenfield or existing | Existing — 30+ epics shipped, this is incremental backlog |

## Open Gaps

1. **`scripts/validate-okf.sh` has two owners.** `e39s10` ("Create scripts/validate-okf.sh — OKF conformance CI gate") and `e40s06` ("validate-okf.sh + provenance gate") both use the identical verify command `test -f scripts/validate-okf.sh && bash scripts/validate-okf.sh --help` and both describe *creating* the same file — one checking generic OKF frontmatter conformance, the other checking metrics-bundle provenance. `release-plan.yaml`'s own release trains land e40 (v2.5x) before e39 (v2.7x/v3.0), so e40s06 will create the script first. `e41s04` already assumes this and says "Extend validate-okf.sh (e40s06)" — the same pattern should apply to e39s10. **Fix:** reword e39s10 to "Extend `scripts/validate-okf.sh` (e40s06) with OKF frontmatter/type/reserved-filename checks" so there's one script with two conformance layers, not two competing creations. Run `plan-work` (or a direct epic.yaml edit) on e39s10 before build.
2. **e38–e42 are missing from `specs/product/SCOPE_LATEST.yaml`.** Add `fr-18` through `fr-22` to `in_scope` (mirroring the `fr-11`..`fr-17` pattern for e30–e36) so each epic has a scope-doc anchor and can inherit `out_of_scope` boundaries. Run `scope-work`.
3. **e39 has no `depends_on:` field.** Add `depends_on: [e33]` to `specs/epics/e39-knowledge-graph/epic.yaml` to make the release-plan rationale ("e33 is an explicit architectural prerequisite for e39's OKF Phase 2") machine-checkable, consistent with how e41/e42 already declare dependencies.
4. **`specs/state.yaml` is stale relative to today's session.** `planning.epics_planned` lists epics only through e39; `handoff.next_skill` still points at `survey-context` with e31-completion framing. Since e40/e41/e42 and the release-train resequencing all landed this session, `state.yaml` should be refreshed before the next build cycle starts (mechanical — no new decision needed, `run scripts/bp-yaml-set.sh` or `survey-context` will do it).

None of these are design-feasibility problems like the e31 audit found — the stories themselves are well-formed (verify commands are mechanical, ACs are Given/When/Then, honesty/degradation rules are explicit in e41). This is spec-hygiene: register the new epics in the scope doc, resolve one duplicate script ownership, and sync state.

## Gap Closure (2026-07-03, same session)

| Gap | Fix applied | Verified |
|---|---|---|
| 1. validate-okf.sh dual ownership | e39s10 reworded to "Extend scripts/validate-okf.sh (created by e40s06)"; e39 gains `soft_depends_on: [e40]` | ✅ yaml parse + title assert |
| 2. e38–e42 missing from SCOPE | `fr-18`..`fr-22` added to `specs/product/SCOPE_LATEST.yaml` in_scope (fr-20 notes it supersedes fr-16/e35) | ✅ fr→epic mapping assert |
| 3. e39 dependency not encoded | `depends_on: [e33]` added to e39 epic.yaml with rationale comment | ✅ yaml assert |
| 4. state.yaml stale | `handoff.context` rewritten (release trains + next target e40); `planning.epics_planned` now lists e40/e41/e42, e35 marked SUPERSEDED | ✅ content asserts |
| (found during verify) e39 epic.yaml was invalid YAML | Three `verify:` plain scalars contained `: ` sequences (`'type: Skill'`, `"FAIL: "`) — pre-existing defect; converted to `>-` block scalars, commands unchanged | ✅ all 4 epic capsules + SCOPE + state parse clean |

`bash scripts/validate-specs-yaml.sh` → OK.

## Verdict

**READY** — all gaps closed and machine-verified. Note: `scripts/validate-specs-yaml.sh` did NOT catch the invalid YAML in e39's epic capsule (it apparently skips capsule files) — consider extending it to parse `specs/epics/*/epic.yaml`.

**Recommended next skill:** `survey-context` → `build-epic e40` (first epic of the v2.5x "Trust & Signal" train per release-plan.yaml).
