#!/usr/bin/env bash
# story: e21s03
# bp-read-agents.sh — Extract preflight/test/build/lint/deploy commands from AGENTS.md.
# Outputs env-var exports: BP_PREFLIGHT, BP_TEST, BP_BUILD, BP_LINT, BP_DEPLOY
# Usage: eval "$(bash scripts/bp-read-agents.sh)"  # imports env vars
#        bash scripts/bp-read-agents.sh --print     # prints discovered commands
set -euo pipefail

PRINT_MODE=false
if [ "${1:-}" = "--print" ]; then
  PRINT_MODE=true
fi

AGENTS_FILES=("AGENTS.md" "CLAUDE.md" "CURSOR.md")
FOUND_FILE=""

for f in "${AGENTS_FILES[@]}"; do
  if [ -f "$f" ]; then
    FOUND_FILE="$f"
    break
  fi
done

if [ -z "$FOUND_FILE" ]; then
  if $PRINT_MODE; then echo "No AGENTS.md found — using defaults" >&2; fi
  exit 0
fi

extract_command() {
  local section="$1"
  local file="$2"
  # Extract the first non-empty, non-comment line after a ## <section> heading
  awk "
    /^## $section/ { found=1; next }
    found && /^## / { found=0 }
    found && /^\`\`\`/ { in_block=!in_block; next }
    found && in_block && /^[a-zA-Z]/ { print; exit }
    found && !/^\`\`\`/ && /^[a-zA-Z]/ && !in_block { print; exit }
  " "$file" 2>/dev/null | head -1 | tr -d '\r' || true
}

BP_PREFLIGHT=$(extract_command "Preflight" "$FOUND_FILE")
BP_TEST=$(extract_command "Test" "$FOUND_FILE")
BP_BUILD=$(extract_command "Build" "$FOUND_FILE")
BP_LINT=$(extract_command "Lint" "$FOUND_FILE")
BP_DEPLOY=$(extract_command "Deploy" "$FOUND_FILE")

if $PRINT_MODE; then
  echo "Source: $FOUND_FILE"
  if [ -n "$BP_PREFLIGHT" ]; then echo "Preflight: $BP_PREFLIGHT"; fi
  if [ -n "$BP_TEST" ];      then echo "Test:      $BP_TEST"; fi
  if [ -n "$BP_BUILD" ];     then echo "Build:     $BP_BUILD"; fi
  if [ -n "$BP_LINT" ];      then echo "Lint:      $BP_LINT"; fi
  if [ -n "$BP_DEPLOY" ];    then echo "Deploy:    $BP_DEPLOY"; fi
else
  # Bash %q preserves the command as data when the caller evaluates exports.
  if [ -n "$BP_PREFLIGHT" ]; then printf 'export BP_PREFLIGHT=%q\n' "$BP_PREFLIGHT"; fi
  if [ -n "$BP_TEST" ];      then printf 'export BP_TEST=%q\n' "$BP_TEST"; fi
  if [ -n "$BP_BUILD" ];     then printf 'export BP_BUILD=%q\n' "$BP_BUILD"; fi
  if [ -n "$BP_LINT" ];      then printf 'export BP_LINT=%q\n' "$BP_LINT"; fi
  if [ -n "$BP_DEPLOY" ];    then printf 'export BP_DEPLOY=%q\n' "$BP_DEPLOY"; fi
fi

