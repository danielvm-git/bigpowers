# e47 Threat Model — Cross-Tool Skill Distribution

**Date:** 2026-07-05 | **Assessor:** build-epic Step 0 | **Risk Level:** LOW

## Scope

| Story | Surface | Description |
|-------|---------|-------------|
| e47s01 | `scripts/install.sh` | Add `install_pi()` / `uninstall_pi()`, remove `install_opencode()` + `print_opencode_instructions()` |
| e47s02 | `skills/seed-conventions/` | Add optional "local tool wiring" interview step + templates for Cursor/OpenCode project-local files |
| e47s03 | `docs/references/agent-config-files-and-okf.md` | Add skill-catalog vs instruction-only taxonomy; pure documentation |
| e47s04 | `scripts/verify-install.sh` | Manual assertion harness (local only, not CI-wired) |

## Threat Assessment

### T1: Symlink Manipulation — LOW (Confidence: 9/10)

**Surface:** `install_pi()` creates per-skill symlinks `~/.pi/agent/skills/<name>` → `$SKILLS_ROOT/<name>`, symmetric with `install_claude()`.

**Existing guard:** `unlink_if_managed()` only removes symlinks whose readlink target starts with `$REPO_ROOT/`. A user-authored pi skill with a different target is never touched. The `ln -sfn` flag prevents following through existing symlinks. `$SKILLS_ROOT` is derived from `REPO_ROOT` via `cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd` — no user input, no path-traversal vector.

**Exploit scenario:** None viable. An attacker would need write access to the bigpowers install directory to plant a malicious symlink target, which implies they already have code execution at the same privilege level.

**Recommendation:** No changes needed. The existing `unlink_if_managed()` pattern is proven in `install_claude()` and `install_gemini()`.

---

### T2: install_opencode() Removal — LOW (Confidence: 10/10)

**Surface:** `install_opencode()` writes `opencode.json` to `$REPO_ROOT`, which for a global `npm install -g` consumer is inside `node_modules/` — a location OpenCode never reads. No paired `uninstall_opencode()` exists, so there is nothing to strand.

**Exploit scenario:** None. The function is a latent no-op. Removing it cannot create a regression because it never produced a useful outcome.

**Recommendation:** Remove after explicit user confirmation (hard_gate in e47s01). No security risk.

---

### T3: seed-conventions Template Output — LOW (Confidence: 10/10)

**Surface:** e47s02 adds static templates to `REFERENCE.md` and an interview step. The generated `.cursor/rules` symlink and `opencode.json` contain no dynamic user data — only static paths and JSON. No injection surface exists because no user input flows into executable code.

**Exploit scenario:** None. Templates are static strings.

**Recommendation:** No security controls needed for template content.

---

### T4: verify-install.sh — NONE (Confidence: 10/10)

**Surface:** Manual assertion harness that checks symlink/file existence in a scratch directory. Local-only, not CI-wired, no network, no privilege escalation.

**Exploit scenario:** None. Pure read-only assertions.

**Recommendation:** No security concerns.

---

## Decision

| Category | Risk | Confidence |
|----------|------|------------|
| Symlink attacks | LOW | 9/10 |
| Path traversal | LOW | 9/10 |
| Code injection | NONE | 10/10 |
| Auth bypass | N/A | — |
| Secrets exposure | N/A | — |
| **Overall** | **LOW** | **9/10** |

**Verdict:** CLEAR to proceed. No HIGH findings. No action items.

Mitigation is already in place: `unlink_if_managed()` prevents unintended symlink deletion; `set -euo pipefail` at script top catches unexpected errors; static templates carry no injection risk.
