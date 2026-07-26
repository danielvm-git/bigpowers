# story: e64s01
# Gemini hooks adapter — event docs, templates, adapter completeness (Wave A)

**type:** feat  
**risk:** P2  
**context:** infra  
**bcps:** 3

## Context

Gemini CLI uses `BeforeTool`/`AfterTool` naming (not Claude's `PreToolUse`/`PostToolUse`) and supports 11 hook events. Core skill sync via `gemini.sh` exists; hooks are partially shipped (`session-start`, `run-hook.cmd`) but lack event documentation, a machine-readable manifest, BeforeTool wrapper templates, and adapter validation helpers. Wave A completes the **adapter layer** only — hub install wiring stays in Wave B (`install_gemini`, `install-helpers.js`, `targets.yaml` contracts).

## Requirements

#### ADDED: Gemini hook event catalog

Full documentation of all 11 Gemini CLI hook events with bigpowers shipped/planned hook mapping, config path (`~/.gemini/settings.json`), and example `settings.json` snippet.

#### ADDED: Hook template bundle under extension hooks dir

Source templates: `HOOKS.md`, `hooks-manifest.json`, `settings.json.example`, BeforeTool wrappers for git guardrails / RTK / token-mgmt (passthrough or delegate to repo scripts).

#### ADDED: Adapter completeness in gemini.sh

Functions to list events, validate template presence, and render hooks manifest; callable from `scripts/test-gemini-adapter.sh`.

#### ADDED: sync-render Gemini hook manifest helper

`render_gemini_hooks_manifest()` in `scripts/lib/sync-render.sh` (Gemini-only).

## Acceptance Criteria

```bash
bash scripts/test-adapter-render.sh && echo OK
```

## Out of scope

- `scripts/install.sh` / `install-helpers.js` / `bin/setup.js` hub wiring (Wave B)
- `scripts/targets.yaml` hook contracts (Wave B)
- `scripts/verify-install.sh` matrix rows (Wave B)
- Antigravity `.gemini/antigravity` paths
- Editing generated `.gemini/extensions/bigpowers/skills/` or `commands/` (sync-skills.sh owns those)

## Risks

- Gemini CLI hook JSON shape may drift — wrappers use `.command // .tool_input.command` dual-path (proven in guard-git).
- RTK may lack native Gemini hook mode — template documents optional wiring with passthrough fallback.

## Verification Script

1. Run `bash scripts/test-adapter-render.sh` — expect PASS.
2. Open `.gemini/extensions/bigpowers/hooks/HOOKS.md` — confirm 11 events listed.
3. Run `bash scripts/adapters/gemini.sh` with `--validate-hooks` (via test script) — all required templates present.
