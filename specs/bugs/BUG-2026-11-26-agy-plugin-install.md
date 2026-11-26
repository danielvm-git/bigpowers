---
bug_id: BUG-2026-11-26-agy-plugin-install
status: resolved
severity: high
scope: installer
title: Antigravity global installer targets undiscoverable ~/.gemini/antigravity-cli/skills instead of ~/.gemini/config/plugins/bigpowers
---

# BUG-2026-11-26-agy-plugin-install

## Symptom
Typing `/fix-bug` (or any bigpowers skill slash command) in Antigravity does not show any bigpowers skills, even after running `bigpowers setup` or `scripts/install.sh` for Antigravity.

## Root Cause
Antigravity discovers global customizations under `~/.gemini/config/`:
- Global skills: `~/.gemini/config/skills/<name>/SKILL.md`
- Global plugins: `~/.gemini/config/plugins/<plugin>/` (containing `plugin.json` and `skills/<name>/SKILL.md`)

`bigpowers` instead installed Antigravity skills globally into `~/.gemini/antigravity-cli/skills/` (`bin/setup.js`, `scripts/lib/install-helpers.js`, `scripts/lib/install-targets-b.sh`), which Antigravity only uses for CLI runtime state and `settings.json` — never for skill discovery.

## Fix Approach (Option 2: Native Antigravity Plugin)
1. Emit `.bigpowers/rendered/antigravity/plugin.json` during `scripts/sync-skills.sh` (before the `--distribute-only` exit) so `.bigpowers/rendered/antigravity/` is a valid native Antigravity plugin bundle (`plugin.json` + `skills/`).
2. Update the global Antigravity target in `scripts/lib/install-targets-b.sh`, `scripts/lib/install-helpers.js`, `bin/setup.js`, and `scripts/install.sh` to symlink `.bigpowers/rendered/antigravity` → `~/.gemini/config/plugins/bigpowers`.
3. Clean up any legacy bigpowers-managed symlinks under `~/.gemini/antigravity-cli/skills/` on install and uninstall so existing users migrate cleanly without stale links.
4. Keep local workspace install (`<cwd>/.agents/skills`) and the Gemini extension isolation guard (`verify-install.sh`) intact.

## Verify
- `bash tests/test-agy-plugin-install.sh`
- `bash scripts/verify-install.sh`
- `bash scripts/test-install-hub.sh`
- `bash tests/test-render-targets-not-discoverable.sh`
- `npm run compliance && bash scripts/run-verification-gates.sh`
