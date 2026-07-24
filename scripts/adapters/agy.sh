#!/usr/bin/env bash
# story: e37s09
# story: e74s01
# story: e74s02
# Antigravity CLI (agy) — skills at .agents/skills/ (workspace) and
# ~/.gemini/antigravity-cli/skills/ (global). See RESEARCH-ANTIGRAVITY.md.

AGY_SKILLS="${AGY_SKILLS:-.agents/skills}"
AGY_HOOKS_GLOBAL="${AGY_HOOKS_GLOBAL:-$HOME/.gemini/config/hooks.json}"
AGY_HOOKS_WORKSPACE="${AGY_HOOKS_WORKSPACE:-.agents/hooks.json}"

render_skill() {
  if declare -f render_agy_skill >/dev/null 2>&1; then
    render_agy_skill
    return
  fi
  local out="${AGY_SKILLS}/${IR_NAME}"
  mkdir -p "$out"
  cp "${SKILL_MD_PATH:-}" "$out/SKILL.md" 2>/dev/null || {
    {
      echo "---"
      echo "name: $IR_NAME"
      [[ -n "${IR_MODEL:-}" ]] && echo "model: $IR_MODEL"
      echo "description: \"$IR_DESC_ESCAPED\""
      echo "---"
      echo ""
      echo "${IR_BODY_SKILL:-$IR_BODY}"
    } > "$out/SKILL.md"
  }
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-AGENTS.md}"
}

# If stdin is a pipe/redirect, read the SkillIR JSON and render
if [[ ! -t 0 ]]; then
  JSON_INPUT=$(cat)
  if [[ -n "$JSON_INPUT" ]]; then
    IR_NAME=$(echo "$JSON_INPUT" | jq -r '.name')
    IR_MODEL=$(echo "$JSON_INPUT" | jq -r '.model // empty')
    IR_DESCRIPTION=$(echo "$JSON_INPUT" | jq -r '.description')
    IR_BODY=$(echo "$JSON_INPUT" | jq -r '.body')
    IR_BODY_SKILL=$(echo "$JSON_INPUT" | jq -r '.body_agy_skill // .body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
