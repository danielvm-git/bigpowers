# Threat Model — Epic e37: BCP Plus Counting

**Date:** 2026-07-05
**Risk Level:** LOW
**Epic Scope:** Evolve story sizing from 3D BCP to 13D BCP Plus; integrate big-counter optional tool; update affected skills.

## Surface Area

| Component | Type | Exposure |
|-----------|------|----------|
| `skills/build-epic/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/plan-work/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/plan-release/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/develop-tdd/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/security-review/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/wire-observability/SKILL.md` | Markdown skill | Internal — agent reads only |
| `skills/setup-environment/SKILL.md` | Markdown skill | Internal — agent reads only |
| `docs/references/bcp-plus.md` | Reference doc | Internal — documentation |
| `docs/references/bcp.md` | Reference doc | Internal — documentation (cross-link) |
| `specs/templates/story-template.md` | Template | Internal — spec generation |
| `specs/state.yaml` | Runtime state | Internal — YAML schema extension |
| `scripts/record-cycle-time.sh` | Bash script | Internal — metrics recording |
| `CLAUDE.md` | Config | Internal — agent instructions |
| `big-counter` (optional) | External tool | pip/npm install — trusted PyPI/npm registry |

## Vulnerability Assessment

### 1. Dependency Supply Chain (big-counter)

**Category:** Supply chain
**Severity:** LOW
**Risk:** The `big-counter` tool is an optional external dependency. If installed from a compromised source, it could inject malicious code into the agent's execution context.
**Mitigation:** Install only from trusted registries (PyPI or npm). The skill text should specify `pip install big-counter` or `npm install -g big-counter` from official registries. No custom URLs or third-party mirrors.

### 2. YAML Schema Injection

**Category:** Configuration manipulation
**Severity:** LOW
**Risk:** Extending `specs/state.yaml` with `bcp_plus` fields adds new keys. A malformed YAML could theoretically cause parser issues, but YAML is a declarative format read by trusted scripts — no code execution path.
**Mitigation:** Validate with existing `python3 scripts/yaml-tools.py validate-file specs/state.yaml`. The BCP Plus fields are numeric only (integer totals).

### 3. SKILL.md Content Poisoning

**Category:** Prompt injection (theoretical)
**Severity:** LOW
**Risk:** Adding BCP Plus references to SKILL.md files could theoretically include malicious instructions if the source files were compromised. However, all edits are done by the agent under user supervision.
**Mitigation:** All SKILL.md changes go through sync-skills.sh validation. No untrusted external content is injected.

### 4. Cross-Skill Inconsistency

**Category:** Logic flaw
**Severity:** LOW
**Risk:** If one skill emits BCP Plus but another doesn't consume it, the sizing pipeline breaks silently. This is a correctness risk, not a security risk.
**Mitigation:** Verification grep commands in each task ensure each skill references `bcp_plus`. The traceability gate catches untagged stories.

## Risk Summary

| Category | Count | Max Severity |
|----------|-------|-------------|
| Supply chain | 1 | LOW |
| Configuration | 1 | LOW |
| Prompt injection | 1 | LOW |
| Logic | 1 | LOW |

## Recommendation

**CLEAR — No blocking findings.** Proceed with the build cycle. All risks are LOW. The primary watchpoint is the optional `big-counter` dependency — the install instructions should reference only trusted registries. No code executes network-facing endpoints; no user data is processed; no authentication boundaries exist in scope.

## Verification

- [ ] `big-counter` install instructions in `setup-environment` reference PyPI/npm only
- [ ] `bcp_plus` YAML fields are integer-only in schema validation
- [ ] All SKILL.md changes pass `sync-skills.sh` validation
