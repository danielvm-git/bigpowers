# Qwen Code Hook Templates (Wave A)

Shipped under `scripts/hooks/qwen/` — copy to user config in Wave B.

## Events

- `PreToolUse`
- `PostToolUse`
- `PostToolUseFailure`
- `UserPromptSubmit`
- `SessionStart`
- `SessionEnd`
- `Stop`
- `SubagentStart`
- `SubagentStop`
- `PreCompact`
- `PostCompact`
- `Notification`
- `PermissionRequest`
- `TodoCreated`
- `TodoCompleted`
- `StopFailure`

## Security

Templates use fixed guard logic only — no dynamic eval.

