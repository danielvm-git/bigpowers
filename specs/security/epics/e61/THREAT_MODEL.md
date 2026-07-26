# Threat Model — Epic e61: Integration: Hermes Agent — Skills + 3 Hook Systems

**Date:** 2026-07-24
**Risk Level:** MEDIUM
**Epic Scope (Wave A):** Expand `scripts/adapters/hermes.sh` to render SkillIR into `.hermes/skills/` and ship hook templates under `scripts/hooks/hermes/` (gateway, shell, plugin). Hub wiring (`install.sh`, `targets.yaml`, `bin/setup.js`) is Wave B.

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| `scripts/adapters/hermes.sh` | Bash adapter | Writes `.hermes/skills/<name>/SKILL.md` from SkillIR JSON on stdin |
| `scripts/hooks/hermes/gateway/*` | Python templates | Gateway hook manifest + `handler.py` (user copies to `~/.hermes/hooks/`) |
| `scripts/hooks/hermes/shell/*` | Shell templates | Subprocess hooks declared in `~/.hermes/config.yaml` |
| `scripts/hooks/hermes/plugin/*` | Python templates | Plugin `register(ctx)` stubs for CLI + gateway |
| `.hermes/config.yaml` (bridge) | Config | `instructions:` key bridged from AGENTS.md via `wire_context` |
| Hermes hook dispatcher | External runtime | Runs user hooks with full user credentials ([Hermes docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks)) |

## Vulnerability Assessment

### 1. Command Injection in Shell Hook Templates

**Category:** Command injection (CWE-78)
**Severity:** MEDIUM
**Risk:** Shell hooks run via `shlex.split` with user credentials. A compromised `config.yaml` `hooks:` block could execute arbitrary commands.
**Mitigation:** Templates are read-only sources in-repo; Wave B install must symlink/copy, not eval user paths. Document that `hooks:` is privileged config. Shell template uses fixed guard logic, no dynamic eval.

### 2. Path Traversal in Adapter Output

**Category:** Path traversal (CWE-22)
**Severity:** MEDIUM
**Risk:** `render_skill` writes under `.hermes/skills/$IR_NAME`. Malicious SkillIR `name` with `../` could escape output dir.
**Mitigation:** Reject or sanitize `IR_NAME` containing `/`, `..`, or leading `-`. Mirror pi/cursor pattern where name comes from parsed SKILL.md frontmatter (trusted source tree).

### 3. Python Handler Code Execution

**Category:** Unsafe code execution
**Severity:** LOW (Wave A)
**Risk:** Gateway/plugin hook templates are Python executed by Hermes at runtime.
**Mitigation:** Wave A ships minimal observer stubs only — no network, no subprocess, no file writes outside logging. User customization is explicit opt-in when copying to `~/.hermes/hooks/`.

### 4. Secrets in SKILL.md / Config Bridge

**Category:** Information disclosure (CWE-200)
**Severity:** LOW
**Risk:** Skill body or AGENTS.md bridge could propagate secrets into `.hermes/`.
**Mitigation:** Same as e37 — skill sources are repo-controlled; no credential placeholders in templates.

### 5. Supply Chain — Hermes Agent Upstream

**Category:** Supply chain
**Severity:** LOW
**Risk:** Hook event names and config schema may drift from NousResearch/hermes-agent.
**Mitigation:** Discovery mandate cites [Hermes hooks docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks); Wave B adds install verification against live schema.

## Risk Summary

| Category | Count | Highest |
|----------|-------|---------|
| Command injection | 1 | MEDIUM |
| Path traversal | 1 | MEDIUM |
| Code execution | 1 | LOW |
| Info disclosure | 1 | LOW |
| Supply chain | 1 | LOW |

**Overall: MEDIUM** — primary concerns are shell-hook privilege boundary and adapter path safety; mitigated by trusted sources and name sanitization.

## Mitigation Guidance

1. Sanitize `IR_NAME` in `render_skill` before mkdir/write.
2. Keep shell hook templates minimal; block decisions only via documented JSON shapes.
3. Run `bash scripts/test-adapter-render.sh` and `bash scripts/test-adapters.sh hermes` after adapter edits.
4. Wave B: wire install to copy templates; never auto-enable hooks without user consent (`hooks_auto_accept: false` default).
5. Treat `~/.hermes/config.yaml` `hooks:` block as privileged — review like CI config.
