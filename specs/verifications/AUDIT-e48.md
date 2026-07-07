# Code Audit: e48 — Foundation (Knowledge Layer + Process Maturity)

Date: 2026-07-07
Epic: e48 (15 stories, archived)
Auditor: audit-code (self-review)
Status: **CONCERNS** — 3 checklist sections fail; 2 partial

## Churn-ranked review order

Reviewed high-churn hotspots first (`bp-churn-rank.sh --since 90.days`), then e48 implementation files by story cluster.

| Priority | File / cluster | Stories |
|----------|----------------|---------|
| 1 | `scripts/sync-skills.sh`, `scripts/lib/srp-engine.py`, adapters | e48s15 |
| 2 | `scripts/generate-epics-wiki.sh`, `scripts/generate-adr-wiki.sh` | e48s01, e48s06 |
| 3 | `scripts/validate-okf.sh`, `.github/workflows/sync-skills.yml` | e48s05 |
| 4 | `scripts/sync-bugs-registry.sh`, golden/audit OKF emitters | e48s02, e48s03 |
| 5 | `kernel/src/publish-to-wiki.sh`, `.github/workflows/publish-wiki.yml` | e48s07, e48s08 |
| 6 | `kernel/templates/wiki/*`, `bin/bigspec` | e48s09, e48s10 |
| 7 | `specs/viz.html` | e48s04 |
| 8 | BCP Plus skill/template edits | e48s11–e48s14 |

## Verification evidence

```text
bash tests/test-srp-engine.sh                          → PASS
bash scripts/validate-okf.sh --dir specs/epics-wiki    → PASS
bash scripts/validate-okf.sh --dir specs/adr-wiki      → PASS
bash scripts/sync-bugs-registry.sh                     → 43 OKF bundles
test -f specs/viz.html                                 → OK
test -f kernel/templates/wiki/_Sidebar.md              → OK
kernel/src/publish-to-wiki.sh (non-dry-run)            → stub (echo + exit 0)
```

Prior per-story audit: `specs/verifications/AUDIT-e48-e48s15.md` (PASS).

---

## Checklist

### Supply Chain & Security

- [x] No new package dependencies introduced by e48 (PyYAML pre-existing)
- [x] No secrets in implementation files (`WIKI_PAT` referenced via `${{ secrets.* }}` only)
- [x] OWASP spot-check: `srp-engine.py` uses `yaml.safe_load`, subprocess to known adapter paths; no shell injection from user input
- [x] `viz.html` loads D3 from CDN — spec-approved (e48s04); document supply-chain trust boundary
- [x] No unaddressed HIGH security findings in e48 diff

**Section: PASS**

### Provenance & Metadata

- [x] Epic capsule and story specs carry `type:` / `context:` metadata (e48s15 confirmed)
- [x] e48s15 references ADR-0008 in spec steps
- [ ] **Story tags incomplete on legacy scripts** — `generate-epics-wiki.sh` still tagged `e45s01` not `e48s01`; traceability matrix covers e48 but file headers lag

**Section: CONCERNS (1 item)**

### Law of Demeter

- [x] No method-chain violations in e48 Python/bash additions
- [x] Adapter subprocess boundary respects immediate-neighbor collaboration

**Section: PASS**

### CONVENTIONS.md Compliance

- [x] Generated artifacts land under `specs/` (wikis, viz, verifications)
- [x] No `gh issue create` in new/modified e48 scripts
- [x] `gh` usage limited to PR workflows
- [x] No direct GitHub REST API calls

**Section: PASS**

### Scope

- [x] Epic deliverables map to stated `in_scope` (OKF bundles, CI wiring, BCP Plus, SRP seam)
- [ ] **`publish-to-wiki.sh` is a stub** — e48s07 (P1) AC requires link rewrite + wiki push; script prints message and exits 0 without git operations
- [ ] **`bin/bigspec --with-wiki` is a stub** — e48s10 AC requires wiki seeding on init; current implementation is a one-line echo
- [x] BCP Plus integration scoped to docs/skills only (no big-counter core changes)
- [x] Discovered defects: Preflight gates green on main at audit time

**Section: FAIL (2 items)**

### Boy Scout Rule

- [x] e48s15 fixed YAML parse hazard in `define-success/SKILL.md` during SRP work
- [x] No dead/commented code in e48 additions
- [ ] Stub files (`publish-to-wiki.sh`, `bigspec`) left in misleading "complete" state

**Section: CONCERNS (1 item)**

### Types and Safety

- [x] No `any`, `@ts-ignore`, or unsafe casts (bash/python project)
- [x] Python uses explicit error exits; adapters validate JSON via `jq`

**Section: PASS**

### Test Coverage

- [x] e48s15: `tests/test-srp-engine.sh` — dry-run, stdin adapter, cursor/gemini/pi targets
- [ ] **No regression tests** for `generate-epics-wiki.sh`, `generate-adr-wiki.sh`, `sync-bugs-registry.sh`
- [ ] **No tests** for `publish-to-wiki.sh` (even dry-run link-rewrite assertions)
- [ ] **No tests** for `specs/viz.html` graph render smoke
- [x] OKF output indirectly gated by `validate-okf.sh` in CI and local preflight

**Section: FAIL (3 items)**

### SOLID and Heuristics

- [x] SRP seam achieves dependency inversion (JSON contract decouples parser from adapters)
- [x] `srp-engine.py` is a deep module hiding YAML/compile complexity
- [ ] `parse_skill()` (~60 lines) and `main()` (~45 lines) exceed 4–20 line function heuristic (G34)

**Section: CONCERNS (1 item)**

### Code Style (CONVENTIONS.md)

- [x] Files under 300 lines (`srp-engine.py` 245, `generate-epics-wiki.sh` 85)
- [ ] Long functions in `srp-engine.py` (see above)
- [x] Early returns, positive conditionals in adapters
- [x] Names are grep-unique (`srp-engine`, `render_okf_concept`)

**Section: CONCERNS (1 item)**

### Agent Readability

- [x] Adapter stdin/JSON contract is grep-able and documented in e48s15 spec
- [x] Tier assignment in `generate-epics-wiki.sh` uses explicit case table

**Section: PASS**

### Red Flags (rationalizations caught)

1. **"Epic is archived/done, so stubs are acceptable."** — Rejected. Audit-code checks AC correctness, not capsule status. e48s07/e48s10 verify commands only assert file existence, masking incomplete behavior.
2. **"OKF validation in CI is sufficient even if non-blocking."** — Partially rejected. e48s05 is labeled HARD GATE; `sync-skills.yml` uses `continue-on-error: true` and `::warning::` only. `publish-wiki.yml` does block on validate-okf, but the primary push workflow does not.
3. **"validate-okf.sh covers testing for generators."** — Partially accepted for schema conformance only; does not substitute for behavioral/regression tests on generator scripts.

---

## Story-level summary

| Story | Title | Audit |
|-------|-------|-------|
| e48s01 | Epics/ADR OKF bundles | PASS — generators work; OKF validates |
| e48s02 | Verification report OKF | PASS — GOLDEN-*.okf.md emitted |
| e48s03 | Bug registry OKF | PASS — 43 bundles; no dedicated test |
| e48s04 | viz.html | PASS — D3 force layout present; no test |
| e48s05 | OKF CI wiring | **FAIL** — sync-skills OKF step non-blocking vs HARD GATE |
| e48s06 | tier: field | PASS — tier in epics-wiki bundles |
| e48s07 | publish-to-wiki kernel | **FAIL** — stub, no push/rewrite |
| e48s08 | publish-wiki.yml | PASS — workflow exists; gates validate-okf |
| e48s09 | Wiki templates | PASS — header + _Sidebar.md |
| e48s10 | bigspec --with-wiki | **FAIL** — one-line stub |
| e48s11 | big-counter install | PASS — documented in setup-environment |
| e48s12 | BCP Plus template | PASS — `bcp_plus_breakdown` in story-template |
| e48s13 | NFR Gate in security-review | PASS — dimension 12 documented |
| e48s14 | BCP Plus in build-epic | PASS — `bcp_plus` in state handoff |
| e48s15 | SRP hybrid JSON seam | PASS — see AUDIT-e48-e48s15.md |

---

## Verdict

**CONCERNS** — Epic is functionally shippable for OKF generation, validation, BCP Plus docs, and the SRP refactor (core value). Three gaps block a clean PASS:

1. **Stub implementations** — `publish-to-wiki.sh` and `bin/bigspec --with-wiki` do not meet story ACs.
2. **Test coverage** — Generator/sync scripts lack regression tests beyond `validate-okf.sh`.
3. **HARD GATE drift** — e48s05 non-blocking CI contradicts epic labeling (documented in `okf.md` but still a gate failure).

## Recommended fixes (before `request-review` on any follow-up PR)

| Priority | Fix |
|----------|-----|
| P1 | Implement `publish-to-wiki.sh` link rewrite + git push (or mark stories deferred in epic with waived gate) |
| P1 | Make OKF validation blocking in `sync-skills.yml` OR downgrade e48s05 HARD GATE label in epic.yaml |
| P2 | Add `tests/test-okf-generators.sh` covering epics-wiki, adr-wiki, bugs-registry emit + validate |
| P2 | Flesh out `bin/bigspec --with-wiki` or document as intentionally deferred |
| P3 | Split `parse_skill()` in `srp-engine.py` to satisfy 4–20 line heuristic |
| P3 | Add `# story: e48s01` tags to generator scripts |

## Handoff

Gate: **NOT READY** for `commit-message` on new e48 follow-up work.
Next: fix P1 items OR waive with documented exception in `specs/security/EXCEPTIONS.md` / epic amendment.
After fixes: re-run `audit-code e48`, then `request-review`.
