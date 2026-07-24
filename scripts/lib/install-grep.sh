#!/usr/bin/env bash
# install-grep.sh — grep install.sh plus extracted install-targets-*.sh
# story: e65s02 (fleet Wave B file-size split)

if [[ -n "${INSTALL_GREP_LOADED:-}" ]]; then return 0; fi
INSTALL_GREP_LOADED=1

install_grep_paths() {
  local root="${1:-${REPO_ROOT:-}}"
  if [[ -z "$root" ]]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi
  printf '%s\n' "$root/scripts/install.sh" "$root"/scripts/lib/install-targets-*.sh
}

install_grep() {
  grep "$@" $(install_grep_paths)
}
