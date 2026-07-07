#!/usr/bin/env bash
# story: e37s05
# scenario: SC-e37s05-P1-02
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS_FILE="$SCRIPT_DIR/targets.yaml"
DRY_RUN=0
FILTER=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "test-adapters: unknown flag $arg" >&2; exit 2 ;;
    *) FILTER="$arg" ;;
  esac
done

command -v yq >/dev/null || { echo "test-adapters: yq required" >&2; exit 1; }
bash "$SCRIPT_DIR/validate-targets-yaml.sh" >/dev/null

PASS=0
FAIL=0
TMPDIR=""
TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$SCRIPT_DIR/lib/test-assertions.sh"
trap ta_cleanup EXIT

test_adapter() {
  local id="$1"
  local adapter_file="$SCRIPT_DIR/adapters/${id}.sh"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would test: $id"
    return 0
  fi

  [[ -f "$adapter_file" ]] || { ta_fail "$id: adapter missing"; return; }
  ta_pass "$id: exists"

  # shellcheck source=/dev/null
  source "$adapter_file" 2>/dev/null && ta_pass "$id: sourceable" || { ta_fail "$id: source error"; return; }

  local has_skill has_context mode
  has_skill=$(yq -r ".targets[] | select(.id==\"$id\") | .skill != null" "$TARGETS_FILE")
  has_context=$(yq -r ".targets[] | select(.id==\"$id\") | .context != null" "$TARGETS_FILE")
  mode=$(yq -r ".targets[] | select(.id==\"$id\") | .context.mode // \"\"" "$TARGETS_FILE")

  if [[ "$has_skill" == "true" ]]; then
    declare -f render_skill >/dev/null 2>&1 && ta_pass "$id: render_skill defined" || ta_fail "$id: render_skill missing"
  fi

  if [[ "$has_context" == "true" && "$mode" != "native" ]]; then
    declare -f wire_context >/dev/null 2>&1 && ta_pass "$id: wire_context defined" || ta_fail "$id: wire_context missing"

    TMPDIR=$(mktemp -d)
    cp "$SCRIPT_DIR/../docs/templates/AGENTS.md" "$TMPDIR/AGENTS.md" 2>/dev/null || echo "# test" > "$TMPDIR/AGENTS.md"
    (
      cd "$TMPDIR"
      # shellcheck source=/dev/null
      source "$adapter_file"
      wire_context 2>/dev/null || true
      wire_context 2>/dev/null && ta_pass "$id: idempotent wire_context" || ta_fail "$id: wire_context failed"
    )
  fi
}

if [[ -n "$FILTER" ]]; then
  test_adapter "$FILTER"
else
  while IFS= read -r adapter; do
    [[ -n "$adapter" ]] && test_adapter "$adapter"
  done < <(yq -r '.targets[] | (.skill.adapter // .context.adapter)' "$TARGETS_FILE" | sort -u)
fi

echo "test-adapters: $TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]] || exit 1
