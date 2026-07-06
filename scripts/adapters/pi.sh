#!/usr/bin/env bash
# story: e37s05 e37s07

render_skill() {
  if declare -f render_pi_skill >/dev/null 2>&1; then
    render_pi_skill
    render_pi_prompt
    return
  fi
  mkdir -p "${PI_SKILLS:-.pi/skills}/$IR_NAME"
  cp "${SKILL_MD_PATH:-}" "${PI_SKILLS}/$IR_NAME/SKILL.md" 2>/dev/null || {
    {
      echo "---"
      echo "name: $IR_NAME"
      [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
      echo "description: \"$IR_DESC_ESCAPED\""
      echo "---"
      echo ""
      echo "$IR_BODY"
    } > "${PI_SKILLS}/$IR_NAME/SKILL.md"
  }

  mkdir -p "${PI_PROMPTS:-.pi/prompts}"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "${PI_PROMPTS}/$IR_NAME.md"
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-CLAUDE.md}"
}
