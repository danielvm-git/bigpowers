# story: e37s01
# seed-conventions — unified AGENTS.md template with e51 Preflight + multi-agent header

## Acceptance Criteria

Given a fresh project being seeded
When seed-conventions runs
Then AGENTS.md is emitted from docs/templates/AGENTS.md containing the e51 Preflight command row
And CLAUDE.md is created as a symlink to AGENTS.md (not a copy)
And opencode.json instructions: ["AGENTS.md"] is present
And the multi-agent preamble names active OSS tools without Codex-only title
And opting out leaves standard seed output unchanged

