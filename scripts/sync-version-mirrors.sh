#!/usr/bin/env bash
# story: e38s08
# sync-version-mirrors.sh — bump version mirrors across all config files
# Called by: @semantic-release/exec prepareCmd during release
# Usage: bash scripts/sync-version-mirrors.sh <version>
#
# Runs AFTER @semantic-release/npm has bumped package.json (so derived
# artifacts like .gemini/ and .pi/ read the new version from there).
# Runs BEFORE @semantic-release/git commits everything.

set -euo pipefail

VERSION="${1:?usage: sync-version-mirrors.sh <version>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "sync-version-mirrors.sh: bumping mirrors to $VERSION"

# ── 1. YAML mirror fields ──────────────────────────────────────────────
python3 "$REPO_ROOT/scripts/yaml-tools.py" set \
  "$REPO_ROOT/specs/state.yaml" bigpowers_version "$VERSION"

python3 "$REPO_ROOT/scripts/yaml-tools.py" set \
  "$REPO_ROOT/specs/release-plan.yaml" release.version "$VERSION"

# ── 2. Regenerate derived artifacts (reads already-bumped package.json) ─
bash "$REPO_ROOT/scripts/sync-skills.sh"

echo "sync-version-mirrors.sh: done — all mirrors at $VERSION"
