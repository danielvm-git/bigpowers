# Threat Model — e74 Antigravity CLI Integration

**Epic:** e74 — Integration: Antigravity CLI  
**Story scope:** Wave A (adapter research + `agy.sh` stub only)  
**Date:** 2026-07-24  
**Risk level:** Low (no install wiring, no runtime hook execution in Wave A)

## Surface area

| Component | Wave A touch | Notes |
|-----------|--------------|-------|
| `scripts/adapters/agy.sh` | Yes | Context symlink stub; `render_skill` stub only |
| `specs/epics/e74-integration-antigravity/*` | Yes | Research + plan artifacts |
| Install hub (`install.sh`, `setup.js`, `targets.yaml`) | **No** | Deferred to Wave B |
| Antigravity runtime (`agy` binary) | **No** | Proprietary beta; not invoked in CI |

## Antigravity config paths (research — not wired in Wave A)

| Artifact | Global | Workspace |
|----------|--------|-----------|
| Skills | `~/.gemini/antigravity-cli/skills/` | `.agents/skills/` |
| Hooks | `~/.gemini/config/hooks.json` | `.agents/hooks.json` |
| Rules | `~/.gemini/GEMINI.md` | `AGENTS.md` + `.agents/rules/` |
| MCP | `~/.gemini/config/mcp_config.json` | `.agents/mcp_config.json` |
| Permissions | `~/.gemini/antigravity-cli/settings.json` | — |

Sources: [Mete Atamel hooks post](https://atamel.dev/posts/2026/07-16_where_agy_hooks/), [antigravity-cli repo](https://github.com/google-antigravity/antigravity-cli).

## Vulnerability categories

| Category | Applicability | Mitigation (Wave B+) |
|----------|---------------|----------------------|
| Command injection (CWE-78) | Hooks run shell scripts from `hooks.json` | Absolute paths only; validate hook scripts before install |
| Path traversal (CWE-22) | Symlink/copy context wiring | Reuse `context-wire.sh` idempotent guards |
| Secrets exposure (CWE-798) | Global config under `~/.gemini/` | Never copy tokens into repo; document opt-in |
| Unsafe deserialization | Low — JSON config only | Schema-validate hook payloads in Wave B |
| Auth bypass | N/A Wave A | `agy` uses Google SSO — out of bigpowers scope |

## Wave A mitigations

1. **Scope fence:** No edits to install hub or `.gemini/**` generated artifacts.
2. **Stub-only adapter:** `render_skill` creates directories only when env vars set; no network or auth.
3. **Shared context-wire:** Reuse proven `wire_context_mode symlink` from e37 — no custom path logic.
4. **Research citations:** External paths documented in specs only — not hardcoded into installer.

## Risk verdict

**Low** — documentation and adapter stub with no runtime integration. Proceed to Wave A implementation; re-run threat model before Wave B install wiring.
