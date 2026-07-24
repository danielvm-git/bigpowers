#!/usr/bin/env bash
# story: e66s01
# scenario: SC-e66s01-P1-01
# Cline skill adapter — renders .cline/skills from SkillIR.

cline_is_unsafe_skill_name() {
  local name="$1"
  [[ -z "$name" || "$name" == "null" || "$name" == *"/"* || "$name" == *".."* ]]
}

cline_sanitize_name() {
  local name="$1"
  if cline_is_unsafe_skill_name "$name"; then
    echo "cline: invalid skill name: ${name:-<empty>}" >&2
    return 1
  fi
  printf '%s' "$name"
}

render_skill() {
  local safe_name
  safe_name=$(cline_sanitize_name "${IR_NAME:-}") || return 1
  local out="${CLINE_SKILLS:-.cline/skills}"
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
  # native mode — Cline reads AGENTS.md directly
  return 0
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
