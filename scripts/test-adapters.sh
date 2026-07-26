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

  # </dev/null is load-bearing. The caller feeds the target list into a
  # `while read` loop, so a sourced adapter inherits it on fd 0 — and every
  # adapter ends in a main block that reads stdin. agy.sh was consuming the
  # remaining target list and running render_skill with an empty IR_NAME, so
  # this "registry-driven" runner silently tested exactly one adapter.
  # shellcheck source=/dev/null
  source "$adapter_file" </dev/null 2>/dev/null && ta_pass "$id: sourceable" || { ta_fail "$id: source error"; return; }

  local has_skill has_context mode
  has_skill=$(yq -r ".targets[] | select(.id==\"$id\") | .skill != null" "$TARGETS_FILE")
  has_context=$(yq -r ".targets[] | select(.id==\"$id\") | .context != null" "$TARGETS_FILE")
  mode=$(yq -r ".targets[] | select(.id==\"$id\") | .context.mode // \"\"" "$TARGETS_FILE")

  if [[ "$has_skill" == "true" ]]; then
    declare -f render_skill >/dev/null 2>&1 && ta_pass "$id: render_skill defined" || ta_fail "$id: render_skill missing"
  fi

  if [[ "$has_context" == "true" && "$mode" != "native" ]]; then
    declare -f wire_context >/dev/null 2>&1 && ta_pass "$id: wire_context defined" || ta_fail "$id: wire_context missing"

    TA_TMPDIR=$(mktemp -d)
    cp "$SCRIPT_DIR/../docs/templates/AGENTS.md" "$TA_TMPDIR/AGENTS.md" 2>/dev/null || echo "# test" > "$TA_TMPDIR/AGENTS.md"
    # The idempotency probe runs in a subshell (it cd's away), so its ta_pass/
    # ta_fail would increment counters in a child and be lost — the script used
    # to print 5 PASS lines and report 4. Capture the status, tally in-process.
    if (
      cd "$TA_TMPDIR"
      # </dev/null for the same reason as above — this subshell also inherits
      # the caller's target list on fd 0.
      # shellcheck source=/dev/null
      source "$adapter_file" </dev/null
      wire_context >/dev/null 2>&1 || true
      wire_context >/dev/null 2>&1
    ) </dev/null; then
      ta_pass "$id: idempotent wire_context"
    else
      ta_fail "$id: wire_context failed"
    fi
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
