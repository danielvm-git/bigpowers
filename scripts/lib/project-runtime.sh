#!/usr/bin/env bash
# story: e82s01
# Resolve consumer-project runtime settings without external YAML dependencies.

if [[ -n "${BIGPOWERS_PROJECT_RUNTIME_LOADED:-}" ]]; then
  return 0
fi
BIGPOWERS_PROJECT_RUNTIME_LOADED=1

_bp_config_value() {
  local project_root="$1" key="$2"
  local config_file="$project_root/.bigpowers/config.yaml"
  [[ -f "$config_file" ]] || return 1

  awk -v key="$key" '
    /^[[:space:]]*#/ { next }
    {
      separator = index($0, ":")
      if (!separator) next
      candidate = substr($0, 1, separator - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
      if (candidate != key) next
      value = substr($0, separator + 1)
      sub(/[[:space:]]+#.*$/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if ((substr(value, 1, 1) == "\"" && substr(value, length(value), 1) == "\"") ||
          (substr(value, 1, 1) == "\047" && substr(value, length(value), 1) == "\047")) {
        value = substr(value, 2, length(value) - 2)
      }
      print value
      found = 1
      exit
    }
    END { if (!found) exit 1 }
  ' "$config_file"
}

_bp_specs_dir_value() {
  local project_root="$1"
  if [[ -n "${BIGPOWERS_SPECS_DIR+x}" ]]; then
    printf '%s\n' "$BIGPOWERS_SPECS_DIR"
  elif _bp_config_value "$project_root" specs_dir; then
    return 0
  else
    printf '%s\n' specs
  fi
}

bp_specs_dir() {
  local project_root="${1:-$PWD}"
  local specs_dir
  specs_dir="$(_bp_specs_dir_value "$project_root")"
  if [[ -z "$specs_dir" ]]; then
    echo "bigpowers config: specs_dir must not be empty; set it to specs, .specs, or another directory" >&2
    return 2
  fi
  printf '%s\n' "$specs_dir"
}

bp_specs_path() {
  local project_root="${1:-$PWD}" relative_path="${2:-}"
  local specs_dir
  specs_dir="$(bp_specs_dir "$project_root")" || return

  if [[ "$specs_dir" == /* ]]; then
    if [[ -n "$relative_path" ]]; then
      printf '%s/%s\n' "${specs_dir%/}" "${relative_path#/}"
    else
      printf '%s\n' "${specs_dir%/}"
    fi
  elif [[ -n "$relative_path" ]]; then
    printf '%s/%s/%s\n' "${project_root%/}" "${specs_dir%/}" "${relative_path#/}"
  else
    printf '%s/%s\n' "${project_root%/}" "${specs_dir%/}"
  fi
}

_bp_vcs_value() {
  local project_root="$1"
  if [[ -n "${BIGPOWERS_VCS+x}" ]]; then
    printf '%s\n' "$BIGPOWERS_VCS"
  elif _bp_config_value "$project_root" vcs; then
    return 0
  else
    printf '%s\n' auto
  fi
}

bp_vcs_kind() {
  local project_root="${1:-$PWD}"
  local configured_vcs
  configured_vcs="$(_bp_vcs_value "$project_root")"

  case "$configured_vcs" in
    git|jj) printf '%s\n' "$configured_vcs" ;;
    auto)
      if [[ -d "$project_root/.jj" ]]; then
        printf '%s\n' jj
      elif [[ -e "$project_root/.git" ]]; then
        printf '%s\n' git
      else
        printf '%s\n' none
      fi
      ;;
    *)
      echo "bigpowers config: invalid vcs '$configured_vcs'. Expected one of: auto, git, jj" >&2
      return 2
      ;;
  esac
}
