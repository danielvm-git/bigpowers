#!/usr/bin/env bash
# story: e58s01
# ab-arm-bigpowers.sh — provision an A/B eval workdir the way a bigpowers user has it.
# Runs inside the workdir. $AB_BP_ROOT is the bigpowers checkout.
# Copies (never symlinks): the agent must not be able to walk back into the repo,
# where the hidden tests live.
set -euo pipefail
: "${AB_BP_ROOT:?AB_BP_ROOT must point at the bigpowers checkout}"

mkdir -p .claude/skills .agents/skills specs/bugs specs/verifications
for skill_dir in "$AB_BP_ROOT"/skills/*/; do
  name="$(basename "$skill_dir")"
  cp -R "$skill_dir" ".claude/skills/$name"
  cp -R "$skill_dir" ".agents/skills/$name"
done
cp -R "$AB_BP_ROOT/scripts" scripts
cp "$AB_BP_ROOT/specs/benchmarks/ab/arms/bigpowers/CLAUDE.md" CLAUDE.md
cp CLAUDE.md AGENTS.md
