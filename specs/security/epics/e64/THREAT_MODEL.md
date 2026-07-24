# e64 Threat Model — Gemini CLI Extensions + Hooks (Wave A)

**Date:** 2026-07-24 | **Assessor:** build-epic Step 0 | **Risk Level:** LOW

## Scope (Wave A — adapter-only)

| Surface | Description |
|---------|-------------|
| `scripts/adapters/gemini.sh` | Hook manifest helpers, template validation (no install wiring) |
| `scripts/lib/sync-render.sh` | `render_gemini_hooks_manifest()` only |
| `.gemini/extensions/bigpowers/hooks/` | Source hook templates + `settings.json.example` (not live settings) |
| `specs/epics/e64-integration-gemini/` | Story spec, tasks, verification artifacts |

**Out of scope (Wave B):** `scripts/install.sh`, `scripts/lib/install-helpers.js`, `bin/setup.js`, `scripts/targets.yaml`, `scripts/verify-install.sh`, live `~/.gemini/settings.json` mutation.

## Threat Assessment

### T1: Hook command injection via settings.json — LOW (Confidence: 9/10)

**Surface:** Wave A ships `settings.json.example` only. Live settings mutation is deferred to Wave B (`install_gemini()` jq merge).

**Exploit scenario:** An attacker with write access to the consumer's `~/.gemini/settings.json` could point hooks at arbitrary commands — but that implies the same privilege as the Gemini CLI user.

**Recommendation:** Wave B must keep hook commands as quoted paths to repo-managed scripts under `unlink_if_managed()` symlinks. Document in `HOOKS.md`; no dynamic user input in hook command strings.

### T2: Symlink targets in hook wrappers — LOW (Confidence: 9/10)

**Surface:** Hook wrappers (`before-tool-git-guard.sh`) resolve `skills/guard-git/scripts/block-dangerous-git.sh` by walking up to repo root (same pattern as `session-start`).

**Existing guard:** `unlink_if_managed()` in Wave B install prevents deleting user-owned hook targets.

**Recommendation:** No Wave A changes needed. Wrappers must never accept hook payload as shell arguments.

### T3: Session-start context injection — LOW (Confidence: 8/10)

**Surface:** `session-start` embeds `project-survey.sh` output into JSON `additionalContext`.

**Exploit scenario:** Malicious repo content could inflate context; not a privilege escalation — bounded by survey script output size.

**Recommendation:** Accept for Wave A. Token-mgmt hook (Wave B wiring) provides mechanical backstop for oversized reads.

### T4: Path traversal in adapter render — NONE (Confidence: 10/10)

**Surface:** `render_skill()` writes to `GEMINI_SKILLS/$IR_NAME/` where `IR_NAME` comes from parsed SKILL.md frontmatter (sync pipeline), not user CLI input at install time.

**Recommendation:** No action.

## Decision

| Category | Risk | Confidence |
|----------|------|------------|
| Command injection | LOW | 9/10 |
| Symlink attacks | LOW | 9/10 |
| Path traversal | NONE | 10/10 |
| Secrets exposure | N/A | — |
| **Overall** | **LOW** | **9/10** |

**Verdict:** CLEAR to proceed. No HIGH findings. Wave B must preserve `unlink_if_managed()` and static hook command paths.
