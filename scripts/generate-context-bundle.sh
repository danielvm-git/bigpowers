#!/usr/bin/env bash
# story: e37s06
# scenario: SC-e37s06-P1-01
# bp-manual-utility: ADR-0007/tech-stack.md document this as the post-seed
# context-wiring step, but seed-conventions never invokes it — a real
# "documented, never executed" gap. Not fixed here: wiring it into
# seed-conventions changes that skill's actual output, which needs its own
# investigate-bug pass and verification, not a silent bundle into a
# compliance-margin PR. Run manually: bash scripts/generate-context-bundle.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/skill-common.sh"
resolve_repo_root

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      echo "Usage: generate-context-bundle.sh [--dry-run]"
      exit 0
      ;;
  esac
done

bash "$SCRIPT_DIR/validate-targets-yaml.sh" >/dev/null

TARGETS_FILE="$SCRIPT_DIR/targets.yaml"
command -v yq >/dev/null || { echo "generate-context-bundle: yq required" >&2; exit 1; }

cd "$REPO_ROOT"
agents_src="AGENTS.md"
[[ -f "$agents_src" ]] || agents_src="docs/templates/AGENTS.md"

while IFS= read -r row; do
  id=$(echo "$row" | yq -r '.id')
  mode=$(echo "$row" | yq -r '.context.mode // ""')
  [[ "$mode" == "null" || -z "$mode" || "$mode" == "native" ]] && continue

  file=$(echo "$row" | yq -r '.context.file // ""')
  bridge_file=$(echo "$row" | yq -r '.context.bridge_file // ""')
  bridge_key=$(echo "$row" | yq -r '.context.bridge_key // "read"')
  adapter=$(echo "$row" | yq -r '.context.adapter')

  dest="${file:-$bridge_file}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would wire $id → $dest (mode=$mode, source=$agents_src)"
    continue
  fi

  adapter_script="$SCRIPT_DIR/adapters/${adapter}.sh"
  # shellcheck source=/dev/null
  source "$adapter_script"
  case "$mode" in
    symlink) wire_context_mode symlink "$file" ;;
    copy) wire_context_mode copy "$file" ;;
    config-bridge) wire_context_mode config-bridge "$bridge_file" "$bridge_key" "$agents_src" ;;
  esac
  echo "wired $id → $dest"
done < <(yq -o=json '.targets[] | select(.context != null)' "$TARGETS_FILE" | jq -c '.')

echo "generate-context-bundle: done (source=$agents_src)"
