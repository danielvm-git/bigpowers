# Threat Model — e31s01: G-04 Sync-Pipeline Self-Test

**Epic:** e31 — Quality Guarantee — Deterministic Gates
**Story:** e31s01 — Create scripts/golden-g04-selftest.sh
**Date:** 2026-07-02
**Risk level:** LOW

## Surface Area

| Dimension | Detail |
|-----------|--------|
| Language | Bash (no dependencies beyond coreutils) |
| Input | Filesystem reads: `.cursor/rules/*.md`, `.gemini/extensions/bigpowers/*.md`, `.pi/skills/*/SKILL.md`, `skills-lock.json`, `SKILL-INDEX.md` |
| Output | stdout (pass/fail messages), exit code (0/1) |
| Network | None |
| Secrets | None accessed |
| User input | None (no CLI arguments with data) |
| File writes | None (read-only) |
| Invocation context | Local terminal or GitHub Actions CI (read-only permissions) |

## Vulnerability Categories

| Category | Risk | Rationale |
|----------|------|-----------|
| Injection | NONE | No user input; no `eval`; file paths are hardcoded |
| Auth bypass | N/A | No authentication involved |
| Secrets exposure | NONE | No secrets accessed |
| Deserialization | LOW | Parses `skills-lock.json` with `jq` or grep — trusted repo file, not user-supplied |
| Supply chain | NONE | No external dependencies beyond bash coreutils |
| DoS | NONE | File counting is O(n) on ~300 files — sub-second execution |

## Mitigation Guidance

1. Use `jq` for JSON parsing (already installed on ubuntu-latest runners and typical dev machines).
2. Quote all variable expansions to prevent word splitting.
3. Use `set -euo pipefail` for fail-fast behavior.
4. Hardcode target paths — do not accept directory arguments that could enable path traversal.

## Verdict

**ACCEPT — no blocking risks.** The script is read-only, has no network access, no secrets, and no user-controlled input. Standard bash hardening (`set -euo pipefail`, quoted variables) is sufficient.
