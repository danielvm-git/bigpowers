# Codex CLI Hook Templates (Wave A)

Shipped under `scripts/hooks/codex/` — copy to user config in Wave B.

## Events

- `PreToolUse`
- `PostToolUse`
- `SessionStart`
- `PermissionRequest`
- `PreCompact`
- `PostCompact`
- `UserPromptSubmit`
- `SubagentStart`
- `SubagentStop`
- `Stop`

## Security

Templates use fixed guard logic only — no dynamic eval.

