#!/usr/bin/env bash
# check-orphan-gitlinks.sh — fail if git index has gitlinks without .gitmodules URLs
# story: BUG-2026-07-09T033939-golden-g01-submodule-checkout
set -euo pipefail

check_orphan_gitlinks() {
  local repo_root="${1:-.}"
  local gitlinks orphans=0

  cd "$repo_root"

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ ! -f .gitmodules ]] || ! git config -f .gitmodules --get "submodule.${path}.url" >/dev/null 2>&1; then
      gitlinks+=("$path")
      orphans=$((orphans + 1))
    fi
  done < <(git ls-files -s | awk '$1 == "160000" { $1=$2=$3=""; sub(/^ /, ""); print }')

  if [[ "$orphans" -eq 0 ]]; then
    echo "no orphan gitlinks"
    return 0
  fi

  echo "orphan gitlink(s) without .gitmodules URL:" >&2
  printf '  %s\n' "${gitlinks[@]}" >&2
  return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_orphan_gitlinks "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
