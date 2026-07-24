# Impact Assessment — e61s01 (lightweight)

**Date:** 2026-07-24
**Risk score:** 3/10 (LOW)
**Scope:** Adapter-only Wave A — no hub file changes.

## Module purpose

`scripts/adapters/hermes.sh` renders bigpowers skills into Hermes Agent's skills directory and bridges AGENTS.md into `.hermes/config.yaml`.

## Callers

- `scripts/lib/srp-engine.py` / `scripts/sync-skills.sh` (via targets.yaml `skill.adapter: hermes`) — unchanged in Wave A
- `scripts/test-adapters.sh hermes` — smoke test

## Contracts

- `render_skill` + `wire_context` adapter hooks (e37)
- Output: `.hermes/skills/<name>/SKILL.md` with YAML frontmatter
- Hook templates are inert until Wave B install copies them

## Blast radius

| Dependent | Impact |
|-----------|--------|
| sync-skills dispatch | Improved — stub now emits real SKILL.md |
| install.sh / setup.js | None (forbidden Wave A) |
| Other adapters | None — isolated script |

**Verdict:** Proceed without grill-me session.
