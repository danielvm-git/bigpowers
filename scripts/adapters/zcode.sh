#!/usr/bin/env bash
# story: e76s01
# ZCode skill adapter — renders SKILL.md to ~/.zcode/skills/<name>/.

render_skill() {
  local skills_dir="${ZCODE_SKILLS:-${HOME}/.zcode/skills}"
  mkdir -p "${skills_dir}/${IR_NAME}"
  {
    echo "---"
    echo "name: $IR_NAME"
    [[ -n "${IR_MODEL:-}" ]] && echo "model: $IR_MODEL"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "${skills_dir}/${IR_NAME}/SKILL.md"
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  local dest="${ZCODE_AGENTS:-${HOME}/.zcode/AGENTS.md}"
  mkdir -p "$(dirname "$dest")"
  wire_context_mode symlink "$dest" "" "" "" "${1:-AGENTS.md}"
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
