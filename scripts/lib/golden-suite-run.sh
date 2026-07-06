#!/usr/bin/env bash
# story: e42s04 e45s02
# Golden suite orchestrator — sourced by run-verification-gates.sh / run-golden-suite.sh

if [ -n "${GOLDEN_SUITE_RUN_LOADED:-}" ]; then return 0; fi
GOLDEN_SUITE_RUN_LOADED=1

_LIB="$(dirname "${BASH_SOURCE[0]}")"
source "$_LIB/golden-suite-gates.sh"
source "$_LIB/golden-suite-agent.sh"
source "$_LIB/golden-suite-report.sh"

golden_suite_main() {
  local arg gate name cmd optional

  REPORT_DIR="specs/benchmarks/reports"
  BASELINE_FILE="$REPORT_DIR/BASELINE-GOLDEN.yaml"
  GOLDEN_DIR="specs/benchmarks/golden"
  DRY_RUN=false BASELINE_MODE=false CHECK_SIZE=false AGENT_MODE=false

  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=true ;;
      --baseline) BASELINE_MODE=true ;;
      --check-size) CHECK_SIZE=true ;;
      --agent) AGENT_MODE=true ;;
      *)
        echo "Unknown flag: $arg"
        echo "Usage: ${GOLDEN_USAGE_NAME} [--agent] [--dry-run] [--baseline] [--check-size]"
        exit 2
        ;;
    esac
  done

  if $AGENT_MODE && ! command -v gh-aw &>/dev/null && ! command -v gh &>/dev/null; then
    echo -e "${GOLDEN_YELLOW}WARNING: gh-aw not installed — agent gate skipped${GOLDEN_NC}" >&2
    AGENT_MODE=false
  fi

  if $DRY_RUN; then
    if $AGENT_MODE; then
      echo "Golden Suite — DRY RUN (deterministic + agent)"
      echo ""
      echo "Deterministic gates (in order):"
      for gate in "${GOLDEN_GATES[@]}"; do
        IFS=':' read -r name cmd optional <<< "$gate"
        echo "  - $name: $cmd"
      done
      echo ""
      golden_agent_dry_run
      exit $?
    fi
    echo "Golden Suite — DRY RUN"
    echo "Gates (in order):"
    for gate in "${GOLDEN_GATES[@]}"; do
      IFS=':' read -r name cmd optional <<< "$gate"
      echo "  - $name: $cmd"
    done
    echo "Report: $REPORT_DIR/GOLDEN-YYYY-MM-DD.yaml"
    echo "OK (dry run)"
    exit 0
  fi

  mkdir -p "$REPORT_DIR"
  TODAY=$(date +%Y-%m-%d)
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  if $BASELINE_MODE; then REPORT_FILE="$BASELINE_FILE"; else REPORT_FILE="$REPORT_DIR/GOLDEN-${TODAY}.yaml"; fi

  golden_run_deterministic_gates
  golden_run_agent_stories
  golden_print_verdict
  golden_write_reports

  if $BASELINE_MODE; then golden_write_baseline_sizes; fi
  if $CHECK_SIZE; then golden_check_size_budget; exit $?; fi
  [[ "$OVERALL" == "fail" ]] && exit 1
  exit 0
}
