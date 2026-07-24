#!/usr/bin/env bash
# story: e69s01

render_skill() {
  if declare -f render_mimo_skill >/dev/null 2>&1; then
    render_mimo_skill
    return
  fi
  local out="${MIMO_SKILLS:-.mimocode/skills}/$IR_NAME"
  mkdir -p "$out"
  cp "${SKILL_MD_PATH:-}" "$out/SKILL.md" 2>/dev/null || {
    {
      echo "---"
      echo "name: $IR_NAME"
      [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
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
    IR_BODY_SKILL=$(echo "$JSON_INPUT" | jq -r '.body_mimo_skill // .body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
