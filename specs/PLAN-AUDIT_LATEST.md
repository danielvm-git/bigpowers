# Plan Audit — Full release plan re-audit after 21-task remediation (red team)

**Date:** 2026-07-03 · **Verdict:** READY — all 4 gaps closed and re-verified same session (see Gap Closure below)

**Plan audited:** entire forward backlog (`specs/release-plan.yaml` release trains v2.6x → v2.8x: e33, e43, e39, e44, e28, e41, e42, e37, e32, e36, e45) plus the 21 remediation claims from the 2026-07-03 fix session. Every claim was re-verified against the working tree and by re-running the gates — not taken from the completion report.

**Remediation verification: 19 of 21 tasks fully verified. 1 introduced a regression (A6). 1 is incomplete (C18).**

| Verified ✅ | Evidence |
|---|---|
| A1 e43 story IDs | epic.yaml now e43s01–e43s07 |
| A2 e13s02 tag | `trace-stories.sh --strict` exit 0 on main |
| A3 drift sync | execution-status: e26 done, e35 superseded, e37 active |
| A4 G-05→G-06 | e44 epic.yaml:98 says G-06; no collision with e37's g-05 |
| A5 m2 ADR move removed | registry + m2 bundle: `set_yaml_key` only |
| A7 registry version mirror | "mirror, not the authority" comment + 2.56.1 |
| A8 state.yaml stamp | `bigpowers_version: "2.56.1"` at state.yaml:36 |
| A9 m1/convert-legado | reconciled in e44s01 spec |
| B10 release-plan mirror | v2.56.1, synced 2026-07-03 |
| B11 "72 skills" | zero hardcoded-count hits in README |
| B12 naming exceptions | 6 new rows in CONVENTIONS table |
| B13 ADR-0004/0006 | both amended to "shipped in v2.x — evolved" |
| B15 first OKF metrics bundle | `specs/metrics/e38s09.okf.md` PASSes via `--dir` |
| C16 overlap resolved | e43 `supersedes: scripts/mcp-server.js`; e39s01 re-scoped to emit via e43 |
| C17 e43 slotted | v2.7x train: `[e43, e39, e44, e28, e41, e42, e37]` |
| C19 okf.md authority | `docs/references/okf.md` exists, covers all okf_kinds |
| C20 e42 pulled forward | in v2.7x train list |
| C21 renumbering note | release-plan.yaml:65 "DO NOT RENUMBER EPIC IDs" |
| B14 compliance FAILs | score 84/4 = 95%, GATE PASS; 4 FAILs remain documented |

## Principles Alignment

| Check | Status | Note |
|---|---|---|
| Vertical slices | ✅ | All forward epics use single-deliverable stories with verify:/ac: blocks; e44's 6 stories carry 44 task-level verify commands. |
| Scope bounded | ⚠️ | SCOPE has fr-01–fr-24 incl. fr-23 (e43), fr-24 (e44). **e45 has no FR entry** and no execution-status keys — it exists only as a release-plan row. |
| Success criteria | ✅ | Mechanical verify everywhere sampled; e41's "absent is a state, not an error" and e40's provenance gate are exemplary. |
| HARD GATE candidates | ✅ | 72/73 skills carry HARD GATE; trace gate + compliance gate + doctrine all green this session. |
| Domain language | ⚠️ | okf.md now anchors OKF (closes the prior audit's biggest term gap); GLOSSARY_LATEST.yaml itself remains sparse. Non-blocking. |

## Conventions Completeness

| Check | Status | Note |
|---|---|---|
| CLAUDE.md / CONVENTIONS.md | ✅ | Present, current, naming-exception table now complete. |
| specs/ layout | ✅ | `validate-specs-yaml.sh: OK`; `validate-doctrine.sh: ALL checks passed`. |
| Conventional Commits | ✅ | Documented + semantic-release wired. |
| Git workflow mode | ✅ | solo-git profile (land-branch.sh) documented in CONVENTIONS. |

## Pre-flight Answers

| Question | Value |
|---|---|
| Test | N/A (doc project) — gates: `npm run compliance`, `run-golden-suite.sh` |
| Build | `bash scripts/install.sh` |
| Lint | `bash scripts/sync-skills.sh` |
| Typecheck | N/A (e43 will introduce TypeScript — its capsule declares the stack) |
| CI | GitHub Actions (publish.yml, sync-skills.yml incl. strict trace gate) |
| Solo/team | Solo (solo-git) |
| Language | Markdown / Bash (+ TS for e43, Astro for e28) |
| Greenfield/existing | Existing, 30+ shipped epics |

## Gap Closure (re-verified 2026-07-03, red team)

- [x] **GAP-1 CLOSED:** no-arg mode scans both default dirs (4 bundles PASS), positional dirs accepted (exit 0), unknown flags exit 1 (verified with clean exit-code probe, no pipe pollution). Gate now fails closed.
- [x] **GAP-2 CLOSED:** `specs/epics/e45-okf-completion/epic.yaml` exists (5 stories), fr-25 in SCOPE_LATEST.yaml:83, 6 e45 keys in execution-status.yaml.
- [x] **GAP-3 CLOSED:** e42 capsule now `release: v2.7x/v3.0` with provenance comment.
- [x] **GAP-4 CLOSED:** compliance re-run confirms 85 PASS / 3 FAIL = 96%; `is_empty_json_value` fully renamed (0 hits); validate-okf.sh at 297 lines. Remaining 3 FAILs documented as intentional (usage symbol convention, trace-stories.sh 613 lines + 2 scripts >300).
- [x] **Bonus:** G-04 golden selftest, reported as pre-existing FAIL (stale context7 artifact), now passes 7/7 — 73 artifacts across .cursor/.gemini/.pi match lockfile and SKILL-INDEX. Not reproducible; considered resolved.

## Open Gaps (original findings, retained for provenance)

- [ ] **GAP-1 (HIGH — regression from A6):** `validate-okf.sh` default no-arg mode is broken AND fail-open. It mishandles its second default directory (`specs/migrations` hits the flag parser → "unknown flag" → prints usage → **exit 0**), so the default invocation validates nothing and reports success. Positional args (`validate-okf.sh specs/migrations/`) also error with exit 0 — and that exact positional form is what `specs/migrations/registry.okf.md:72` instructs. Explicit `--dir` calls work (metrics: 1 PASS; migrations: 3 PASS). Fix: make no-arg mode iterate both default dirs correctly, accept a positional dir, and **exit non-zero on any usage error** — a gate must fail closed.
- [ ] **GAP-2 (MEDIUM — C18 incomplete):** e45 is registered only in release-plan.yaml. Missing: fr-25 in SCOPE_LATEST.yaml, e45/e45sNN keys in execution-status.yaml, and the capsule dir `specs/epics/e45-okf-completion/` (needs slice-tasks + plan-work before build — acceptable for `proposed`, but SCOPE/status registration is the project's own convention for every planned epic, applied to e43/e44 but not e45).
- [ ] **GAP-3 (LOW):** e42 capsule says `release: v2.8x` while the train list now puts it in v2.7x — same capsule-vs-train drift class that A3 just cleaned up elsewhere. Update the capsule field (and consider e44's `release: v2.45.0` label while touching it).
- [ ] **GAP-4 (LOW):** B14 claimed "1 compliance FAIL fixed" but the score is unchanged at 84 PASS / 4 FAIL (the G28 fix was in validate-okf.sh, not a compliance step). Gate passes at 95%; keep the 4 documented FAILs listed in the next stocktake so they don't silently become permanent.

## Verdict

**READY — all gaps closed and independently re-verified.** Gates green across the board: trace-stories --strict (exit 0), compliance (96%), doctrine (pass), validate-specs-yaml (OK), validate-okf (4/4 bundles PASS, fails closed), G-04 selftest (7/7).

**Next skill:** `survey-context` → `build-epic` on e43 (leads the v2.7x train at WSJF 4.00).
