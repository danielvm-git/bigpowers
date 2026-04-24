#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="${SOURCE_DIR:-$REPO_ROOT}"
TARGET_DIR="${TARGET_DIR:-"$HOME/.cursor/skills"}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "SOURCE_DIR is not a directory: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

shopt -s nullglob
count=0
for item in "$SOURCE_DIR"/*; do
  [[ -d "$item" ]] || continue
  name="$(basename "$item")"
  [[ -f "$item/SKILL.md" ]] || continue
  if [[ "$name" == .?* ]]; then
    continue
  fi
  echo "Syncing <${name}>"
  rsync -a --delete "$item/" "$TARGET_DIR/${name}/"
  count=$((count + 1))
done

if [[ "$count" -eq 0 ]]; then
  echo "No top-level skill directories with SKILL.md found in $SOURCE_DIR" >&2
  exit 1
fi

echo "Done. Installed $count skills under $TARGET_DIR"
