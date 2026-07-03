---
on:
  workflow_dispatch:
  schedule: weekly on monday

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: claude
  model: deepseek-v4-pro
  env:
    ANTHROPIC_BASE_URL: "https://api.deepseek.com/anthropic"
    ANTHROPIC_MODEL: "deepseek-v4-pro"
    ANTHROPIC_DEFAULT_SONNET_MODEL: "deepseek-v4-pro"
    ANTHROPIC_DEFAULT_HAIKU_MODEL: "deepseek-v4-flash"
    CLAUDE_CODE_SUBAGENT_MODEL: "deepseek-v4-flash"
    CLAUDE_CODE_EFFORT_LEVEL: "max"
    ANTHROPIC_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}

max-turns: 30
timeout-minutes: 20

network:
  allowed:
    - defaults
    - api.deepseek.com

safe-outputs:
  create-issue:
    max: 3
  create-pull-request:
    max: 1
  add-comment:
  push-to-pull-request-branch:

tools:
  github:
    toolsets: [default]
---

# Golden Story G-01: CI Gate Regression Test

You are an agent running in GitHub Actions on the **bigpowers** repository — a collection of AI agent skills for spec-driven, test-first software development.

Your job: run a deterministic regression check and report the result.

## Instructions

1. **Run the compliance gate**: Execute `npm run compliance` and capture the output.
2. **Run the skill sync check**: Execute `bash scripts/sync-skills.sh` and verify it exits 0.
3. **Check YAML validity**: Run `bash scripts/validate-specs-yaml.sh` and capture the result.
4. **Check the golden self-test**: If `scripts/golden-g04-selftest.sh` exists, run it. If not, note that e31s01 is not yet implemented.
5. **Summarize**: Create an issue or PR comment summarizing:
   - Which gates passed/failed
   - Any regressions detected
   - Whether the CI configuration (`.github/workflows/`) is consistent with the published specs in `specs/release-plan.yaml`

## Success Criteria

- All deterministic gates pass (exit code 0)
- No drift between CI workflow files and spec declarations
- If any gate fails, create an issue with the failure details
