#!/usr/bin/env bash
# story: e37s05
# scenario: SC-e37s05-P1-01
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS_FILE="${1:-$SCRIPT_DIR/targets.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "validate-targets-yaml: yq required — brew install yq" >&2
  exit 1
fi

[[ -f "$TARGETS_FILE" ]] || { echo "validate-targets-yaml: missing $TARGETS_FILE" >&2; exit 1; }

version=$(yq -r '.registry_version // ""' "$TARGETS_FILE")
[[ -n "$version" && "$version" != "null" ]] || { echo "validate-targets-yaml: registry_version required" >&2; exit 1; }

count=$(yq '.targets | length' "$TARGETS_FILE")
[[ "$count" -ge 5 ]] || { echo "validate-targets-yaml: need >= 5 targets, got $count" >&2; exit 1; }

valid_tiers=" default_on opt_in optional "
valid_modes=" native symlink copy config-bridge "

while IFS= read -r row; do
  id=$(echo "$row" | yq -r '.id // ""')
  name=$(echo "$row" | yq -r '.name // ""')
  tier=$(echo "$row" | yq -r '.tier // ""')
  skill_null=$(echo "$row" | yq -r '.skill == null')
  context_null=$(echo "$row" | yq -r '.context == null')

  [[ -n "$id" ]] || { echo "validate-targets-yaml: target missing id" >&2; exit 1; }
  [[ -n "$name" ]] || { echo "validate-targets-yaml: $id missing name" >&2; exit 1; }
  [[ "$valid_tiers" == *" $tier "* ]] || { echo "validate-targets-yaml: $id invalid tier: $tier" >&2; exit 1; }
  [[ "$skill_null" == "false" || "$context_null" == "false" ]] || {
    echo "validate-targets-yaml: $id needs skill or context" >&2; exit 1
  }

  if [[ "$skill_null" == "false" ]]; then
    adapter=$(echo "$row" | yq -r '.skill.adapter // ""')
    [[ -n "$adapter" ]] || { echo "validate-targets-yaml: $id skill.adapter required" >&2; exit 1; }
    adapter_file="$SCRIPT_DIR/adapters/${adapter}.sh"
    [[ -f "$adapter_file" ]] || { echo "validate-targets-yaml: missing adapter $adapter_file" >&2; exit 1; }
  fi

  if [[ "$context_null" == "false" ]]; then
    mode=$(echo "$row" | yq -r '.context.mode // ""')
    adapter=$(echo "$row" | yq -r '.context.adapter // ""')
    [[ "$valid_modes" == *" $mode "* ]] || { echo "validate-targets-yaml: $id invalid context.mode: $mode" >&2; exit 1; }
    [[ -n "$adapter" ]] || { echo "validate-targets-yaml: $id context.adapter required" >&2; exit 1; }
    adapter_file="$SCRIPT_DIR/adapters/${adapter}.sh"
    [[ -f "$adapter_file" ]] || { echo "validate-targets-yaml: missing context adapter $adapter_file" >&2; exit 1; }
    if [[ "$mode" == "symlink" || "$mode" == "copy" ]]; then
      file=$(echo "$row" | yq -r '.context.file // ""')
      [[ -n "$file" ]] || { echo "validate-targets-yaml: $id context.file required for $mode" >&2; exit 1; }
    fi
    if [[ "$mode" == "config-bridge" ]]; then
      bf=$(echo "$row" | yq -r '.context.bridge_file // ""')
      bk=$(echo "$row" | yq -r '.context.bridge_key // ""')
      [[ -n "$bf" && -n "$bk" ]] || { echo "validate-targets-yaml: $id bridge_file/key required" >&2; exit 1; }
    fi
  fi
done < <(yq -o=json '.targets[]' "$TARGETS_FILE" | jq -c '.')

# Unique ids
dup=$(yq -r '.targets[].id' "$TARGETS_FILE" | sort | uniq -d)
[[ -z "$dup" ]] || { echo "validate-targets-yaml: duplicate ids: $dup" >&2; exit 1; }

echo "validate-targets-yaml: PASS ($count targets)"
