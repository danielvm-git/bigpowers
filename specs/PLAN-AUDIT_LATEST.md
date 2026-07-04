# Plan Audit — Full Missing Roadmap (14 Proposed/Upcoming Epics)

**Date:** 2026-07-03 · **Verdict:** ⚠️ NOT READY as top-to-bottom WSJF order — dependency chain breaks it; READY once resequenced

**Scope audited:** All 14 not-yet-done epics in `specs/release-plan.yaml`: e47, e32, e41, e44, e39, e46, e35, e45, e33, e43, e37, e28, e42, e36. Cross-referenced each `epic.yaml`'s `depends_on`/`soft_depends_on` against `execution-status.yaml`, `state.yaml`, and `specs/product/SCOPE_LATEST.yaml`.

---

## Critical Finding — the WSJF list is not dependency-safe

`release-plan.yaml` lists these 14 epics sorted by WSJF alone. Reading it top-down and building in that order will stall, because three epics have **hard dependencies on lower-WSJF, unbuilt epics**:

| Epic | WSJF | Hard depends_on | Dependency status |
|---|---|---|---|
| e41 | 3.75 | `e28` (2.0), `e40` ✅ | **e28 is `backlog`, 0/4 stories** — e41 cannot start |
| e44 | 3.75 | `e39` (3.6), `e40` ✅ | **e39 itself is blocked** (see below) — e44 cannot start |
| e39 | 3.60 | `e33` (2.8) | **e33 is `planned`, not built** — e39 cannot start |
| e37 | 2.10 | `e40` ✅, `e33` (2.8) | same blocker as e39 |
| e46 | 3.40 | `e42` (1.8, in-flight) | e42 is `ready`/1 of 4 stories done — e46 must wait for e42 to finish |

This means **e33** (WSJF 2.8, the 9th-ranked epic) is a single point of gate for two higher-WSJF epics (e39 at 3.6, e37 at 2.1), and transitively for a third (e44 at 3.75, since e44 depends on e39). A reader following the raw WSJF list would hit e41 (rank 3) and e44 (rank 4) and find both blocked before reaching their prerequisites.

**Dependency-respecting build order** (WSJF-sorted within each unlocked tier):

1. **Finish e42** (in-flight, `ready`, 1/4 done) — unlocks e46 later, no reason to leave it half-built
2. **e47** (4.3) — no deps
3. **e32** (4.0) — no deps
4. **e33** (2.8) — low own-WSJF, but promoted ahead of its rank because it single-handedly unlocks e39 (3.6) and e37 (2.1)
5. **e39** (3.6) — unlocked by e33
6. **e44** (3.75) — unlocked by e39 (highest WSJF in the whole roadmap once buildable — should not sit at rank 4 waiting)
7. **e28** (2.0) — unlocks e41
8. **e41** (3.75) — unlocked by e28
9. **e46** (3.4) — unlocked once e42 fully done
10. **e35** (3.0), **e45** (3.0), **e43** (2.5), **e37** (2.1), **e36** (1.4) — remaining, WSJF order, no blockers

**Fix:** Either add a `build_order:` field to `release-plan.yaml` reflecting the above, or add explicit `blocked_until:` annotations on e39/e41/e44/e46/e37 so `build-epic` doesn't get picked up out of dependency order by WSJF rank alone.

---

## Principles Alignment (sampled across all 14)

| Check | Status | Note |
|---|---|---|
| Vertical slices | ✅ | All 14 use `mode: capsule` with per-story `verify:` |
| Scope bounded | ✅ | `depends_on`/`soft_depends_on` explicit where applicable; e47 has explicit out-of-scope list |
| Success criteria | ✅ | Verify commands present throughout sampled epics |
| HARD GATE candidates | ⚠️ | e47s01 (removes `install_opencode()`) has no HARD GATE annotation — carried over from the e47-only audit, still open |
| Domain language | ✅ | Consistent (WSJF/BCP, capsule, skill-catalog vs instruction-only) |

## Conventions Completeness

| Check | Status | Note |
|---|---|---|
| CLAUDE.md / CONVENTIONS.md | ✅ | Present, current |
| specs/ layout / capsule_dir | ✅ | All 14 `capsule_dir` values match disk (`ls specs/epics/` confirms) — previous audit's GAP-C1 (7 mismatches) is still fixed, no regressions |
| SCOPE mappings | ✅ | fr-13 → e35, fr-16 → superseded by fr-20/e40 — previous audit's GAP-H1 fix holds |
| e45 duplicate `source:` block | ✅ | Confirmed single `source:` block now (previous audit's GAP-M1 fix holds) |
| Commit conventions / git workflow | ✅ | Conventional Commits, semantic-release, solo-git |

## Pre-flight Answers

Unchanged from prior audits — inherited project-wide: Test `npm run compliance && bash scripts/run-golden-suite.sh`; Build `bash scripts/install.sh`; Lint `bash scripts/sync-skills.sh`; Typecheck N/A (Markdown/Bash, +TS scoped to e32 only); CI GitHub Actions; Solo; Existing 30+-epic codebase.

---

## Open Gaps

- [ ] **SEQ-1 (real blocker, unchanged):** `state.yaml active_flow` is `fix_bug` on `BUG-2026-07-03-trace-engine-vacuous-gate`, step 1/N, not yet landed. No `build-epic` should start on any of these 14 until it does.
- [ ] **DEP-1 (this audit's main finding):** Raw WSJF order in `release-plan.yaml` is not buildable top-down — see Critical Finding above. Needs `build_order:` or `blocked_until:` annotations before `build-epic` is run against this list mechanically.
- [ ] **STATUS-1 (minor):** `e42.status` is `"active"` in both `release-plan.yaml` and its own `epic.yaml`, but `"ready"` in `execution-status.yaml`. No documented status vocabulary maps these two fields to each other (checked `CONVENTIONS.md` and `specs/templates/` — neither defines the enum). Not necessarily wrong, but worth a one-line convention note so future audits don't have to re-derive the mapping.
- [ ] **GATE-1 (carried over, minor):** e47s01's `install_opencode()` removal still has no HARD GATE annotation. Verified low-risk (no paired `uninstall_opencode()`, writes a plain file not a symlink) — cheap to add for the record.

## Verdict

**NOT READY as a mechanical top-to-bottom WSJF queue** — three epics (e41, e44, e39, e37) have hard dependencies on lower-ranked, unbuilt epics, chiefly gated through **e33**. **READY once resequenced**: the dependency-respecting order above is internally consistent and every individual epic capsule is well-formed (bounded scope, verify commands, no stale capsule_dir/SCOPE references).

**Next skill:** `fix-bug` (resume `BUG-2026-07-03-trace-engine-vacuous-gate` first) → `survey-context` → `build-epic` in this order: **e42 (finish) → e47 → e32 → e33 → e39 → e44 → e28 → e41 → e46 → e35/e45/e43/e37/e36**.
