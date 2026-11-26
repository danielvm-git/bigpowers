#!/usr/bin/env bash
# story: BUG-2026-11-06-install-uninstall-noop
# install-manifest.sh — record and replay the entries scripts/install.sh owns.
#
# Before this, `install.sh --uninstall` removed an entry only when the literal
# text of its symlink target began with $REPO_ROOT/. That failed in two ways:
#
#   1. Installing from the npm package links into node_modules/bigpowers, and
#      an uninstall run from a checkout never matches that prefix — 0 of N
#      entries removed, exit 0, no report.
#   2. Chained hops (~/.agents/skills/x -> ~/.claude/skills/x -> node_modules/…)
#      and copy-mode installs (real directories) were never considered at all.
#
# The manifest is the authoritative record of what install.sh created. Uninstall
# replays it after the per-channel link sweep, so a machine can be cleaned even
# when the link target changed or a channel switched to copies.

if [ -n "${INSTALL_MANIFEST_LOADED:-}" ]; then
  return 0
fi
INSTALL_MANIFEST_LOADED=1

BP_MANIFEST_DIR="${BP_MANIFEST_DIR:-$HOME/.bigpowers}"
BP_MANIFEST="${BP_MANIFEST_DIR}/install-manifest.json"

# bp_manifest_path — echo the manifest file path, creating the parent dir.
bp_manifest_path() {
  mkdir -p "$BP_MANIFEST_DIR"
  echo "$BP_MANIFEST"
}

# bp_manifest_read — emit the JSON array of recorded entries (empty if none).
bp_manifest_read() {
  local m; m="$(bp_manifest_path)"
  if [[ -f "$m" ]]; then
    cat "$m"
  else
    echo '{"entries":[]}'
  fi
}

# bp_manifest_add <dst> <src> — record (or refresh) one owned entry.
bp_manifest_add() {
  local dst="$1" src="$2"
  [[ -n "$dst" ]] || return 0
  local m; m="$(bp_manifest_path)"
  jq -e --arg dst "$dst" --arg src "$src" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '(.entries |= [.[] | select(.dst != $dst)]) | .entries += [{"dst":$dst,"src":$src,"installed_at":$ts}]' \
    "$(bp_manifest_read)" > "$m.tmp" 2>/dev/null && mv "$m.tmp" "$m" || {
    # jq may be absent on a fresh machine; keep a line-oriented fallback that the
    # removal pass can still consume.
    printf '%s\t%s\n' "$dst" "$src" >> "$m.fallback"
  }
}

# bp_manifest_remove <dst> — drop one entry after it has been removed.
bp_manifest_remove() {
  local dst="$1"
  local m; m="$(bp_manifest_path)"
  if command -v jq >/dev/null 2>&1 && [[ -f "$m" ]]; then
    jq --arg dst "$dst" '.entries |= [.[] | select(.dst != $dst)]' "$m" > "$m.tmp" 2>/dev/null && mv "$m.tmp" "$m"
  fi
  [[ -f "$m.fallback" ]] && sed -i '' "/^$(printf '%s' "$dst" | sed 's/[.[\*^$()+?{|]/\\&/g')	/d" "$m.fallback" 2>/dev/null || true
}

# bp_manifest_dsts — emit every recorded destination, one per line.
bp_manifest_dsts() {
  bp_manifest_read | jq -r '.entries[].dst' 2>/dev/null
  [[ -f "$BP_MANIFEST.fallback" ]] && cut -f1 "$BP_MANIFEST.fallback"
}

# bp_target_managed <link-or-dir> — echo the real managed target when the entry
# is something install.sh owns (resolving symlink chains), else nothing.
#
# Managed means the resolved path lives under $REPO_ROOT or under a
# node_modules/bigpowers install root (the npm package).
bp_target_managed() {
  local entry="$1"
  [[ -e "$entry" || -L "$entry" ]] || return 0
  local real
  real="$(bp_realpath_follow "$entry")" || return 0
  [[ -n "$real" ]] || return 0
  case "$real" in
    "$REPO_ROOT"|"$REPO_ROOT"/*) echo "$real" ;;
    *"/node_modules/bigpowers"|*"/node_modules/bigpowers"/*) echo "$real" ;;
  esac
}

# bp_realpath_follow <path> — resolve symlink chains to the final existing path.
bp_realpath_follow() {
  local p="$1" dir base
  [[ -n "$p" ]] || return 1
  # Walk the parent directory physically, then follow any final symlink.
  dir="$(dirname "$p")"
  base="$(basename "$p")"
  local pdir
  pdir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
  local cur="$pdir/$base"
  local hops=0
  while [[ -L "$cur" ]]; do
    hops=$((hops + 1))
    [[ $hops -gt 16 ]] && return 1
    local link_target
    link_target="$(readlink "$cur")" || return 1
    case "$link_target" in
      /*) cur="$link_target" ;;
      *)  cur="$(cd "$(dirname "$cur")" && pwd -P)/$link_target" ;;
    esac
  done
  echo "$cur"
}

# bp_manifest_replay_cleanup — remove every recorded entry still present and
# owned, reporting a summary line. Run after the per-channel link sweep so that
# copy-mode and chained entries the sweep missed still get cleaned.
bp_manifest_replay_cleanup() {
  local dst real removed=0
  while IFS= read -r dst; do
    [[ -n "$dst" ]] || continue
    real="$(bp_target_managed "$dst")" || continue
    if [[ -L "$dst" ]]; then
      if $DRY_RUN; then echo "  [dry-run] rm $dst"; else rm -f "$dst"; fi
    elif [[ -d "$dst" && ! -L "$dst" ]]; then
      # Copy-mode entry: only remove it if it looks like a bigpowers skill
      # directory (contains SKILL.md) so we never delete a foreign directory.
      if [[ -f "$dst/SKILL.md" ]]; then
        if $DRY_RUN; then echo "  [dry-run] rm -rf $dst"; else rm -rf "$dst"; fi
      else
        continue
      fi
    else
      continue
    fi
    bp_manifest_remove "$dst"
    removed=$((removed + 1))
  done < <(bp_manifest_dsts)
  echo "  manifest cleanup: removed $removed recorded entr$([ "$removed" -eq 1 ] && echo y || echo ies)"
}
