#!/usr/bin/env bash
# story: e48s15
# story: e37s05 e37s07
# story: e64s01

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

GEMINI_HOOK_EVENTS=(
  BeforeTool AfterTool BeforeAgent AfterAgent BeforeModel
  BeforeToolSelection AfterModel SessionStart SessionEnd Notification PreCompress
)

gemini_hooks_dir() {
  echo "${GEMINI_HOOKS_DIR:-${GEMINI_EXT_DIR:-.gemini/extensions/bigpowers}/hooks}"
}

list_hook_events() {
  printf '%s\n' "${GEMINI_HOOK_EVENTS[@]}"
}

gemini_required_hook_files() {
  cat <<'EOF'
session-start
run-hook.cmd
HOOKS.md
hooks-manifest.json
settings.json.example
before-tool-git-guard.sh
before-tool-rtk.sh
before-tool-token-mgmt.sh
EOF
}

validate_hook_templates() {
  local hookdir missing=0 rel
  hookdir="$(gemini_hooks_dir)"
  if [[ ! -d "$hookdir" ]]; then
    echo "FAIL: hook dir missing: $hookdir" >&2
    return 1
  fi
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    if [[ ! -f "$hookdir/$rel" ]]; then
      echo "FAIL: missing $hookdir/$rel" >&2
      missing=1
    fi
  done < <(gemini_required_hook_files)
  local count
  count="$(list_hook_events | wc -l | tr -d ' ')"
  if [[ "$count" != "11" ]]; then
    echo "FAIL: expected 11 hook events, got $count" >&2
    missing=1
  fi
  return "$missing"
}

render_hooks_manifest() {
  if declare -f render_gemini_hooks_manifest >/dev/null 2>&1; then
    render_gemini_hooks_manifest
    return
  fi
  local hookdir
  hookdir="$(gemini_hooks_dir)"
  mkdir -p "$hookdir"
  cat > "$hookdir/hooks-manifest.json" <<'JSON'
{
  "schema_version": 1,
  "target": "gemini",
  "events_total": 11,
  "events": [
    "BeforeTool", "AfterTool", "BeforeAgent", "AfterAgent", "BeforeModel",
    "BeforeToolSelection", "AfterModel", "SessionStart", "SessionEnd",
    "Notification", "PreCompress"
  ]
}
JSON
}

# CLI: bash scripts/adapters/gemini.sh --validate-hooks
if [[ "${1:-}" == "--validate-hooks" ]]; then
  validate_hook_templates && echo "PASS: gemini hook templates"
  exit $?
fi

if [[ "${1:-}" == "--list-hook-events" ]]; then
  list_hook_events
  exit 0
fi

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
