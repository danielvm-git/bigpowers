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

## Out of scope

- Codex wiring (e37s14)
- Aider `.aider.conf.yml` bridge (e37s03)
- Integration registry rows (e37s05)

## References

- docs/templates/AGENTS.md (Reach Template — created by this story)
- specs/adr/0007-agents-md-spine-context-derivatives.md
- specs/tech-architecture/e37-TEST_PLAN_LATEST.md (SC-e37s01-P1-*)
