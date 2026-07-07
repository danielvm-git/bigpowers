#!/usr/bin/env bash
# story: e48s15
# story: e37s05 e37s07

render_skill() {
  if declare -f render_gemini_skill >/dev/null 2>&1; then
    render_gemini_skill
    render_gemini_command
    return
  fi
  mkdir -p "${GEMINI_SKILLS:-.gemini/extensions/bigpowers/skills}/$IR_NAME"
  {
    echo "---"
    echo "name: $IR_NAME"
    [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "disable-model-invocation: true"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "${GEMINI_SKILLS}/$IR_NAME/SKILL.md"

  mkdir -p "${GEMINI_COMMANDS:-.gemini/extensions/bigpowers/commands}/prompts"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "${GEMINI_COMMANDS}/prompts/$IR_NAME.md"
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-GEMINI.md}"
}

# If stdin is a pipe/redirect, read the SkillIR JSON and render
if [[ ! -t 0 ]]; then
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
