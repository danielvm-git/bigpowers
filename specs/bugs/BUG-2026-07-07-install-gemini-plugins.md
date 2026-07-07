---
bug_id: BUG-2026-07-07-install-gemini-plugins
status: fixed
severity: high
scope: install
title: "install.sh uses legacy .gemini/extensions/ directory instead of config/plugins/"
---

# BUG-2026-07-07-install-gemini-plugins

## Root Cause
Antigravity 2.0 (agy) deprecated the `~/.gemini/extensions/` plugin directory structure in favor of `~/.gemini/config/plugins/`. The `install.sh` script currently symlinks the bigpowers directory into `extensions/`, making the skills invisible to the CLI.

## Fix
Update `GEMINI_EXT_DST` in `scripts/install.sh` to point to `$GEMINI_CONFIG_DIR/config/plugins/bigpowers`.
Update the comment in `install.sh` documenting the Gemini CLI install location.

## Verify
→ verify: `grep "config/plugins/bigpowers" scripts/install.sh`
