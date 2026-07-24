# Research — Antigravity CLI (agy)

<!-- story: e74s01 -->

**Repo:** [google-antigravity/antigravity-cli](https://github.com/google-antigravity/antigravity-cli)  
**Stars:** ~1.7K (2026-07-24)  
**Latest release:** 1.1.5 (2026-07-21)  
**Binary:** `agy`

## Summary

Antigravity CLI is Google's terminal coding assistant sharing the Antigravity 2.0 agent engine. Documentation is minimal; community migration guides (Gemini CLI → agy) fill gaps. bigpowers Wave A captures paths and hook shape for a future install adapter — no runtime wiring yet.

## Config layout

```
~/.gemini/
├── GEMINI.md                      # Global rules
├── config/
│   ├── hooks.json                 # Global hooks (Claude-Code-like matcher shape)
│   └── mcp_config.json            # Global MCP
├── antigravity-cli/
│   ├── skills/                    # Global agent skills
│   └── settings.json              # permissions.allow|ask|deny
└── antigravity/                   # Antigravity 2.0 GUI cache (shared engine)

<workspace>/
└── .agents/
    ├── hooks.json
    ├── mcp_config.json
    ├── rules/
    ├── skills/
    └── workflows/
```

**Context file:** workspace uses root `AGENTS.md` (Gemini CLI used `GEMINI.md`). bigpowers `agy` target (e37s09) symlinks `CLAUDE.md` → `AGENTS.md` via adapter — same pattern as `pi`/`omp`.

## Hooks (5 core events)

Consolidated from legacy Gemini CLI hook set:

| Event | Matcher | Use |
|-------|---------|-----|
| `PreToolUse` | Yes | Block/allow tool calls before execution |
| `PostToolUse` | Yes | Audit after tool runs |
| `PreInvocation` | Yes | Before LLM call |
| `PostInvocation` | Yes | After LLM response |
| `Stop` | No | Session end cleanup |

Hook scripts must use **absolute paths** in `hooks.json`; relative paths fail with exit 127. Scripts read JSON from stdin and write decision JSON to stdout; non-zero exit can bypass guardrails.

## Skills

- Workspace: `.agents/skills/<name>/` (SKILL.md or equivalent)
- Global: `~/.gemini/antigravity-cli/skills/`
- No separate slash-command TOML — commands exposed via skills

## MCP

Standalone JSON files (not embedded in `settings.json`):

- Global: `~/.gemini/config/mcp_config.json`
- Workspace: `.agents/mcp_config.json`

## Unknown / deferred (Wave B)

- Exact SKILL.md frontmatter schema agy expects
- Plugin bundle format for subagents
- Whether bigpowers hooks map 1:1 to PreToolUse matcher syntax
- CI/runtime verification (proprietary beta — opt_in tier)

## Prior art in bigpowers

- e37s09: `agy` registry row in `targets.yaml`, tier `opt_in`, context symlink to `CLAUDE.md`
- e37: `scripts/adapters/agy.sh` stub with `wire_context` only
- `bin/setup.js`: lists Antigravity in tool picker (Wave B wiring — **out of scope Wave A**)

## References

1. https://github.com/google-antigravity/antigravity-cli  
2. https://atamel.dev/posts/2026/07-16_where_agy_hooks/  
3. https://tanaikech.github.io/2026/06/26/a-developers-guide-to-agent-hooks-in-antigravity-cli/  
4. https://rulesync.dyoshikawa.com/guide/geminicli-to-antigravity-cli.html
