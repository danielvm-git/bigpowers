#!/usr/bin/env bash
# story: e37s05 e37s06
# scenario: SC-e37s06-P1-02
# Shared Context Derivative wiring — symlink with copy fallback (Windows-safe).

wire_symlink_or_copy() {
  local src="$1"
  local dest="$2"

  [[ -f "$src" ]] || { echo "context-wire: source missing: $src" >&2; return 1; }

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest" 2>/dev/null)" == "$src" || "$(readlink "$dest" 2>/dev/null)" == "./$src" ]]; then
    return 0
  fi
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest" 2>/dev/null; then
    return 0
  fi

  rm -f "$dest" 2>/dev/null || true
  if ln -sf "$src" "$dest" 2>/dev/null; then
    return 0
  fi

  echo "context-wire: symlink failed for $dest — using copy fallback" >&2
  cp "$src" "$dest"
}

wire_config_bridge() {
  local bridge_file="$1"
  local bridge_key="$2"
  local agents_path="${3:-AGENTS.md}"

  mkdir -p "$(dirname "$bridge_file")"
  if [[ -f "$bridge_file" ]] && grep -q "^${bridge_key}:" "$bridge_file" 2>/dev/null; then
    return 0
  fi
  printf '%s: %s\n' "$bridge_key" "$agents_path" > "$bridge_file"
}

wire_context_mode() {
  local mode="$1"
  local file="${2:-}"
  local bridge_file="${3:-}"
  local bridge_key="${4:-read}"
  local src="${5:-AGENTS.md}"

  case "$mode" in
    native) return 0 ;;
    symlink|copy)
      [[ -n "$file" ]] || { echo "context-wire: file required for mode=$mode" >&2; return 1; }
      if [[ "$mode" == "copy" ]]; then
        cp "$src" "$file"
      else
        wire_symlink_or_copy "$src" "$file"
      fi
      ;;
    config-bridge)
      [[ -n "$bridge_file" ]] || { echo "context-wire: bridge_file required" >&2; return 1; }
      wire_config_bridge "$bridge_file" "$bridge_key" "$src"
      ;;
    *)
      echo "context-wire: unknown mode: $mode" >&2
      return 1
      ;;
  esac
}
