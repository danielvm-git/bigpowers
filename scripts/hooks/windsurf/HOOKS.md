# Windsurf Hook Templates (Wave A)

Shipped under `scripts/hooks/windsurf/` — copy to user config in Wave B.

## Events

- `pre_read_code`
- `post_read_code`
- `pre_write_code`
- `post_write_code`
- `pre_run_command`
- `post_run_command`
- `pre_mcp_tool_use`
- `post_mcp_tool_use`
- `pre_user_prompt`
- `post_cascade_response`
- `post_cascade_response_with_transcript`
- `post_setup_worktree`

## Security

Templates use fixed guard logic only — no dynamic eval.

