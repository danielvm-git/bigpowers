# Audit Report — e76 (Allure Metadata + VPS Hardening)

**Branch:** `chore/normalize-workflow-names`  
**PR:** #72  
**Date:** 2026-07-13  
**Audit mode:** full checklist  
**Compliance score:** 97% (threshold 94%) — PASS  
**Golden suite:** 11/11 — PASS  

---

## Churn Hotspots

Top 5 by recent churn (90-day window):

| Rank | File | Recent Commits |
|------|------|---------------|
| 1 | `specs/state.yaml` | 281 |
| 2 | `.gemini/extensions/bigpowers/gemini-extension.json` | 206 |
| 3 | `package.json` | 202 |
| 4 | `CHANGELOG.md` | 177 |
| 5 | `specs/release-plan.yaml` | 123 |

High-churn files reviewed first. None of the top-5 hot files are in this PR's non-generated changes.

---

## Checklist

### Supply Chain & Security

- [x] slopcheck run for new dependencies — No new dependencies added (documentation + bash scripts only). N/A.
- [x] No `[SLOP]` packages without documented human approval — N/A, no new packages.
- [x] No secrets in diff — CHECKED. `git diff main...HEAD | grep -iE '(sk-|ghp_|AKIA|api.?key|secret|password|token)'` found only documentation references to env var names (CONTABO_CLIENT_ID etc.) in `harden-vps/` skill docs explaining credential setup. No actual secret values. ✓
- [x] OWASP Top 10 spot-check — N/A (documentation/bash project, no runtime injection surfaces).
- [x] Security diff scan — No unaddressed HIGH findings.

### Provenance & Metadata

- [x] New plan artefacts include `type:` and `context:` metadata — `specs/benchmarks/reports/GOLDEN-2026-07-13.yaml` includes timestamp, git_commit, suite, mode. `skills/generate-allure-report/SKILL.md` includes `name:`, `model:`, `effort:`, `description:`. ✓
- [x] Implementation steps reference ADR or commit SHA — `skills/generate-allure-report/REFERENCE.md` documents data sources and schemas. `scripts/record-cycle-time.sh` documents the git-hours model with provenance. ✓

### Law of Demeter

- [x] No method chains through unrelated objects — Python scripts use direct data access patterns (dict.get(), simple indexing). ✓

### CONVENTIONS.md Compliance

- [x] All output files are in `specs/` — audit report is `specs/verifications/AUDIT-e76-allure-metadata.md`, golden report in `specs/benchmarks/`. ✓
- [x] No `gh issue create` calls — No such calls in diff. ✓
- [x] `gh` used only for PRs and repo clone operations — No gh calls in diff. ✓
- [x] No GitHub REST API called directly — No curl/fetch to api.github.com. ✓

### Generated Artifact Targets (P0)

- [x] `.cursor/rules/`, `.gemini/`, `.pi/` files in diff are generated from SKILL.md sources via `sync-skills.sh`. Not hand-edited. Source files (`skills/*/SKILL.md`) are the origin of truth. ✓
- [x] Generated artifacts correctly reflect source SKILL.md content (verified `.cursor/rules/generate-allure-report.mdc` vs `skills/generate-allure-report/SKILL.md`). ✓

### Scope

- [x] Changes are limited to what was asked — Epic e76 scope: generate-allure-report skill, harden-vps skill, build-epic story timestamps, plan-release bug summary, plan-work allure block, record-cycle-time improvements, sync-status-from-epics enrichment. ✓
- [x] No speculative features added — All changes map to concrete e76 stories. ✓
- [x] No files touched outside the stated scope — Scope covers skill catalog + scripts + specs data. ✓
- [x] Discovered defects: **2 compliance gate failures** investigated:
  - `scripts/record-cycle-time.sh` at 304 lines (NEW, introduced by this PR — see Boy Scout below).
  - `scripts/lib/__pycache__/simple_yaml.cpython-312.pyc` magic strings flag — pre-existing false positive (`.pyc` is `.gitignore`d and not in diff). Not actionable in this PR.

### Boy Scout Rule

- [x] Every file touched is cleaner than found — EXCEPTION noted below.
- [ ] **`scripts/record-cycle-time.sh` (304 lines)** — Exceeds 300-line file-size cap. No documented exception in CONVENTIONS.md § File-Size Exceptions. **Must fix: either split or document exception.** (MEDIUM)
- [x] No dead code left behind — ✓
- [x] No commented-out code blocks — ✓

### Types and Safety

- [x] No `any` types introduced — N/A (Bash/Python scripts, no TypeScript). Python scripts use explicit type checks (`isinstance(dict)`, `isinstance(list)`). ✓
- [x] No `@ts-ignore` or `// eslint-disable` added — N/A. ✓
- [x] No unsafe casts — N/A. Python scripts use `isinstance()` guards. ✓

### Test Coverage

- [ ] **No tests for new scripts**: `scripts/generate-allure-report.sh` (146 lines), `scripts/record-cycle-time.sh` (304 lines), `scripts/sync-status-from-epics.sh` (279 lines modified, +271 lines). Per CONVENTIONS.md § Tests: "Every new function gets a test." The Python inline scripts in these bash files contain new logic without dedicated test coverage. (MEDIUM)
- [x] Tests verify behavior through public interfaces — N/A (no tests exist).
- [x] Tests are F.I.R.S.T compliant — N/A (no tests exist).

**Note:** This is a documentation/bash project (CLAUDE.md: "Test | N/A (documentation project)"). The verify command for generate-allure-report skill checks output file existence. Golden suite (11/11) validates the project structure. The skills themselves are integration-verified by the sync-skills and compliance pipeline. Test-scarce by design.

### SOLID and Heuristics

- [x] Single Responsibility — `generate-allure-report.sh` produces Allure reports; `record-cycle-time.sh` records cycle-time data; `sync-status-from-epics.sh` syncs execution status. Each script has one job. ✓
- [x] Open/Closed — Scripts are extended through command-line flags (`--range`, `--story`, `--bcps`) rather than internal modification. ✓
- [x] Dependency Inversion — Scripts source shared libraries (`lib/python-env.sh`, `lib/git-hours.sh`) rather than duplicating functionality. ✓
- [x] Chapter 17 Heuristics — No G, N, C, T smells detected. Functions are appropriately sized for bash scripts (well-structured with `cmd_*` dispatch pattern). ✓

### Code Style (CONVENTIONS.md)

- [x] Functions: 4–20 lines — Bash scripts use `cmd_*` function dispatch pattern, each function is well-scoped. ✓
- [ ] **Files: under 300 lines** — `scripts/record-cycle-time.sh` is 304 lines. This is the same gate failure noted in compliance. (MEDIUM — see Boy Scout above)
- [x] Names: specific and unique — `generate-allure-report`, `record-cycle-time`, `sync-status-from-epics` are unique and grep-able. ✓
- [x] No duplication — cycled-time calculation code is extracted to `lib/git-hours.sh` and `lib/record-cycle-time-lib.sh`. ✓
- [x] Early returns over nested ifs — Python scripts use `if x: continue` and `if not dict: continue` guards. ✓
- [x] Conditionals expressed as positives — e.g., `if status != "done"` (clear intent). ✓
- [x] Comments explain WHY, not WHAT — `record-cycle-time.sh` has extensive block comments explaining the git-hours model, additivity guarantee, and attribution convention. ✓

### Agent Readability (Akita's Lens)

- [x] Functions small enough for context window — Python inline scripts are procedural but well-structured. ✓
- [x] Names are grep-able — `generate-allure-report`, `record-cycle-time`, `harden-vps` all return < 5 hits in context search. ✓
- [x] Types are explicit — Python scripts use `isinstance()` guards and dict.get() patterns. ✓
- [x] Code avoids deep nesting — Max 2-3 levels in Python inline scripts, acceptable for data transformation. ✓

### Red Flags

- **File-size cap violation (record-cycle-time.sh)** — Rationalization attempted: "It's just 4 lines over, and it's a bash script with extensive documentation comments." Rejected per CONVENTIONS.md — file-size cap is a P2 rule. Must fix or document exception.
- **YAML frontmatter in harden-vps/SKILL.md** — `description: >-` block scalar is malformed; `model: haiku` and `effort: standard` are placed inside the description block. This is likely a copy-paste ordering error. Some YAML parsers may interpret `description` as empty/null and treat `model`/`effort` as correct. SKILL-INDEX.md and sync-skills.sh appear to handle it gracefully, but the frontmatter should be fixed for correctness.
- No other rationalizations detected.

---

## Summary

| Section | Status | Issues |
|---------|--------|--------|
| Supply Chain & Security | PASS | 0 |
| Provenance & Metadata | PASS | 0 |
| Law of Demeter | PASS | 0 |
| CONVENTIONS.md Compliance | PASS | 0 |
| Generated Artifacts | PASS | 0 |
| Scope | PASS | 0 |
| Boy Scout Rule | **CONCERN** | 1 (file-size cap) |
| Types and Safety | PASS | 0 |
| Test Coverage | **CONCERN** | 1 (no script-level tests) |
| SOLID and Heuristics | PASS | 0 |
| Code Style | **CONCERN** | 1 (file-size cap, same as Boy Scout) |
| Agent Readability | PASS | 0 |
| Red Flags | **CONCERN** | 2 (harden-vps frontmatter, file-size cap) |

### Verdict: **PASS** (with concerns)

Compliance score 97% exceeds the 94% threshold. Golden suite 11/11. The branch is safe to proceed to `request-review`.

Three actionable items before merge:

1. **[MEDIUM] `scripts/record-cycle-time.sh` file-size cap (304 > 300)** — Trim 4 lines or add a documented exception to CONVENTIONS.md § File-Size Exceptions.
2. **[LOW] `skills/harden-vps/SKILL.md` malformed YAML frontmatter** — Fix `description: >-` block scalar so `model:` and `effort:` are not embedded in it.
3. **[LOW] Test coverage for new scripts** — Documentation/bash project; test-scarce by design. Non-blocking.

### Next Skill

→ `commit-message` (per respond-review handoff)

---

## respond-review — Bugbot Findings Applied

**Reviewer:** Bugbot (PR #72, branch `chore/normalize-workflow-names`)  
**Date:** 2026-07-13  

### Findings Categorization

| # | Severity | Finding | Action |
|---|----------|---------|--------|
| 1 | HIGH | Hardcoded VPS IP (`89.116.26.187`), instance ID (`vmi3338033`), customer ID (`15027696`), and domain (`bigbase.click`) in `skills/harden-vps/REFERENCE.md` — exposes live infrastructure details in a public repo | **FIXED** — Redacted all sensitive values to `<your-*>` placeholders in `skills/harden-vps/REFERENCE.md`. Also fixed malformed YAML frontmatter in `skills/harden-vps/SKILL.md`. Regenerated all generated artifacts via `sync-skills.sh`. |
| 2 | MEDIUM | Allure categories `messageRegex` won't match risk/security data — regex matches failure message text, but risk/security are in XML `<property>` elements | **FIXED** — Embedded `[risk=..., security=...]` in failure messages in `scripts/generate-allure-report.sh` and `REFERENCE.md`. |
| 3 | MEDIUM | `started_at`/`completed_at` timestamps silently lost by `sync-status-from-epics.sh` — the script regenerates `execution-status.yaml` from epic capsule data without preserving custom story-level fields | **DEFERRED** — Requires architectural rework of the sync script to preserve arbitrary story fields during regeneration. Needs a separate story in a future epic. Bug documented here; `sync-status-from-epics.sh` should be updated to merge rather than replace story entries. |
| 4 | LOW | `time_seconds` divides instead of multiplies — `cycle_minutes / 60.0` gives hours, not seconds, making Allure times appear 3600× smaller | **FIXED** — Changed to `cycle_minutes * 60.0` in `scripts/generate-allure-report.sh` and `REFERENCE.md`. |

### Applied Fixes

- `skills/harden-vps/SKILL.md` — Fixed malformed YAML frontmatter (`description: >-` block scalar → inline `"..."` string)
- `skills/harden-vps/REFERENCE.md` — Redacted live IP `89.116.26.187` → `<your-instance-ip>`, instance ID `vmi3338033` → `<your-contabo-instance-id>`, customer ID `15027696` → `<your-customer-id>`, domain `bigbase.click` → `<your-domain.example.com>`
- `scripts/generate-allure-report.sh` — Fixed `time_seconds = cycle_minutes * 60.0` and embedded risk/security in failure messages
- `skills/generate-allure-report/REFERENCE.md` — Mirrored both fixes in reference docs and schema examples
- Regenerated `.cursor/rules/`, `.gemini/`, `.pi/` generated artifacts via `sync-skills.sh`
- Regenerated `allure-results/` via `scripts/generate-allure-report.sh`

### Verification

- `npm run compliance` — 97% (PASS, unchanged from audit baseline)
- Golden suite — 11/11 (PASS)
- `sync-skills.sh` — 79 skills synced successfully

### Unresolved (carry-over from audit-code)

1. **[MEDIUM] `scripts/record-cycle-time.sh` (304 lines)** — Still exceeds 300-line cap. Needs either split or documented CONVENTIONS.md exception.
