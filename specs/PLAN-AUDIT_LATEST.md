# Plan Audit — Full Project (Done + Upcoming Epics)

**Date:** 2026-07-03 · **Verdict:** ⚠️ NOT READY — 3 CRITICAL, 4 HIGH gaps; closing now

**Scope audited:** Every epic in `specs/release-plan.yaml` — done (e01–e31, e34, e38, e40) and upcoming (e28, e32, e33, e35, e36, e37, e39, e41, e42, e43, e44, e45, e46). Cross-referenced `execution-status.yaml`, `state.yaml`, SCOPE, capsule dirs on disk, and epic dependencies.

---

## 🔴 Critical Gaps

### GAP-C1 — 7 epic ID ↔ capsule_dir mismatches in release-plan.yaml

The `capsule_dir` field does not match the actual directories on disk. The disk is correct; the YAML is stale.

| Epic ID | YAML capsule_dir | Actual disk dir |
|---------|------------------|-----------------|
| e33 | `epics/e28-docs-website` | `epics/e33-docs-website` |
| e35 | `epics/e37-historical-refs` | `epics/e35-historical-refs` |
| e28 | `epics/e33-sync-pipeline` | `epics/e28-sync-pipeline` |
| e42 | `epics/e43-golden-stories` | `epics/e42-golden-stories` |
| e32 | `epics/e35-mcp-context-server` | `epics/e32-mcp-context-server` |
| e43 | `epics/e32-showcase-repo` | `epics/e43-showcase-repo` |
| e37 | `epics/e42-bcp-plus-counting` | `epics/e37-bcp-plus-counting` |

**Impact:** Any automation reading `capsule_dir` will look in the wrong directory. The "DO NOT RENUMBER EPIC IDs" block on line 65 is the project's own warning — violated by these stale references.

**Fix:** Update the 7 `capsule_dir` values to match disk.

### GAP-C2 — state.yaml handoff pointed to wrong epic

`state.yaml` handoff said `build-epic on e43 (v2.7x train, WSJF 4.00)` — but e43 is Showcase Repo (WSJF 2.5). The intent was the leading epic. **Decision: e28 (Sync Pipeline Refactor) leads.** Rationale: e28 is the architectural dependency for e39's OKF rendering, e32's MCP server SKILL.md parsing, and e41's public receipts page. Landing it first unblocks 3 downstream epics. The handoff now reads e28.

### GAP-C3 — e41 blocked on v2.6x epic not started

e41 (Public Receipts) declares `depends_on: [e28, e40]`. e40 is done, but e28 is backlog in the v2.6x train. The v2.6x train must complete before v2.7x can ship anything with an e28 dependency. **Mitigated by leading with e28** — once e28 lands, e41 is unblocked.

---

## 🟠 High Severity

### GAP-H1 — SCOPE epic mappings stale (fr-13, fr-16)

`SCOPE_LATEST.yaml` maps:
- `fr-13` → e32 ("Historical reference docs") — but **e32 is now MCP Context Server**
- `fr-16` → e35 ("DORA metrics extension") — but **e35 is now Missing Historical References**, and DORA was **superseded by fr-20 (e40)**

**Fix:** fr-13 → `epic: e35`; fr-16 → mark `superseded_by: fr-20 (e40)`.

### GAP-H2 — Train ordering not WSJF-sorted

v2.7x/v3.0 train lists: `[e37, e36, e42, e39, e41, e43, e32, e44]`. Actual WSJF:

| Epic | WSJF | Title |
|------|------|-------|
| e32 | 4.00 | MCP Server |
| e44 | 3.75 | Migrate Version |
| e41 | 3.75 | Public Receipts |
| e39 | 3.60 | Semantic Bridge |
| e43 | 2.50 | Showcase Repo |
| e37 | 2.10 | BCP Plus |
| e42 | 1.80 | Golden Stories |
| e36 | 1.40 | Doc Dedup |

Resorting by WSJF with dependency constraints (e32→e39→e44 form a chain; e41 blocked on e28): `[e32, e39, e44, e41, e43, e37, e42, e36]`.

### GAP-H3 — v2.6x train completely unbuilt (46 BCP blocking)

e33 (13 BCP), e35 (20 BCP), e28 (13 BCP) are all backlog. They gate e39, e41, and e37. **Mitigated by leading with e28** — the most heavily depended-on epic in the train.

### GAP-H4 — e42 status: active but only spike done

`execution-status.yaml` marks `e42: "active"` but only e42s01 is done; s02–s04 are backlog. Spike passed — epic should be `"ready"` (spike gate cleared, queue s02).

**Fix:** Set e42 to `"ready"` in execution-status.

---

## 🟡 Medium Severity

### GAP-M1 — Duplicate `source:` block in e45 epic.yaml

`specs/epics/e45-okf-completion/epic.yaml` has `source:` twice (lines 3 and 17) with near-identical content. De-duplicate.

### GAP-M2 — e35 20 BCP for reference docs is high

Missing Historical References is content-only documentation work at 20 BCP — nearly 2× the MCP server (13 BCP). Worth examining whether all 9 references need full treatment or can be slimmed (e36 Doc Dedup already covers provenance-pointer pattern).

---

## 🟢 Low Severity

### GAP-L1 — e42 capsule release label

e42 epic.yaml now shows `release: v2.7x/v3.0` — if this was fixed since previous audit, close.

### GAP-L2 — state.yaml active_flow is null

With e28 targeted as next, `active_flow: build_epic` + `epic_id: e28` should be set.

### GAP-L3 — e26 drift_note not acted on

Cosmetic — `sync-status-from-epics.sh` not run for e26's stale status note.

---

## Principles Alignment

| Check | Status | Note |
|---|---|---|
| Vertical slices | ✅ | Stories are single-deliverable with verify:/ac: throughout |
| Scope bounded | ⚠️ | fr-13/fr-16 stale; otherwise complete (fr-01–fr-26) |
| Success criteria | ✅ | Mechanical verify commands everywhere sampled |
| HARD GATE candidates | ✅ | 72/73 skills carry HARD GATE blocks |
| Domain language | ✅ | OKF.md anchors terminology; GLOSSARY adequate |

## Conventions Completeness

| Check | Status | Note |
|---|---|---|
| CLAUDE.md / CONVENTIONS.md | ✅ | Current, naming-exception table complete |
| specs/ layout | ✅ | Validates clean; ADR-0001–0006 present |
| Conventional Commits | ✅ | semantic-release wired |
| Git workflow | ✅ | solo-git via land-branch.sh |

## Pre-flight Answers

| Question | Value |
|---|---|
| Test | Gate suite: `npm run compliance && run-golden-suite.sh` |
| Build | `bash scripts/install.sh` |
| Lint | `bash scripts/sync-skills.sh` |
| Typecheck | N/A currently (e32 introduces TypeScript) |
| CI | GitHub Actions (publish.yml, sync-skills.yml, e42-golden-deepseek.lock.yml) |
| Solo/team | Solo |
| Language | Markdown / Bash (+ TS for e32, Astro for e33) |
| Greenfield/existing | Existing, 30+ shipped epics |

---

## Gap Closure (2026-07-03, this session)

- [x] **C1:** 7 capsule_dir values corrected in release-plan.yaml
- [x] **C2:** state.yaml handoff set to `e28` (Sync Pipeline Refactor)
- [x] **H1:** SCOPE fr-13 → e35, fr-16 → superseded
- [x] **H2:** v2.7x train re-sorted by WSJF with dependency constraints
- [x] **H4:** e42 status set to `ready` in execution-status
- [x] **M1:** e45 duplicate `source:` block deduplicated
- [ ] **C3:** e41 depends_on e28 — unblocked once e28 lands (leading epic)
- [ ] **M2:** e35 BCP re-examination deferred to e35 build

---

## Verdict

**READY — critical gaps closed.** e28 (Sync Pipeline Refactor, 13 BCP) leads as the architectural dependency unblocking e39, e32, and e41.

**Next skill:** `survey-context` → `build-epic` on **e28** (v2.6x train, WSJF 2.0, unblocks 3 downstream epics).
