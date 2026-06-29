# Impact Assessment — Backlog Epics e15–e21

> Generated: 2026-06-20
> Scope: All 7 backlog epics (e15 CI/CD → e21 MCP Discovery)
> Existing modules modified: **15 SKILL.md files + 1 conventions doc + 1 config file**

---

## 1. Target Overview

Seven backlog epics propose changes to **15 existing skill files**, **1 conventions doc** (CONVENTIONS.md), and **1 processing pipeline** (sync-skills.sh). Four epics create net-new skills with zero existing dependents; three epics (e15, e18, e20, e21) touch shared modules.

### Affected per Epic

| Epic | New Skills | Existing Skills Modified |
|------|-----------|-------------------------|
| **e15** CI/CD | wire-ci, publish-package | release-branch, develop-tdd |
| **e16** Deploy | deploy, smoke-test | — (net-new) |
| **e17** Contracts | validate-contracts | — (net-new) |
| **e18** Quality Gates | — | build-epic, audit-code, enforce-first, assess-impact, fix-bug, orchestrate-project, session-state, stocktake-skills |
| **e19** Quick-Fix | quick-fix | — (net-new) |
| **e20** Ergonomics | — | change-request, kickoff-branch, verify-work, develop-tdd, build-epic, release-branch, CONVENTIONS.md |
| **e21** MCP | mcp-server.js, bp-opensrc-check.sh, bp-read-agents.sh, workflows/ | research-first, verify-work, compose-workflow |

---

## 2. High-Risk Shared Modules

### 🔴 build-epic/SKILL.md — modified by TWO epics (e18 + e20)

| Change | Epic | Story |
|--------|------|-------|
| audit-code hard gate at step 6 | e18 | e18s01 |
| enforce-first sub-check at step 6 | e18 | e18s02 |
| assess-impact pre-check at step 2 | e18 | e18s03 |
| --fast mode (coalesce steps 1+2, 6+7) | e20 | e20s05 |

**Risk:** Two epics touching the same file with overlapping step re-organization. Step 6 gets both audit-code (hard gate) and enforce-first (sub-check) from e18, while e20 coalesces steps 6+7. Must be merged carefully — order: `audit-code → enforce-first → commit-message` in the coalesced block.

### 🔴 verify-work/SKILL.md — modified by TWO epics (e20 + e21)

| Change | Epic | Story |
|--------|------|-------|
| verify-command validation pre-check | e20 | e20s04 |
| --cli mode for CLI tools | e20 | e20s06 |
| AGENTS.md preflight extraction | e21 | e21s03 |

**Risk:** Two epics add sections to the same file. Verify validation is a pre-UAT step; --cli mode is an alternate mode; AGENTS.md integration is a pre-check. These are non-conflicting if sequenced correctly, but the --cli mode and AGENTS.md both affect how verify-work starts up.

### 🟡 release-branch/SKILL.md — modified by TWO epics (e15 + e20)

| Change | Epic | Story |
|--------|------|-------|
| CI verification step 8b | e15 | e15s03 |
| --squash-state flag | e20 | e20s02 |

**Risk:** Both add sections to a well-structured 140-line file. CI verification is a new step (8b after push); --squash-state is a flag that affects merge behavior. These are additive, not conflicting.

### 🟡 develop-tdd/SKILL.md — modified by TWO epics (e15 + e20)

| Change | Epic | Story |
|--------|------|-------|
| CI dry-run sub-step for workflow changes | e15 | e15s03 |
| --config mode for pure-config tasks | e20 | e20s05 |

**Risk:** Both add alternate modes / sub-steps. CI dry-run triggers only when workflow files change; --config mode is a flag. Non-conflicting.

---

## 3. Dependents Count

| File | Direct Referees | Test Coverage | Cross-Epic Hits |
|------|----------------|--------------|-----------------|
| **build-epic/SKILL.md** | 20+ (specs, skills) | 0 | **2** (e18, e20) |
| **verify-work/SKILL.md** | 15+ (skills, CHANGELOG, specs) | 0 | **2** (e20, e21) |
| **release-branch/SKILL.md** | 15+ (skills, metrics, specs) | 0 | **2** (e15, e20) |
| **develop-tdd/SKILL.md** | 12+ (skills, specs, adr) | 1 (dashboard/test/smoke.test.js) | **2** (e15, e20) |
| **session-state/SKILL.md** | 8+ (CONVENTIONS, CHANGELOG, specs) | 0 | 1 |
| **audit-code/SKILL.md** | 5+ | 0 | 1 |
| **kickoff-branch/SKILL.md** | 4+ | 0 | 1 |
| **CONVENTIONS.md** | 15+ (project ground truth) | 0 | 1 |

---

## 4. Test Coverage

| Test File | Covers |
|-----------|--------|
| `dashboard/test/smoke.test.js` | develop-tdd (e2e smoke test) |

**Gap:** Zero unit tests exist for any SKILL.md — these are documentation files, not code. Verification relies entirely on:
- `bash scripts/sync-skills.sh` (regenerates derived artifacts)
- `bash scripts/validate-specs-yaml.sh` (validates YAML layout)
- Manual `plan-work → verify-work` gates

---

## 5. Downstream Propagation

Every SKILL.md change propagates through `scripts/sync-skills.sh` to:
| Artifact | Location | Count |
|----------|----------|-------|
| Cursor rules | `.cursor/rules/` | 62 rules |
| Gemini skills | `.gemini/extensions/bigpowers/skills/` | 62 skills |
| Pi skills | `.pi/skills/` | 62 skills |
| OpenSkills | `.opn/skills/` | 62 skills |
| **skills-lock.json** | repo root | SHA-256 catalog |
| **SKILL-INDEX.md** | repo root | Auto-generated index |

**All 15 modified SKILL.md files will cascade to 6 artifact targets each = 90 artifact updates.**

---

## 6. Risk Classification

| Level | Count | Epics |
|-------|-------|-------|
| **HIGH** | 2 shared files | build-epic (2 epic overlap), verify-work (2 epic overlap) |
| **MEDIUM** | 2 shared files | release-branch (2 epic overlap), develop-tdd (2 epic overlap) |
| **LOW** | 11 skill files | Single-epic modifications with no cross-epic overlap |

### Risk: Medium

**Rationale:** Four files have cross-epic modifications (2 epics each) but the changes are additive (different sections/modes), not conflicting on the same lines. No code-level dependencies exist — these are agent instruction docs, not runtime modules. The 90-artifact cascade is mechanical (sync-skills.sh handles it). The main risk is sequencing: if e18 and e20 modify build-epic in the same session without a checkpoint, the merged file could lose a section.

---

## 7. Recommended Execution Order

```
1. e16 (Deploy)         → net-new, no conflicts
2. e17 (Contracts)      → net-new, no conflicts  
3. e19 (Quick-Fix)      → net-new, no conflicts
4. e15 (CI/CD)          → touches release-branch, develop-tdd (first to modify)
5. e21 (MCP)            → touches verify-work, research-first, compose-workflow (second to modify verify-work)
6. e20 (Ergonomics)     → touches verify-work, build-epic, release-branch, develop-tdd (third to touch shared files — needs careful merge)
7. e18 (Quality Gates)  → touches build-epic + 7 others (last — merges into finalized build-epic)
```

**Why e18 last:** It has the widest blast radius (8 existing files) and build-epic is the most cross-referenced skill (20+ referees). Let all other modifications land first, then bring in the quality gates last.

---

## 8. Next Steps

1. **Start with net-new epics** (e16 → e17 → e19) — zero conflict risk, build momentum
2. **For build-epic/SKILL.md**: merge e20's `--fast` mode changes BEFORE e18's hard gate changes
3. **For verify-work/SKILL.md**: merge validation pre-check (e20) before AGENTS.md integration (e21)
4. **Run `plan-work e15s01`** when ready to start on wire-ci skill
