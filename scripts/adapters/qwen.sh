#!/usr/bin/env bash
# story: e68s01
# scenario: SC-e68s01-P1-01
# Qwen Code skill adapter — renders .qwen/skills from SkillIR.

qwen_is_unsafe_skill_name() {
  local name="$1"
  [[ -z "$name" || "$name" == "null" || "$name" == *"/"* || "$name" == *".."* ]]
}

qwen_sanitize_name() {
  local name="$1"
  if qwen_is_unsafe_skill_name "$name"; then
    echo "qwen: invalid skill name: ${name:-<empty>}" >&2
    return 1
  fi
  printf '%s' "$name"
}

render_skill() {
  local safe_name
  safe_name=$(qwen_sanitize_name "${IR_NAME:-}") || return 1
  local out="${QWEN_SKILLS:-.qwen/skills}"
  mkdir -p "$out/$safe_name"

  if [[ -n "${SKILL_MD_PATH:-}" && -f "$SKILL_MD_PATH" ]]; then
    cp "$SKILL_MD_PATH" "$out/$safe_name/SKILL.md"
    return 0
  fi

  {
    echo "---"
    echo "name: $safe_name"
    [[ -n "${IR_MODEL:-}" && "$IR_MODEL" != "null" ]] && echo "model: $IR_MODEL"
    echo "description: \"${IR_DESC_ESCAPED:-}\""
    echo "---"
    echo ""
    echo "${IR_BODY:-}"
  } > "$out/$safe_name/SKILL.md"
}


wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-QWEN.md}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ ! -t 0 ]]; then
  JSON_INPUT=$(cat)
  if [[ -n "$JSON_INPUT" ]]; then
    IR_NAME=$(echo "$JSON_INPUT" | jq -r '.name')
    IR_MODEL=$(echo "$JSON_INPUT" | jq -r '.model')
    IR_DESCRIPTION=$(echo "$JSON_INPUT" | jq -r '.description')
    IR_BODY=$(echo "$JSON_INPUT" | jq -r '.body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
