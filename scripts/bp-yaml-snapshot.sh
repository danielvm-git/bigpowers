#!/usr/bin/env bash
# bp-yaml-snapshot.sh — freeze release-plan + requirements into snapshots/
# Usage: bp-yaml-snapshot.sh [version]  (default: read from release-plan.yaml)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="$REPO_ROOT/specs"
VER="${1:-}"

if [[ -z "$VER" ]]; then
  VER=$(grep -E '^\s+version:' "$SPECS/release-plan.yaml" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi
DEST="$SPECS/requirements/snapshots/release-$VER"
mkdir -p "$DEST"

for f in release-plan.yaml requirements/VISION_LATEST.yaml requirements/SCOPE_LATEST.yaml; do
  src="$SPECS/$f"
  [[ -f "$src" ]] || continue
  base=$(basename "$f")
  cp "$src" "$DEST/$base"
done

echo "bp-yaml-snapshot: wrote $DEST"
ls -la "$DEST"
