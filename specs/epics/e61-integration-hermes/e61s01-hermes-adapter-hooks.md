# e61s01: Hermes adapter + hook templates (Wave A)

<!-- story: e61s01 -->

Expand the e37s10 Hermes adapter stub to render SkillIR into `.hermes/skills/<name>/SKILL.md` (matching pi/cursor adapters) and add read-only hook templates for Hermes' three hook systems. Hub install wiring is deferred to Wave B.

## Requirements

### ADDED

- `render_skill` in `scripts/adapters/hermes.sh` MUST emit a valid Hermes `SKILL.md` from SkillIR JSON on stdin (name, optional model, description, body frontmatter).
- `scripts/hooks/hermes/gateway/` MUST ship a gateway hook template (`HOOK.yaml` + `handler.py`) per [Hermes gateway hooks](https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks).
- `scripts/hooks/hermes/shell/` MUST ship a shell hook script plus an example `hooks:` config snippet for `pre_tool_call` blocking.
- `scripts/hooks/hermes/plugin/` MUST ship a minimal Python plugin stub using `ctx.register_hook()`.
- `scripts/test-hermes-adapter.sh` MUST regression-test stdin render and template presence.

## Out of scope (Wave B)

- `scripts/install.sh`, `bin/setup.js`, `scripts/lib/install-helpers.js` hub wiring
- `scripts/targets.yaml` or `scripts/verify-install.sh` changes
- Auto-installing hooks into `~/.hermes/` on `bigpowers setup`

## Acceptance

```bash
bash scripts/test-hermes-adapter.sh &&
bash scripts/test-adapters.sh hermes &&
echo OK
```
