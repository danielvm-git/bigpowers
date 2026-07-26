#!/usr/bin/env bash
# story: GH-104-forge-neutrality
# wire-ci.sh — resolve forge + stack and place a CI template, or skip honestly.
#
# GH #104: wire-ci declared itself a HARD GATE, then generated GitHub Actions
# config copied from one person's personal repository. On GitLab it could not
# work at all. This runner makes the template source configurable and turns an
# unsupported forge into an explicit skip instead of a false guarantee.
#
# Usage:
#   bash scripts/wire-ci.sh --detect            # report forge + stack, write nothing
#   bash scripts/wire-ci.sh --plan              # show what would be written
#   bash scripts/wire-ci.sh --apply             # write the workflow
#   bash scripts/wire-ci.sh --self-test         # prove skip/apply paths behave
#
# Exit codes: 0 applied or cleanly skipped, 1 error, 3 unsupported forge.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/detect-forge.sh
source "$REPO_ROOT/scripts/lib/detect-forge.sh"

EXIT_UNSUPPORTED_FORGE=3
MODE="${1:---detect}"
TARGET_DIR="${WIRE_CI_TARGET:-$REPO_ROOT}"

detect_stack() {
  local root="$1"
  if [[ -f "$root/Cargo.toml" ]]; then echo "rust"
  elif [[ -f "$root/go.mod" ]]; then echo "go"
  elif [[ -f "$root/pyproject.toml" || -f "$root/setup.py" ]]; then echo "python"
  elif [[ -f "$root/package.json" ]]; then echo "node"
  else echo "unknown"
  fi
}

template_for() {
  local forge="$1" stack="$2"
  printf '%s/%s/test-build-release-%s.yml' "$(forge_template_root)" "$forge" "$stack"
}

# The honest-degradation path. An unsupported forge gets a named reason and a
# non-zero-but-distinct exit code, never a GitHub workflow it cannot run.
report_unsupported() {
  local forge="$1"
  echo "wire-ci: SKIP — no CI templates for forge '$forge'"
  echo "  Supported: $FORGE_SUPPORTED_LIST"
  echo "  wire-ci is NOT a hard gate on this forge; it cannot generate config it does not ship."
  echo "  Options:"
  echo "    - point at your own templates: BIGPOWERS_CI_TEMPLATES=/path/to/templates"
  echo "    - pin the forge explicitly:    echo 'forge: github' > specs/forge.yaml"
  echo "    - write CI by hand for $(forge_ci_path "$forge" || true)"
}

resolve_and_report() {
  local root="$1"
  FORGE=$(detect_forge "$root")
  STACK=$(detect_stack "$root")
  echo "wire-ci: forge=$FORGE stack=$STACK"

  if ! forge_is_supported "$FORGE"; then
    report_unsupported "$FORGE"
    return "$EXIT_UNSUPPORTED_FORGE"
  fi
  if [[ "$STACK" == "unknown" ]]; then
    echo "wire-ci: SKIP — no recognized manifest (Cargo.toml, go.mod, pyproject.toml, package.json)"
    return "$EXIT_UNSUPPORTED_FORGE"
  fi

  TEMPLATE=$(template_for "$FORGE" "$STACK")
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "wire-ci: SKIP — no bundled template at $TEMPLATE"
    return "$EXIT_UNSUPPORTED_FORGE"
  fi
  echo "wire-ci: template=$TEMPLATE"
  return 0
}

apply_template() {
  local root="$1"
  local dest_dir="$root/$(forge_ci_path "$FORGE")"
  mkdir -p "$dest_dir"
  cp "$TEMPLATE" "$dest_dir/test-build-release.yml"
  echo "wire-ci: wrote $dest_dir/test-build-release.yml"
}

run_self_test() {
  echo "=== wire-ci self-test ==="
  local tmp problems=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  # An unsupported forge must skip, not emit GitHub Actions config.
  mkdir -p "$tmp/gitlab-project"
  echo '{}' > "$tmp/gitlab-project/package.json"
  echo 'forge: gitlab' > /dev/null
  mkdir -p "$tmp/gitlab-project/specs"
  printf 'forge: gitlab\n' > "$tmp/gitlab-project/specs/forge.yaml"
  local out rc
  out=$(BIGPOWERS_FORGE="" resolve_and_report "$tmp/gitlab-project" 2>&1); rc=$?
  if [[ "$rc" -ne "$EXIT_UNSUPPORTED_FORGE" ]]; then
    echo "FAIL: self-test — gitlab project did not skip (rc=$rc)"; problems=$((problems + 1))
  fi
  if printf '%s' "$out" | grep -q 'HARD GATE'; then
    echo "FAIL: self-test — skip path still claims HARD GATE"; problems=$((problems + 1))
  fi
  if [[ -d "$tmp/gitlab-project/.github" ]]; then
    echo "FAIL: self-test — wrote .github/ for a non-GitHub forge"; problems=$((problems + 1))
  fi

  # A supported forge must resolve to a bundled template — proving the runner
  # does not depend on any external repository being reachable.
  mkdir -p "$tmp/gh-project/specs"
  echo '{}' > "$tmp/gh-project/package.json"
  printf 'forge: github\n' > "$tmp/gh-project/specs/forge.yaml"
  if ! out=$(resolve_and_report "$tmp/gh-project" 2>&1); then
    echo "FAIL: self-test — github/node project did not resolve: $out"; problems=$((problems + 1))
  elif ! printf '%s' "$out" | grep -q 'test-build-release-node.yml'; then
    echo "FAIL: self-test — resolved the wrong template: $out"; problems=$((problems + 1))
  fi

  # The default template root must live inside the package, not in a user's home
  # and not in the project being wired. Guards the #104 regression directly.
  local root
  root=$(forge_template_root)
  case "$root" in
    "$REPO_ROOT"/*) : ;;
    *) echo "FAIL: self-test — default template root escapes the package: $root"; problems=$((problems + 1)) ;;
  esac
  if printf '%s' "$root" | grep -q 'danielvm-git\|~/Developer/.github'; then
    echo "FAIL: self-test — template root still points at a personal repository"; problems=$((problems + 1))
  fi

  rm -rf "$tmp"
  trap - EXIT

  if [[ "$problems" -gt 0 ]]; then
    echo "FAIL: wire-ci self-test — $problems problem(s)"
    return 1
  fi
  echo "PASS: wire-ci self-test — unsupported forges skip, supported forges resolve bundled templates"
  return 0
}

case "$MODE" in
  --self-test) run_self_test; exit $? ;;
  --detect|--plan)
    resolve_and_report "$TARGET_DIR"; exit $?
    ;;
  --apply)
    resolve_and_report "$TARGET_DIR" || exit $?
    apply_template "$TARGET_DIR"
    ;;
  *)
    echo "wire-ci: unknown mode '$MODE' (expected --detect, --plan, --apply, --self-test)" >&2
    exit 1
    ;;
esac
