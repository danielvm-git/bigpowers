#!/usr/bin/env bash
# story: BUG-2026-11-06-install-multi-channel-collisions
# verify-distribution.sh — report when more than one install channel owns the
# same host. Issue #208: the catalog shipped to ~/.pi/agent/skills (symlinks)
# AND via pi's package setting, so pi loaded the same 80 skill names twice and
# ranked a copy the maintainer does not edit. This check names the active
# channels and fails when two overlap for one host.
#
# Usage:
#   bash scripts/verify-distribution.sh           # human-readable report
#   bash scripts/verify-distribution.sh --strict  # exit 1 when a conflict exists
set -euo pipefail

STRICT=0
[[ "${1:-}" == "--strict" ]] && STRICT=1
conflicts=0

info() { printf '  %s\n' "$1"; }
warn() { printf '  CONFLICT: %s\n' "$1"; conflicts=$((conflicts + 1)); }
ok()   { printf '  ok: %s\n' "$1"; }

# Resolve a symlink chain to a real path (echo nothing when unresolvable).
resolve() {
  local p="$1" dir base cur hops=0
  [[ -e "$p" || -L "$p" ]] || return 0
  dir="$(dirname "$p")"; base="$(basename "$p")"
  local pdir; pdir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 0
  cur="$pdir/$base"
  while [[ -L "$cur" ]]; do
    hops=$((hops + 1)); [[ $hops -gt 16 ]] && return 0
    local t; t="$(readlink "$cur")" || return 0
    case "$t" in
      /*) cur="$t" ;;
      *)  cur="$(cd "$(dirname "$cur")" && pwd -P)/$t" ;;
    esac
  done
  echo "$cur"
}

is_bigpowers() {
  case "$1" in
    *"/bigpowers"|*"/bigpowers/"*) return 0 ;;
    *) return 1 ;;
  esac
}

echo "verify-distribution:"

PI_GLOBAL="$HOME/.pi/agent/skills"
PI_SETTINGS="$HOME/.pi/agent/settings.json"
pi_package=0
pi_symlinks=0

# 1. package channel — pi's settings list a bigpowers package source.
if [[ -f "$PI_SETTINGS" ]] && grep -q 'bigpowers' "$PI_SETTINGS"; then
  pi_package=1
  info "pi package channel: $PI_SETTINGS lists a bigpowers source"
fi

# 2. global symlink channel — ~/.pi/agent/skills entries resolve into bigpowers.
if [[ -d "$PI_GLOBAL" ]]; then
  for entry in "$PI_GLOBAL"/*/; do
    [[ -L "${entry%/}" ]] || continue
    real="$(resolve "${entry%/}")"
    if [[ -n "$real" ]] && is_bigpowers "$real"; then
      pi_symlinks=1
      break
    fi
  done
  [[ "$pi_symlinks" -eq 1 ]] && info "pi symlink channel: $PI_GLOBAL links into a bigpowers tree"
fi

echo ""
if [[ "$pi_package" -eq 1 && "$pi_symlinks" -eq 1 ]]; then
  warn "pi has both the package channel and the global symlink channel — pick one"
elif [[ "$pi_package" -eq 1 ]]; then
  ok "pi has exactly one install channel (package)"
elif [[ "$pi_symlinks" -eq 1 ]]; then
  ok "pi has exactly one install channel (symlinks)"
else
  info "pi has no bigpowers channel detected"
fi

echo ""
if [[ "$conflicts" -gt 0 ]]; then
  echo "verify-distribution: $conflicts conflict(s) found"
  [[ "$STRICT" -eq 1 ]] && exit 1
  exit 0
fi
echo "verify-distribution: clean (exactly one channel per host)"
exit 0
