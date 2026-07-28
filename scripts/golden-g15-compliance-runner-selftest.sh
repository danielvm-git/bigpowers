#!/usr/bin/env bash
# story: e45s02
# golden-g15-compliance-runner-selftest.sh — audit-compliance-runner.sh must
# correctly execute a Background step, a step on a file's last line with no
# trailing newline, and must still report a genuinely failing step as FAIL
# rather than silently dropping it.
#
# audit-compliance-runner.sh had two bugs that dropped steps entirely rather
# than failing them: no Background: handling at all (akita.feature's
# Background Given was silently skipped), and `done < "$FEATURE_FILE"` losing
# a final line with no trailing newline (karpathy.feature's last step never
# appeared in [STEP] output). Both are fixed; this gate is the regression
# guard so a future change to the runner can't reintroduce either silently —
# and, just as important, can't "fix" step-dropping by making every line
# execute unconditionally, which would hide a genuinely failing step as a
# false PASS.
#
# Usage: bash scripts/golden-g15-compliance-runner-selftest.sh [--self-test]
# Exit 0: Background executes, the no-newline last step executes, and a
#         failing step is reported FAIL (or, under --self-test, a loose
#         Given line outside any Background/Scenario is correctly NOT
#         executed)
# Exit 1: any of the above does not hold

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Builds a fixture project at $1 with the step scripts a fixture .feature
# needs, then runs audit_run_file against $2 (a path relative to $1) and
# echoes the captured [STEP]/Result output.
run_fixture() { # $1 = fixture root, $2 = feature file path relative to root
  local root="$1" feature="$2"
  (
    cd "$root"
    # shellcheck source=lib/audit-compliance-runner.sh
    source "$REPO_ROOT/scripts/lib/audit-compliance-runner.sh"
    DRY_RUN=false SCENARIO_FILTER="" JUDGE="binary"
    TOTAL_GLOBAL_PASS=0 TOTAL_GLOBAL_FAIL=0 TOTAL_GLOBAL_WAIVED=0 TOTAL_GLOBAL_EXPIRED=0
    audit_run_file "$feature" 2>&1
  )
}

build_step() { # $1 = fixture root, $2 = sanitized step filename (no .sh), $3 = exit code
  cat > "$1/specs/verifications/steps/$2.sh" <<EOF
#!/usr/bin/env bash
exit $3
EOF
}

if [[ "${1:-}" == "--self-test" ]]; then
  echo "=== G-15 self-test: a loose Given outside Background/Scenario must not execute ==="
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$TMP/specs/verifications/steps" "$TMP/specs/verifications/reports"

  build_step "$TMP" "given-a-loose-step-outside-any-block" 0
  # No "Background:" keyword and no "Scenario:" before this line — structurally
  # mimics what the pre-fix runner treated every top-level Given/Then/And as
  # (no scenario context tracked at all), which is the over-broad failure mode
  # a bad fix could reintroduce: executing steps regardless of context.
  printf 'Feature: G-15 self-test fixture\nGiven a loose step outside any block\n' \
    > "$TMP/specs/features_fixture.feature"

  OUTPUT=$(run_fixture "$TMP" "specs/features_fixture.feature")
  if grep -q '\[STEP\] Given a loose step outside any block' <<<"$OUTPUT"; then
    echo -e "${RED}FAIL${NC} a loose Given outside any Background/Scenario executed — the runner no longer tracks scenario context"
    echo "G-15 self-test: FAIL"
    exit 1
  fi
  echo -e "${GREEN}PASS${NC} the loose Given correctly did not execute"
  echo "G-15 self-test: PASS"
  exit 0
fi

echo "=== G-15: compliance runner Background/EOF/failure handling ==="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/specs/verifications/steps" "$TMP/specs/verifications/reports"

build_step "$TMP" "given-a-background-step" 0
build_step "$TMP" "then-a-normal-step" 0
build_step "$TMP" "and-a-step-that-should-fail" 1
build_step "$TMP" "and-a-step-with-no-trailing-newline" 0

# Written without a trailing newline after the last line — printf, not a
# heredoc, so the file ends exactly where karpathy.feature's bug lived.
printf 'Feature: G-15 fixture\n  Background:\n    Given a background step\n\n  Scenario: Fixture\n    Then a normal step\n    And a step that should fail\n    And a step with no trailing newline' \
  > "$TMP/specs/features_fixture.feature"

OUTPUT=$(run_fixture "$TMP" "specs/features_fixture.feature")

FAILS=0

if grep -q '\[STEP\] Given a background step' <<<"$OUTPUT"; then
  echo -e "${GREEN}PASS${NC} Background step executed"
else
  echo -e "${RED}FAIL${NC} Background step did not execute"
  FAILS=$((FAILS + 1))
fi

if grep -q '\[STEP\] And a step with no trailing newline' <<<"$OUTPUT"; then
  echo -e "${GREEN}PASS${NC} the no-trailing-newline last step executed"
else
  echo -e "${RED}FAIL${NC} the no-trailing-newline last step did not execute"
  FAILS=$((FAILS + 1))
fi

if grep -A2 '\[STEP\] And a step that should fail' <<<"$OUTPUT" | grep -q 'Result: FAIL'; then
  echo -e "${GREEN}PASS${NC} the genuinely failing step is reported FAIL, not silently dropped"
else
  echo -e "${RED}FAIL${NC} the genuinely failing step was not reported FAIL"
  FAILS=$((FAILS + 1))
fi

if [[ "$FAILS" -eq 0 ]]; then
  echo "G-15: PASS"
  exit 0
fi
echo "G-15: FAIL ($FAILS assertion(s) failed)"
exit 1
