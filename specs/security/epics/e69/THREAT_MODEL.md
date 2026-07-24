# Threat Model — Epic e69: Integration: MiMo Code — Skills + Plugins (No Hooks)

**Date:** 2026-07-24
**Risk Level:** LOW
**Epic Scope:** Wave A adapter-only — `scripts/adapters/mimo.sh` renders SKILL.md files to `.mimocode/skills/`; context wiring via AGENTS.md symlink. No hooks, no targets.yaml registry (Wave B).

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| `scripts/adapters/mimo.sh` | Bash adapter | Writes `.mimocode/skills/<name>/SKILL.md` from SkillIR globals or JSON stdin |
| `.mimocode/skills/` | Consumer project dir | MiMo Code skill discovery path (XiaomiMiMo/MiMo-Code) |
| `.mimocode/mimocode.jsonc` | Config (Wave B+) | MiMo Code config — not written in Wave A |
| `scripts/lib/context-wire.sh` | Shared library | Symlink/copy AGENTS.md derivative |

## Vulnerability Assessment

### 1. Path Traversal in render_skill

**Category:** Path traversal / unsafe file write  
**Severity:** LOW  
**Risk:** Malformed `IR_NAME` could write outside `.mimocode/skills/` if unvalidated.  
**Mitigation:** Adapter uses fixed base `${MIMO_SKILLS:-.mimocode/skills}`; skill names come from sync-skills IR pipeline, not user CLI input. No path segments from external input in Wave A.

### 2. Command Injection via Adapter Shell

**Category:** Command injection  
**Severity:** LOW  
**Risk:** JSON stdin parsed with `jq`; description escaped for YAML frontmatter.  
**Mitigation:** No `eval`; quoted paths; follows pi.sh/cursor.sh adapter pattern audited in e37.

### 3. Supply Chain — MiMo Code Documentation

**Category:** Social engineering / misleading install guidance  
**Severity:** LOW  
**Risk:** Epic references XiaomiMiMo/MiMo-Code (12K+ stars). Stale URLs in future docs could misdirect users.  
**Mitigation:** Registry row and install wiring deferred to Wave B; epic capsule pins canonical repo.

### 4. Symlink Context Wiring

**Category:** Path traversal  
**Severity:** LOW  
**Risk:** `wire_context` creates symlinks relative to repo root via shared `context-wire.sh`.  
**Mitigation:** Repo-relative resolution; idempotent wire tested in adapter smoke verify.

## Risk Summary

| Category | Count | Highest |
|----------|-------|---------|
| Path traversal | 2 | LOW |
| Command injection | 1 | LOW |
| Supply chain | 1 | LOW |

**Overall: LOW** — greenfield adapter mirroring proven pi.sh pattern; no hooks or external API calls.

## Mitigation Guidance

1. Keep Wave A scope adapter-only — do not touch `targets.yaml`, `install.sh`, or `verify-install.sh` until Wave B.
2. Verify `render_skill` and `wire_context` via standalone smoke commands (no registry row required).
3. Run `bash scripts/validate-targets-yaml.sh` in Wave B before adding mimo target row.
