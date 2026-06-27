---
name: security-review
description: >
  AI-powered security analysis of code changes — traces data flow, detects
  injection, auth bypass, secrets exposure, and unsafe deserialization across
  files. Use when reviewing pending changes, before release-branch, during
  verify-work Phase 5, during build-epic Step 0 threat modeling, or when
  the user says "security review" or "scan for vulns".
---

# Security Review

> **HARD GATE** — Requires git context (branch with merge-base or diff). Never
> writes files outside `specs/security/`. Findings below confidence 8/10 are
> suppressed. **→ verify:** `git rev-parse HEAD >/dev/null 2>&1 && echo "ok" || echo "BLOCKED"`

## 5-phase scan

| # | Phase | What |
|---|-------|------|
| 1 | **Scope Resolution** | Detect diff via `git diff --merge-base origin/HEAD`; resolve languages/frameworks from dependency files |
| 2 | **Context Research** | Identify existing security patterns, sanitization, auth model in the codebase |
| 3 | **Vulnerability Assessment** | Trace user input → sink; check auth boundaries, crypto, deserialization, path ops |
| 4 | **False-Positive Filtering** | Cross-check each finding against exclusion rules; reject confidence < 8 |
| 5 | **Report Generation** | Output structured markdown: file:line, severity, category, exploit scenario, fix |

## Categories

Covered: SQLi, XSS, SSRF, command injection, auth bypass, unsafe deserialization, path traversal, IDOR, crypto flaws, secrets exposure, template injection, NoSQLi

## Integration points

| Skill | Touchpoint |
|-------|------------|
| `build-epic` | Step 0 — threat-model epic scope → `specs/security/epics/<id>/THREAT_MODEL.md` |
| `plan-work` | `security:` field (none/low/medium/high) on story tasks |
| `plan-release` | +2 WSJF risk boost for HIGH+ risk epics |
| `audit-code` | Checklist: "diff scanned — no unaddressed HIGH findings" |
| `request-review` | Inject threat model categories + false-positive rules into reviewer prompt |
| `investigate-bug` | Security-impact assessment in RCA (NONE→CRITICAL) |
| `validate-fix` | Recurrence hardening check for security bugs |
| `verify-work` | Phase 5 — blocks on HIGH findings ≥ 8 confidence |
| `release-branch` | Hard gate — blocks merge if unresolved HIGH findings |

## Report format

Each finding: **`File:Line` — Severity — Category**
- Description: how the vulnerability manifests
- Exploit scenario: concrete attack path
- Recommendation: fix with code example

## Reference files

- [Vuln categories](REFERENCE-vuln-categories.md) — detection guidance per vuln type
- [False positives](REFERENCE-false-positives.md) — hard exclusions + precedent
- [Confidence rubric](REFERENCE-confidence-rubric.md) — scoring methodology (0–10)

## Verify

```bash
test -d specs/security && echo "OK: specs/security/ exists" || mkdir -p specs/security
grep -q "Merge-base\|merge.base\|git diff" SKILL.md && echo "OK: git context verified"
```
