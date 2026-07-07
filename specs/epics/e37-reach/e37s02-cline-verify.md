# story: e37s02
# verify-install.sh + docs — Cline native AGENTS.md verification

## Acceptance Criteria

Given a bigpowers-seeded project with AGENTS.md at root
When a Cline user follows the using-bigpowers Cline section
Then verify-install.sh asserts AGENTS.md exists and is readable by Cline
And using-bigpowers documents Cline as native AGENTS.md support (no adapter required)

