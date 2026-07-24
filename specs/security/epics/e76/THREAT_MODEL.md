# Threat Model — Epic e76: Integration: ZCode — Skills + Plugin Hooks

**Date:** 2026-07-24
**Risk Level:** LOW (Wave A adapter-only)
**Epic Scope:** Greenfield ZCode adapter (`scripts/adapters/zcode.sh`), skills at `~/.zcode/skills/`, context at `~/.zcode/AGENTS.md`. Wave B will wire install hub + `targets.yaml`.

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| `scripts/adapters/zcode.sh` | Bash adapter | Writes SKILL.md under `~/.zcode/skills/`; wires AGENTS.md to `~/.zcode/AGENTS.md` |
| `~/.zcode/skills/` | User home dir | Global skill install path per ZCode docs |
| `~/.zcode/AGENTS.md` | User home config | Context derivative from project AGENTS.md |
| ZCode plugin hooks | Plugin-scoped | Out of Wave A scope — event names unknown |

## Vulnerability Assessment

### 1. Path Traversal via IR_NAME

**Category:** Path traversal / unsafe file write
**Severity:** LOW
**Risk:** Malformed SkillIR `name` could escape the skills directory if unvalidated.
**Mitigation:** Adapter writes only under `${ZCODE_SKILLS}/${IR_NAME}/SKILL.md`; Wave B registry validation; no user-controlled path segments in Wave A.

### 2. Home Directory Writes

**Category:** Filesystem write outside project
**Severity:** LOW
**Risk:** `wire_context` symlinks/copies into `~/.zcode/AGENTS.md`.
**Mitigation:** Expected for global agent tools (same pattern as Codex `~/.codex/`); opt-in via install in Wave B; test overrides use `ZCODE_SKILLS` / temp dirs.

### 3. Command Injection in Adapter

**Category:** Command injection
**Severity:** LOW
**Risk:** Shell adapter sources shared libs and writes files from IR globals.
**Mitigation:** Quoted paths; no `eval`; IR fields from sync pipeline only — not raw CLI args in Wave A.

### 4. Plugin Hook Surface (Deferred)

**Category:** Hook event injection
**Severity:** UNKNOWN
**Risk:** ZCode hooks are plugin-scoped with unknown event names.
**Mitigation:** Deferred to Wave B+ after research; no hook templates in Wave A.

## Risk Summary

| Category | Count | Highest |
|----------|-------|---------|
| Path traversal | 1 | LOW |
| Home dir writes | 1 | LOW |
| Command injection | 1 | LOW |
| Hook injection | 1 | UNKNOWN (deferred) |

**Overall: LOW** for Wave A — single adapter file with repo-relative test overrides.

## Mitigation Guidance

1. Wave A verify uses `ZCODE_SKILLS` temp override — never assert against live `~/.zcode/` in CI.
2. Wave B must add `targets.yaml` row + `validate-targets-yaml.sh` before hub dispatch.
3. Plugin hooks require threat-model update when event names are documented.
