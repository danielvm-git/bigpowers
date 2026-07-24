# Gemini CLI Hook Events — bigpowers Extension

**Config path:** `~/.gemini/settings.json` (global) or `.gemini/settings.json` (project)  
**Hook scripts (installed):** `~/.gemini/hooks/` — symlinked from this directory in Wave B via `install_gemini()`  
**Naming:** Gemini uses `BeforeTool`/`AfterTool` (not Claude's `PreToolUse`/`PostToolUse`).

## All 11 events

| Event | Fires when | bigpowers status |
|-------|------------|------------------|
| `BeforeTool` | Before a tool executes | **Shipped** — git guard, RTK, token-mgmt wrappers |
| `AfterTool` | After a tool completes | Documented — no default hook |
| `BeforeAgent` | Before agent loop iteration | Documented — no default hook |
| `AfterAgent` | After agent loop iteration | Documented — no default hook |
| `BeforeModel` | Before model call | Documented — no default hook |
| `BeforeToolSelection` | Before tool selection | Documented — no default hook |
| `AfterModel` | After model response | Documented — no default hook |
| `SessionStart` | Session startup / clear / compact | **Shipped** — `session-start` |
| `SessionEnd` | Session ends | Documented — no default hook |
| `Notification` | User notification | Documented — no default hook |
| `PreCompress` | Before context compression | Documented — no default hook |

## Shipped templates (this directory)

| Script | Event | Matcher | Purpose |
|--------|-------|---------|---------|
| `session-start` | SessionStart | `startup\|clear\|compact` | Project survey + using-bigpowers bootstrap |
| `run-hook.cmd` | (polyglot launcher) | — | Windows + Unix hook runner |
| `before-tool-git-guard.sh` | BeforeTool | `run_shell_command` | Delegates to `guard-git` with `GIT_GUARDRAILS_MODE=gemini` |
| `before-tool-rtk.sh` | BeforeTool | `run_shell_command` | RTK passthrough when installed (optional) |
| `before-tool-token-mgmt.sh` | BeforeTool | `read_file`, `glob`, `run_shell_command` | Token backstop (optional) |

See `settings.json.example` for wiring snippets. Machine-readable list: `hooks-manifest.json`.

## Wave B (not in Wave A)

Hub install (`scripts/install.sh` → `install_gemini()`) symlinks these scripts to `~/.gemini/hooks/` and merges hook entries into `~/.gemini/settings.json`. Do not edit hub files during Wave A.

## Verify locally

```bash
bash scripts/test-gemini-adapter.sh
```
