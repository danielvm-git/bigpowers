#!/usr/bin/env bash
# story: e73s01
# scenario: SC-e73s01-P1-01
# Windsurf skill adapter — renders .windsurf/rules from SkillIR.

windsurf_is_unsafe_skill_name() {
  local name="$1"
  [[ -z "$name" || "$name" == "null" || "$name" == *"/"* || "$name" == *".."* ]]
}

windsurf_sanitize_name() {
  local name="$1"
  if windsurf_is_unsafe_skill_name "$name"; then
    echo "windsurf: invalid skill name: ${name:-<empty>}" >&2
    return 1
  fi
  printf '%s' "$name"
}

render_skill() {
  local safe_name
  safe_name=$(windsurf_sanitize_name "${IR_NAME:-}") || return 1
  local out="${WINDSURF_RULES:-.windsurf/rules}"
  mkdir -p "$out"
  {
    echo "---"
    echo "name: $safe_name"
    [[ -n "${IR_MODEL:-}" && "$IR_MODEL" != "null" ]] && echo "model: $IR_MODEL"
    echo "description: \"${IR_DESC_ESCAPED:-}\""
    echo "---"
    echo ""
    echo "${IR_BODY:-}"
  } > "$out/$safe_name.md"
}


wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode copy "${1:-AGENTS.md}"
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
