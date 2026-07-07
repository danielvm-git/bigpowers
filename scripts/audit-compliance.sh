#!/usr/bin/env bash
# audit-compliance.sh — Agentic Gherkin Compliance Harness (LLM-Judge Upgrade)

source "$(dirname "${BASH_SOURCE[0]}")/lib/audit-compliance-runner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/audit-compliance-report.sh"

audit_show_help() {
  cat <<EOF
Usage: bash scripts/audit-compliance.sh [feature-file|directory] [options]

Options:
  --help            Show this help message
  --dry-run         Parse the feature file without starting the judge loop
  --scenario [name] Run only a specific scenario
  --judge [type]    Judge type: 'binary' (exit code, default) or 'gemini' (LLM-judged)
  --model [name]    Model name to use for judging

If a directory is provided, all .feature files in that directory will be processed.
EOF
}

DRY_RUN=false
SCENARIO_FILTER=""
JUDGE="binary"
MODEL=""
INPUTS=()
TOTAL_GLOBAL_PASS=0
TOTAL_GLOBAL_FAIL=0
TOTAL_GLOBAL_WAIVED=0
TOTAL_GLOBAL_EXPIRED=0
SCORE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) audit_show_help; exit 0 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --scenario) SCENARIO_FILTER="$2"; shift 2 ;;
    --judge) JUDGE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    -*) echo "Unknown option: $1"; audit_show_help; exit 1 ;;
    *) INPUTS+=("$1"); shift ;;
  esac
done

if [[ ${#INPUTS[@]} -eq 0 ]]; then
  echo "Error: No feature file or directory specified."
  audit_show_help
  exit 1
fi

for input in "${INPUTS[@]}"; do
  if [[ -d "$input" ]]; then
    for f in "$input"/*.feature; do
      [[ -f "$f" ]] && audit_run_file "$f"
    done
  elif [[ -f "$input" ]]; then
    audit_run_file "$input"
  else
    echo "Warning: Input not found: $input"
  fi
done

audit_print_summary_and_exit
