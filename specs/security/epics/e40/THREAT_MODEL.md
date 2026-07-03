# Threat Model — e40 Metrics Integrity

**Date:** 2026-07-03
**Epic:** e40 — Metrics Integrity (Honest, Additive, Benchmarkable)
**Scope:** 8 stories covering git-derived metrics, OKF bundles, CI validation, telemetry capture
**Risk Level:** LOW
**Reviewer:** security-review (build-epic Step 0)

## Surface Area

| # | Component | Type | Exposure |
|---|-----------|------|----------|
| 1 | `scripts/record-cycle-time.sh` | Bash script | Reads git history; writes OKF bundles to disk |
| 2 | `scripts/validate-okf.sh` | Bash script | Reads YAML/OKF bundles; validates structure |
| 3 | `specs/templates/story-metrics.okf.md` | Template | Defines OKF bundle schema |
| 4 | `release-branch` integration | Skill hook | Invokes record-cycle-time.sh at merge |
| 5 | CI workflows (`.github/workflows/`) | GitHub Actions | Runs validate-okf.sh; uploads artifacts |
| 6 | Telemetry capture | Runtime hook | Reads harness session data (pi, Claude Code) |

## Vulnerability Assessment

### 1. Command Injection — record-cycle-time.sh

**Analysis:** `git log` output is parsed in bash. The `commit_range` parameter
(e.g., `8823212..d1abc82`) is user-supplied at merge time via `release-branch`.
If an attacker could inject shell metacharacters into `commit_range`, command
injection is possible.

**Mitigation:** `commit_range` should be validated as `^[0-9a-f]+\.\.[0-9a-f]+$`
before passing to `git log`. bash `set -euo pipefail` and quoting `"$commit_range"`
prevent most injection paths.

**Risk:** LOW — callers are trusted (release-branch skill, not external input).
**Confidence:** 8 (well-known pattern, requires attacker control of skill invocation).

### 2. YAML Deserialization — validate-okf.sh

**Analysis:** validate-okf.sh uses Python `yaml.safe_load()` which is safe against
arbitrary code execution (unlike `yaml.load()`). The bigpowers codebase already
uses `safe_load` exclusively.

**Mitigation:** Already safe. validate-okf.sh should use Python's `yaml.safe_load`
(not `yaml.load`). Enforce in code review.

**Risk:** NEGLIGIBLE — `safe_load` is the project standard.
**Confidence:** 9 (safe_load is a known-safe deserializer).

### 3. Secrets Exposure — Telemetry Data

**Analysis:** Agent telemetry capture (e40s04) collects `cost_usd`, `tokens`,
`cache_hit_rate`, `tool_calls`, `model`, `tier`. These are operational metrics,
NOT secrets. No API keys, tokens, or credentials are captured.

**Mitigation:** Template explicitly excludes credential fields. If the harness
exposes raw API keys (unlikely), filter before writing.

**Risk:** NEGLIGIBLE — no secrets in scope.
**Confidence:** 9 (telemetry schema is public, non-sensitive fields).

### 4. CI/CD Pipeline Injection — GitHub Actions

**Analysis:** validate-okf.sh runs in CI (sync-skills.yml). The script reads
local YAML files and runs `git log` to validate `commit_range`. If a malicious
OKF bundle is committed to the repo, validate-okf.sh would process it — but
the bundle would already be in the trusted repo (attacker has push access).
The script is read-only; it doesn't modify files or execute code from bundles.

**Mitigation:** validate-okf.sh is a read-only validator. No write operations,
no `eval`, no shell expansion from bundle content. `safe_load` prevents YAML
code execution.

**Risk:** NEGLIGIBLE — same trust model as existing CI scripts.
**Confidence:** 9 (existing CI surface is identical; no new attack paths).

### 5. Path Traversal — File Operations

**Analysis:** record-cycle-time.sh writes OKF bundles to `specs/metrics/`.
validate-okf.sh reads from `specs/metrics/`. Paths are constructed relative to
`REPO_ROOT` with hardcoded directory names. No user-supplied path components.

**Mitigation:** Paths are hardcoded (`specs/metrics/`), not derived from input.
No `../` traversal vector.

**Risk:** NEGLIGIBLE — hardcoded paths, no user input.
**Confidence:** 9 (no path construction from untrusted input).

### 6. Data Integrity — Fabricated Metrics

**Analysis:** NOT a security vulnerability — this is the problem e40 exists to fix.
The existing `cycle-times.yaml` contains fabricated rows (11× identical 45-min blocks,
120 BCP/hr outliers). e40 replaces agent-self-reported metrics with git-derived,
provenance-gated metrics. The validate-okf.sh provenance gate ensures bundles are
only accepted when the official generator ran and `commit_range` resolves.

**Risk:** METHODOLOGY — not a security threat. The fix is the epic itself.

## Mitigation Guidance

| # | Requirement | Story |
|---|-------------|-------|
| 1 | `commit_range` validated as `^[0-9a-f]+\.\.[0-9a-f]+$` before git log | e40s01 |
| 2 | `bash -n` parse check on all shell scripts before commit | e31 (existing gate) |
| 3 | Use `yaml.safe_load()` exclusively (already the standard) | e40s06 (validate-okf.sh) |
| 4 | No secrets in telemetry schema — filter if harness exposes credentials | e40s04 |
| 5 | Read-only validator — no shell expansion from bundle content | e40s06 |
| 6 | Paths hardcoded; no user-supplied path components | e40s01, e40s06 |

## Verdict

**Risk Level: LOW.** No critical, high, or medium security vulnerabilities
identified. The epic adds shell scripts and YAML processing — both already
well-defended in the existing codebase (`safe_load`, hardcoded paths, trusted
callers). The primary risk is a METHODOLOGY concern (fabricated metrics) which
the epic itself resolves.

**Gate:** No findings ≥ confidence 8 that require mitigation beyond what the epic
already provides. Step 0 passes.
