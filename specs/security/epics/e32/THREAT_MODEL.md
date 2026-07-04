# Threat Model — e32: MCP Semantic Context Server

**Date:** 2026-07-04  
**Epic:** e32 — MCP Semantic Context Server (13 BCP, 7 stories)  
**Scope:** `bigpowers-mcp/` TypeScript package + `.mcp.json` registration  
**Reviewer:** pre-flight (build-epic Step 0)

## Surface Area

| Component | Type | Trust Boundary |
|-----------|------|----------------|
| `bigpowers-mcp/` MCP server | New TS process (stdio) | Agent client invokes tools; reads repo files |
| `index_skills` / `read_skill` | File read tools | Reads `skills/*/SKILL.md`, `CONVENTIONS.md` |
| `build_skill_graph` | Graph builder | Writes `bigpowers-mcp/graph.jsonl` |
| `get_git_context` (e32s04) | Git subprocess | `git status`, `git log`, `git diff` scoped to repo |
| `validate_skill` | Linter tool | Reads SKILL.md, returns findings |
| `.mcp.json` registration (e32s06) | Config | Spawns `node bigpowers-mcp/build/index.js` |

## Vulnerability Categories Assessed

| Category | Risk | Rationale |
|----------|------|-----------|
| Path Traversal | **MEDIUM** | `read_skill` takes skill name → path join. Malicious client could pass `../../etc/passwd` if not normalized. **Mitigation:** resolve under `skills/` only; reject `..` and absolute paths. |
| Command Injection | **MEDIUM** (e32s04+) | `get_git_context` shells out to git. **Mitigation:** fixed subcommands only; no user-supplied git args; `execFile` with static argv. |
| Secrets Exposure | **MEDIUM** | `get_git_context` diffs may include `.env` if untracked. **Mitigation:** restrict to `git ls-files` paths under `skills/`, `specs/`; denylist `.env*`, `*credentials*`, `*.pem`. |
| Arbitrary File Read | **LOW** | Tools limited to skills/specs/CONVENTIONS. **Mitigation:** allowlist roots in config. |
| Denial of Service | **LOW** | Full catalog parse on each call could be heavy. **Mitigation:** cache index; graph.jsonl warm start. |
| MCP Tool Injection | **LOW** | Forged tool responses if server compromised locally. Out of scope — local dev trust model. |
| Auth Bypass | **NONE** | Local stdio MCP; no network listener in v1. |
| SQLi / XSS / SSRF | **NONE** | No DB, no HTML render, no outbound HTTP in v1. |

## Risk Level: **MEDIUM** (acceptable for local dev tooling with mitigations)

Higher than e38 (read-only shell scripts) because MCP exposes structured tools to agents and e32s04 adds git subprocesses.

## Mitigation Guidance (required in implementation)

1. **Path allowlist:** All file reads via `resolveWithin(root, userPath)` — throw if outside `skills/`, `specs/`, or repo root CONVENTIONS.
2. **Git scope:** `get_git_context` only reports changes under `skills/` and `specs/`; never `git diff` entire repo without path filter.
3. **Secret denylist:** Skip paths matching `.env`, `*.pem`, `*secret*`, `*credentials*` in diff/status output.
4. **No network:** Do not add HTTP fetch tools in e32; defer to separate epic if needed.
5. **Output bounds:** Cap `read_skill` response size (e.g. 512KB); truncate with explicit flag.
6. **graph.jsonl integrity:** Write only under `bigpowers-mcp/`; never modify `skills/` or `specs/` from MCP tools.

## Per-story security tasks

| Story | Requirement |
|-------|-------------|
| e32s01 | Path normalization on `read_skill` name parameter |
| e32s04 | Git allowlist + denylist; security-review before merge |
| e32s06 | `.mcp.json` uses workspace-relative paths only |

## Verdict: **READY TO PROCEED** (e32s01)

e32s01 has no git tools yet — path traversal mitigations required in spike. Re-run threat review at e32s04 gate.
