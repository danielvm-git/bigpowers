## Target
`scripts/sync-skills.sh`, `scripts/install.sh`, `seed-conventions/SKILL.md`

## Dependents ([many])
- `scripts/sync-skills.sh`: Used by almost all documentation and planning artifacts to propagate changes.
- `scripts/install.sh`: The primary entry point for users to install bigpowers.
- `seed-conventions/SKILL.md`: Used to bootstrap new projects.

## Affected Stories
- Story [v2.8.0]: Generate integration with OpenCode (New story)

## Test Coverage
- `npm run compliance`: Runs Gherkin tests.
- Gap: No automated tests for `sync-skills.sh` or `install.sh` side effects (filesystem changes) exist in the repo currently, they are verified manually.

## Risk: Medium
Changes to core scripts have a broad impact but are conceptually simple (adding file generation). Risk is mitigated by the fact that these are bash scripts and can be easily verified by running them and checking the output.

## Recommended action
Proceed with planning. Ensure `sync-skills.sh` is updated first to provide the local `opencode.json`, then `install.sh` for user projects.
