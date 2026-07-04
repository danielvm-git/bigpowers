# Security Review — e32: bigpowers-mcp semantic context server

## Scope Resolution
Scanned changes: `feat/e32-mcp-context-server` — `git diff main...HEAD`
Files changed: `bigpowers-mcp/` (new TS MCP server), `.mcp.json`, docs, specs
Languages: TypeScript, JSON, Markdown, YAML

## Vulnerability Assessment

| Category | Finding | Severity | Mitigation |
|----------|---------|----------|------------|
| Path Traversal | `read_skill` accepts skill name param | MEDIUM | `resolveWithin()` + reject `..` — implemented in `src/lib/paths.ts` |
| Command Injection | `get_git_context` shells out to git | MEDIUM | Fixed argv via `execFileSync`; scoped to `skills/` + `specs/` |
| Secrets Exposure | git diff may include secrets | MEDIUM | Denylist `.env*`, `*.pem`, `*credentials*` in `git-context.ts` |
| Arbitrary File Read | MCP tools read repo files | LOW | Allowlist: skills/, specs/ only |
| Auth Bypass | Local stdio MCP | NONE | No network listener |

Threat model: `specs/security/epics/e32/THREAT_MODEL.md` (pre-flight, 2026-07-04)

## False-Positive Filtering
- Compiled `build/` output is generated from reviewed source — no manual edits
- `.mcp.json` uses workspace-relative paths only (no absolute home paths)

## Verdict
**PASS** — MEDIUM risks mitigated per threat model. No unresolved HIGH findings. Re-review at e32s04 scope was satisfied in this branch (git tool included with allowlist).
