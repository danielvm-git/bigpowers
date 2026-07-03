# Threat Model — e38: Spec-to-Code Traceability Gate

**Date:** 2026-07-03
**Epic:** e38 — Traceability Gate (13 BCP, 9 stories)
**Scope:** 3 new scripts + 1 new skill + 5 integration edits
**Reviewer:** build-epic Step 0 automated scan

## Surface Area

| Component | Type | Trust Boundary |
|-----------|------|----------------|
| `scripts/trace-stories.sh` | New shell script | Runs against local repo (trusted input) |
| `scripts/check-blind-spots.sh` | New shell script | Runs against local repo (trusted input) |
| `skills/gate-trace/SKILL.md` | New skill | Agent-invoked, reads local JSON artifacts |
| CI integration (e38s03) | GitHub Actions edit | Runs in CI context from repo contents |
| build-epic SKILL.md edit (e38s02) | Skill edit | Agent invocation instruction |
| verify-work SKILL.md edit (e38s05) | Skill edit | Agent invocation instruction |
| release-branch SKILL.md edit (e38s07) | Skill edit | Agent invocation instruction |
| CONVENTIONS.md edit (e38s08) | Doc edit | No code impact |
| `docs/references/traceability-gate.md` (e38s09) | New doc | No code impact |

## Vulnerability Categories Assessed

| Category | Risk | Rationale |
|----------|------|-----------|
| Command Injection | **LOW** | Scripts parse trusted YAML/JSON via `yq`/`jq` against repo-internal files. No user-supplied data enters shell commands. Mitigation: use `--arg`/`--raw-output` in jq, avoid `eval`. |
| Path Traversal | **LOW** | Scripts traverse working tree only. No user-supplied paths. `grep` is scoped to repo root. Mitigation: use `git ls-files` or explicit `find .` with prefix checks. |
| Secrets Exposure | **LOW** | `grep` for `story: eNNsNN` patterns is unlikely to match secrets. CI artifact upload (traceability-matrix.json) contains only file paths + story IDs — no code content. Mitigation: verify matrix.json schema excludes source code snippets. |
| CI Workflow Injection | **LOW** | New CI step runs a repo-contained script with `--strict`. No external inputs. Mitigation: pin script path, no `${{ }}` expansion on untrusted context. |
| Malformed Input (YAML/JSON) | **LOW** | Scripts parse internal YAML/JSON files. A malicious commit could craft YAML to cause unexpected `yq`/`jq` behavior. Mitigation: validate schema before processing, fail on parse errors. |
| Skill Injection | **LOW** | gate-trace skill reads JSON artifacts and makes gate decisions. If an attacker could write a forged matrix.json, they could force PASS on uncovered code. Mitigation: gate-trace should validate matrix.json hasn't been hand-edited (timestamp freshness check). |
| Auth Bypass | **NONE** | No authentication or authorization in scope. |
| SQLi / XSS / SSRF / Deserialization | **NONE** | No databases, web rendering, network requests, or deserialization in scope. |

## Risk Level: **LOW**

The e38 epic builds internal development tooling that reads trusted repository files and writes analysis artifacts. All inputs are repo-internal (YAML specs, git-tracked code). No network access, no user-supplied data, no authentication. The primary risks are robustness (malformed YAML, script errors) rather than exploitability.

## Mitigation Guidance

1. **Defensive YAML/JSON parsing:** Validate structure before processing. Fail loudly on parse errors with actionable messages rather than silently producing incorrect matrices.
2. **Output isolation:** Scripts write exclusively under `specs/`. Never modify `skills/`, `scripts/`, `.github/`, or `.cursor/`.
3. **CI artifact hygiene:** `traceability-matrix.json` uploaded as CI artifact should contain file paths and story metadata only — never source code snippets.
4. **Gate integrity:** gate-trace should check that matrix.json was generated (timestamp within session window) rather than hand-written or stale.
5. **Shell hardening:** No `eval`, no `shell=True`, no backtick execution. All variable expansion in grep/sed/yq should use `--` terminators.

## Verdict: **READY TO PROCEED**

No HIGH-severity findings. All identified risks are LOW and addressed by standard defensive practices. No gating issue for build-epic Step 0.
