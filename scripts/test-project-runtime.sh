#!/usr/bin/env bash
# story: e82s01
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib/project-runtime.sh"

PASS=0
FAIL=0
TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

pass() {
  echo "  PASS $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL $1" >&2
  FAIL=$((FAIL + 1))
}

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$name"
  else
    fail "$name — expected '$expected', got '$actual'"
  fi
}

assert_fails_with() {
  local name="$1" expected="$2"
  shift 2
  local output
  if output="$("$@" 2>&1)"; then
    fail "$name — command unexpectedly succeeded"
  elif [[ "$output" == *"$expected"* ]]; then
    pass "$name"
  else
    fail "$name — expected error containing '$expected', got '$output'"
  fi
}

make_project() {
  local name="$1"
  local project="$TMPDIR_ROOT/$name"
  mkdir -p "$project/.bigpowers"
  printf '%s\n' "$project"
}

DEFAULT_PROJECT="$(make_project default)"
assert_eq "default specs directory" "specs" "$(bp_specs_dir "$DEFAULT_PROJECT")"
assert_eq "default specs path" "$DEFAULT_PROJECT/specs/state.yaml" \
  "$(bp_specs_path "$DEFAULT_PROJECT" state.yaml)"
assert_eq "repository without VCS" "none" "$(bp_vcs_kind "$DEFAULT_PROJECT")"

CONFIG_PROJECT="$(make_project configured)"
cat > "$CONFIG_PROJECT/.bigpowers/config.yaml" <<'YAML'
specs_dir: .specs
vcs: git
YAML
assert_eq "configured specs directory" ".specs" "$(bp_specs_dir "$CONFIG_PROJECT")"
assert_eq "configured specs path" "$CONFIG_PROJECT/.specs/release-plan.yaml" \
  "$(bp_specs_path "$CONFIG_PROJECT" release-plan.yaml)"
assert_eq "configured VCS" "git" "$(bp_vcs_kind "$CONFIG_PROJECT")"

assert_eq "environment specs override" "private-specs" \
  "$(BIGPOWERS_SPECS_DIR=private-specs bp_specs_dir "$CONFIG_PROJECT")"
assert_eq "environment VCS override" "jj" \
  "$(BIGPOWERS_VCS=jj bp_vcs_kind "$CONFIG_PROJECT")"

COLOCATED_PROJECT="$(make_project colocated)"
mkdir -p "$COLOCATED_PROJECT/.git" "$COLOCATED_PROJECT/.jj"
assert_eq "auto prefers Jujutsu in colocated repository" "jj" \
  "$(bp_vcs_kind "$COLOCATED_PROJECT")"

INVALID_PROJECT="$(make_project invalid)"
printf '%s\n' 'vcs: svn' > "$INVALID_PROJECT/.bigpowers/config.yaml"
assert_fails_with "invalid VCS is actionable" \
  "Expected one of: auto, git, jj" bp_vcs_kind "$INVALID_PROJECT"

EMPTY_PROJECT="$(make_project empty)"
printf '%s\n' 'specs_dir: ""' > "$EMPTY_PROJECT/.bigpowers/config.yaml"
assert_fails_with "empty specs directory is rejected" \
  "specs_dir must not be empty" bp_specs_dir "$EMPTY_PROJECT"

echo "---"
echo "test-project-runtime: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
