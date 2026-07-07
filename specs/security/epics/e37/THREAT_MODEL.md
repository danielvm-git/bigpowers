# Threat Model — Epic e37: Reach — Universal Agent Portability

**Date:** 2026-07-07
**Risk Level:** MEDIUM
**Epic Scope:** AGENTS.md context spine, `scripts/targets.yaml` integration registry, adapter dispatch in `sync-skills.sh`, OSS wave targets, optional Codex wiring.

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| `docs/templates/AGENTS.md` | Template | Seeded into consumer projects — agent-readable instructions |
| `scripts/targets.yaml` | Config registry | Declares adapter paths, symlink/copy modes, contract matrix |
| `scripts/adapters/*.sh` | Bash adapters | Write symlinks, copies, config bridges into consumer project dirs |
| `scripts/generate-context-bundle.sh` | Bash orchestrator | Sources adapter scripts; wires context derivatives from AGENTS.md |
| `scripts/sync-skills.sh` | Bash orchestrator | Dispatches skill artifacts per target registry |
| `scripts/verify-install.sh` | Verification | Asserts per-target contracts from targets.yaml |
| `skills/seed-conventions/SKILL.md` | Skill | Emits AGENTS.md, symlinks, opencode.json, optional Codex/Aider wiring |
| `scripts/install.sh` | Installer | Global `~/.codex/` symlink (optional wave) |
| Consumer project dirs | Filesystem | `.cursor/`, `.gemini/`, `.pi/`, `.aider.conf.yml`, `.codex/` |

## Vulnerability Assessment

### 1. Symlink / Path Traversal in Adapters

**Category:** Path traversal / unsafe file write
**Severity:** MEDIUM
**Risk:** Adapters create symlinks and copy files based on `targets.yaml` paths. A compromised or malformed registry entry could write outside the project root.
**Mitigation:** `wire_context_mode` in `scripts/lib/context-wire.sh` resolves paths relative to repo root; `validate-targets-yaml.sh` schema-checks registry before dispatch. Adapters must not accept user-controlled path segments.

### 2. Command Injection via Adapter Scripts

**Category:** Command injection
**Severity:** LOW
**Risk:** Adapter shell scripts source each other and invoke filesystem operations. User input should not reach `eval` or unquoted shell expansion.
**Mitigation:** Adapters use `set -euo pipefail`; paths are quoted; no user input in adapter dispatch — only registry-defined ids.

### 3. Supply Chain — OSS Target Documentation

**Category:** Social engineering / misleading install guidance
**Severity:** LOW
**Risk:** `using-bigpowers` documents third-party tools (Goose, Continue, etc.). Stale or incorrect repo URLs could point users to wrong packages.
**Mitigation:** Verify commands in epic stories grep for canonical org names (e.g. `Aider-AI/aider`). Manual UAT for live agent sessions is explicitly out of scope.

### 4. Secrets Exposure in AGENTS.md Template

**Category:** Information disclosure
**Severity:** LOW
**Risk:** AGENTS.md is the single context spine copied/symlinked across tools. Accidental inclusion of secrets in the template would propagate to all derivatives.
**Mitigation:** Template contains only commands and conventions — no credential placeholders. Preflight chain uses public npm/bash scripts only.

### 5. Windows Copy-Fallback Integrity

**Category:** Configuration drift
**Severity:** LOW
**Risk:** Symlink mode falls back to copy on Windows; copies can stale relative to AGENTS.md source.
**Mitigation:** `generate-context-bundle.sh` re-wires on each run; `verify-install.sh --matrix` asserts per-target contracts.

### 6. Optional Codex Global Install

**Category:** Filesystem write outside project
**Severity:** LOW
**Risk:** `install.sh` creates `~/.codex/` starter symlink — writes to user home directory.
**Mitigation:** Opt-in only (e37s14–s16 optional wave); dry-run documented; user must run install explicitly.

## Risk Summary

| Category | Count | Highest |
|----------|-------|---------|
| Path traversal | 1 | MEDIUM |
| Command injection | 1 | LOW |
| Supply chain | 1 | LOW |
| Info disclosure | 1 | LOW |
| Config drift | 1 | LOW |
| Filesystem (home) | 1 | LOW |

**Overall: MEDIUM** — primary concern is adapter path safety; mitigated by schema validation and repo-relative resolution.

## Mitigation Guidance

1. Run `bash scripts/validate-targets-yaml.sh` before any registry change.
2. Run `bash scripts/test-adapters.sh` and `bash scripts/verify-install.sh --matrix` after adapter edits.
3. Never add user-interpolated paths to `targets.yaml` output fields.
4. Keep AGENTS.md template free of secrets and environment-specific values.
5. Treat optional Codex global install as explicit opt-in with dry-run preview.
