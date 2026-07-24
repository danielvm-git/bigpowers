#!/usr/bin/env bash
# story: e37s09
# story: e74s01
# story: e74s02
# Antigravity CLI (agy) — skills under .agents/skills/ (workspace) or
# ~/.gemini/antigravity-cli/skills/ (global). Separate from Gemini extension path.
# Paths documented in specs/epics/e74-integration-antigravity/RESEARCH-ANTIGRAVITY.md

# Global skills: ~/.gemini/antigravity-cli/skills/
# Workspace skills: .agents/skills/
# Global hooks: ~/.gemini/config/hooks.json
# Workspace hooks: .agents/hooks.json
AGY_SKILLS="${AGY_SKILLS:-.agents/skills}"
AGY_HOOKS_GLOBAL="${AGY_HOOKS_GLOBAL:-$HOME/.gemini/config/hooks.json}"
AGY_HOOKS_WORKSPACE="${AGY_HOOKS_WORKSPACE:-.agents/hooks.json}"

render_skill() {
  mkdir -p "${AGY_SKILLS}/${IR_NAME:-_stub}"
  cp "${SKILL_MD_PATH:-}" "${AGY_SKILLS}/${IR_NAME}/SKILL.md" 2>/dev/null || {
    {
      echo "---"
      echo "name: $IR_NAME"
      [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
      echo "description: \"$IR_DESC_ESCAPED\""
      echo "---"
      echo ""
      echo "${IR_BODY:-}"
    } > "${AGY_SKILLS}/${IR_NAME}/SKILL.md"
  }
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-CLAUDE.md}"
}

# If stdin is a pipe/redirect, read the SkillIR JSON and render
if [[ ! -t 0 ]]; then
  JSON_INPUT=$(cat)
  if [[ -n "$JSON_INPUT" ]]; then
    IR_NAME=$(echo "$JSON_INPUT" | jq -r '.name')
    IR_MODEL=$(echo "$JSON_INPUT" | jq -r '.model // empty')
    IR_DESCRIPTION=$(echo "$JSON_INPUT" | jq -r '.description')
    IR_BODY=$(echo "$JSON_INPUT" | jq -r '.body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
