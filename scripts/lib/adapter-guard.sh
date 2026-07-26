#!/usr/bin/env bash
# story: e37s05
# adapter-guard.sh — shared skill-name validation for every render adapter.
#
# Adapters interpolate the SkillIR `name` straight into a filesystem path
# (mkdir -p "$dir/$IR_NAME"). A name containing "/" or ".." therefore writes
# outside the destination directory.
#
# Ten adapters carried a private copy of this check (qwen_is_unsafe_skill_name
# and friends) and nine had none at all — and the nine unguarded ones were
# exactly the nine that never got a per-target test. One guard, sourced by every
# adapter, replaces both the duplication and the gap.

# Returns 0 (true) when the name must not be used as a path component.
bp_is_unsafe_skill_name() {
  local name="${1-}"
  [[ -z "$name" || "$name" == "null" || "$name" == *"/"* || "$name" == *".."* || "$name" == .* ]]
}

# Echoes the name when safe; otherwise reports on stderr and returns 1.
# Usage inside render_skill:  name="$(bp_assert_safe_skill_name "$IR_NAME" adaptername)" || return 1
bp_assert_safe_skill_name() {
  local name="${1-}"
  local adapter="${2:-adapter}"
  if bp_is_unsafe_skill_name "$name"; then
    echo "${adapter}: refusing unsafe skill name: ${name:-<empty>}" >&2
    return 1
  fi
  printf '%s' "$name"
}
