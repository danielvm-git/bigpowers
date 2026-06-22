#!/usr/bin/env bash
# bp-opensrc-check.sh — Check project dependencies against the local opensrc cache.
# Usage: bash scripts/bp-opensrc-check.sh [package.json|requirements.txt]
# Output: one line per dependency — FOUND or NOT CACHED, with local path when found.
set -euo pipefail

INPUT="${1:-package.json}"

if ! command -v npx >/dev/null 2>&1; then
  echo "SKIP: npx not found — opensrc requires Node.js" >&2
  exit 0
fi

if ! npx opensrc --version >/dev/null 2>&1; then
  echo "SKIP: opensrc not installed — run: npm install -g opensrc" >&2
  exit 0
fi

extract_deps() {
  local file="$1"
  case "$file" in
    *.json)
      python3 -c "
import json, sys
data = json.load(open('$file'))
deps = list(data.get('dependencies', {}).keys()) + list(data.get('devDependencies', {}).keys())
print('\n'.join(deps))
" 2>/dev/null || true
      ;;
    requirements*.txt)
      grep -v '^#' "$file" | grep -v '^$' | sed 's/[>=<!].*//' | tr -d ' ' || true
      ;;
    *)
      echo "WARN: unsupported file type: $file — pass package.json or requirements.txt" >&2
      exit 1
      ;;
  esac
}

if [ ! -f "$INPUT" ]; then
  echo "WARN: $INPUT not found" >&2
  exit 0
fi

echo "opensrc cache check: $INPUT"
echo "---"

FOUND=0
MISSING=0

while IFS= read -r dep; do
  [ -z "$dep" ] && continue
  result=$(npx opensrc search "$dep" 2>/dev/null | head -1 || true)
  if [ -n "$result" ]; then
    echo "FOUND     $dep — $result"
    FOUND=$((FOUND + 1))
  else
    echo "NOT CACHED $dep"
    MISSING=$((MISSING + 1))
  fi
done < <(extract_deps "$INPUT")

echo "---"
echo "Summary: $FOUND cached, $MISSING not cached"
