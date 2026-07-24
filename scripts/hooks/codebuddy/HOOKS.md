# CodeBuddy Hook Templates (Wave A)

Shipped under `scripts/hooks/codebuddy/` — copy to user config in Wave B.

## Events

- `PreToolUse`
- `PostToolUse`
- `PostToolUseFailure`
- `SessionStart`
- `SessionEnd`
- `Stop`
- `SubagentStart`
- `SubagentStop`
- `UserPromptSubmit`
- `Notification`
- `PermissionRequest`
- `PreCompact`
- `PostCompact`

## Security

Templates use fixed guard logic only — no dynamic eval.

