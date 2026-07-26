#!/usr/bin/env bash
# story: e48s15
# story: e37s05 e37s07

render_skill() {
  # shellcheck source=../lib/adapter-guard.sh
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/adapter-guard.sh"
  bp_assert_safe_skill_name "${IR_NAME-}" pi >/dev/null || return 1
  if declare -f render_pi_skill >/dev/null 2>&1; then
    render_pi_skill
    render_pi_prompt
    return
  fi
  mkdir -p "${PI_SKILLS:-.pi/skills}/$IR_NAME"
  cp "${SKILL_MD_PATH:-}" "${PI_SKILLS:-.pi/skills}/$IR_NAME/SKILL.md" 2>/dev/null || {
    {
      echo "---"
      echo "name: $IR_NAME"
      [[ -n "$IR_MODEL" ]] && echo "model: $IR_MODEL"
      echo "description: \"$IR_DESC_ESCAPED\""
      echo "---"
      echo ""
      echo "${IR_BODY_SKILL:-$IR_BODY}"
    } > "${PI_SKILLS:-.pi/skills}/$IR_NAME/SKILL.md"
  }

  mkdir -p "${PI_PROMPTS:-.pi/prompts}"
  {
    echo "---"
    echo "name: $IR_NAME"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "${PI_PROMPTS:-.pi/prompts}/$IR_NAME.md"
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
    IR_MODEL=$(echo "$JSON_INPUT" | jq -r '.model')
    IR_DESCRIPTION=$(echo "$JSON_INPUT" | jq -r '.description')
    IR_BODY=$(echo "$JSON_INPUT" | jq -r '.body')
    # Skill files get link-rewritten bodies (relative links repointed from
    # .pi/skills/<name>/ to the shipped source tree); prompts keep the raw body.
    IR_BODY_SKILL=$(echo "$JSON_INPUT" | jq -r '.body_pi_skill // .body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
